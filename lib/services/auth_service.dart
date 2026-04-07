import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'db/database_connection.dart';
import 'error_logger.dart';
import 'repositories/user_repository.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class AuthService {
  AuthService({
    UserRepository? userRepository,
    SharedPreferencesLoader? sharedPreferencesLoader,
  }) : _userRepository =
           userRepository ?? UserRepository(sharedDatabaseProvider),
       _sharedPreferencesLoader =
           sharedPreferencesLoader ?? SharedPreferences.getInstance;

  final UserRepository _userRepository;
  final SharedPreferencesLoader _sharedPreferencesLoader;

  Future<String?> loadSavedUsername() async {
    try {
      final prefs = await _sharedPreferencesLoader();
      final username = prefs.getString('saved_username');
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
      await prefs.setString('saved_username', username);
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: 'AuthService.saveUsername',
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
