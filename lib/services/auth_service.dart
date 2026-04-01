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
  }) async {
    final (hashedPassword, salt) = UserRepository.hashPassword(password);
    await _userRepository.insertUser(
      User(
        username: username,
        email: email,
        password: hashedPassword,
        salt: salt,
      ),
    );
  }
}
