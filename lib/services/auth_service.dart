import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'db/database_connection.dart';
import 'error_logger.dart';
import 'repositories/user_repository.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class RememberedCredentials {
  const RememberedCredentials({required this.username, required this.password});

  final String username;
  final String password;
}

class AuthService {
  AuthService({
    UserRepository? userRepository,
    SharedPreferencesLoader? sharedPreferencesLoader,
    FlutterSecureStorage? secureStorage,
  }) : _userRepository =
           userRepository ?? UserRepository(sharedDatabaseProvider),
       _sharedPreferencesLoader =
           sharedPreferencesLoader ?? SharedPreferences.getInstance,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final UserRepository _userRepository;
  final SharedPreferencesLoader _sharedPreferencesLoader;
  final FlutterSecureStorage _secureStorage;

  static const _savedUsernameKey = 'saved_username';
  static const _rememberedUsernameKey = 'remembered_username';
  static const _rememberedPasswordKey = 'remembered_password';

  Future<String?> loadSavedUsername() async {
    try {
      final prefs = await _sharedPreferencesLoader();
      final username = prefs.getString(_savedUsernameKey);
      if (username == null || username.isEmpty) return null;
      return username;
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: 'AuthService.loadSavedUsername',
      );
      return null;
    }
  }

  Future<void> saveUsername(String username) async {
    try {
      final prefs = await _sharedPreferencesLoader();
      await prefs.setString(_savedUsernameKey, username);
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: 'AuthService.saveUsername',
      );
    }
  }

  Future<RememberedCredentials?> loadRememberedCredentials() async {
    try {
      final username = await _secureStorage.read(key: _rememberedUsernameKey);
      final password = await _secureStorage.read(key: _rememberedPasswordKey);
      if (username == null || username.isEmpty) return null;
      if (password == null || password.isEmpty) return null;
      return RememberedCredentials(username: username, password: password);
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: 'AuthService.loadRememberedCredentials',
      );
      return null;
    }
  }

  Future<void> saveRememberedCredentials({
    required String username,
    required String password,
  }) async {
    try {
      await _secureStorage.write(key: _rememberedUsernameKey, value: username);
      await _secureStorage.write(key: _rememberedPasswordKey, value: password);
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: 'AuthService.saveRememberedCredentials',
      );
    }
  }

  Future<void> clearRememberedCredentials() async {
    try {
      await _secureStorage.delete(key: _rememberedUsernameKey);
      await _secureStorage.delete(key: _rememberedPasswordKey);
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: 'AuthService.clearRememberedCredentials',
      );
    }
  }

  Future<bool> userExists() => _userRepository.userExists();

  Future<User?> authenticate({
    required String username,
    required String password,
  }) {
    return _userRepository.authenticate(username, password);
  }

  Future<void> registerUser({
    required String username,
    required String email,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    final (hashedPassword, salt) = UserRepository.hashPassword(password);
    final (hashedAnswer, answerSalt) = UserRepository.hashPassword(
      securityAnswer.trim().toLowerCase(),
    );
    await _userRepository.insertUser(
      User(
        username: username,
        email: email,
        password: hashedPassword,
        salt: salt,
        securityQuestion: securityQuestion,
        securityAnswer: '$hashedAnswer:$answerSalt',
      ),
    );
  }

  Future<User?> getUserByUsername(String username) {
    return _userRepository.getUserByUsername(username);
  }

  bool verifySecurityAnswer(User user, String answer) {
    final stored = user.securityAnswer;
    if (stored == null || !stored.contains(':')) return false;
    final parts = stored.split(':');
    final storedHash = parts[0];
    final storedSalt = parts[1];
    final (inputHash, _) = _hashWithKnownSalt(
      answer.trim().toLowerCase(),
      storedSalt,
    );
    return inputHash == storedHash;
  }

  static (String, String) _hashWithKnownSalt(String input, String salt) {
    final unsalted = UserRepository.hashUnsalted(input);
    final salted = UserRepository.hashWithSalt(unsalted, salt);
    return (salted, salt);
  }

  Future<void> resetPassword({
    required int userId,
    required String newPassword,
  }) async {
    final (hashedPassword, salt) = UserRepository.hashPassword(newPassword);
    await _userRepository.updateUserPassword(userId, hashedPassword, salt);
  }
}
