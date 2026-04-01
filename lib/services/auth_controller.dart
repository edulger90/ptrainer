import 'dart:math';

import '../models/user.dart';
import 'auth_service.dart';
import 'error_logger.dart';

enum AuthMessageCode {
  registrationSuccess,
  unexpectedError,
  usernameEmpty,
  usernameMinLength,
  usernameMaxLength,
  usernameInvalidChars,
  usernameStartsWithNumber,
  emailEmpty,
  emailInvalid,
  passwordEmpty,
  passwordMinLength,
  passwordNeedsLowercase,
  passwordNeedsUppercase,
  usernameAndPasswordRequired,
  invalidCredentials,
  onlyOneUser,
  tooManyAttempts,
}

class AuthMessage {
  const AuthMessage(this.code, {this.remainingSeconds});

  final AuthMessageCode code;
  final int? remainingSeconds;

  bool get isSuccess => code == AuthMessageCode.registrationSuccess;
}

class AuthInitializationState {
  const AuthInitializationState({
    required this.userExists,
    required this.savedUsername,
    required this.isLogin,
  });

  final bool userExists;
  final String? savedUsername;
  final bool isLogin;
}

class AuthSubmissionResult {
  const AuthSubmissionResult({
    this.user,
    this.message,
    this.shouldSwitchToLogin = false,
    this.shouldClearPassword = false,
    this.userExists,
  });

  final User? user;
  final AuthMessage? message;
  final bool shouldSwitchToLogin;
  final bool shouldClearPassword;
  final bool? userExists;
}

class AuthController {
  AuthController({AuthService? authService, DateTime Function()? clock})
    : _authService = authService ?? AuthService(),
      _clock = clock ?? DateTime.now;

  static final _usernameRegex = RegExp(r'^[a-z0-9_.]+$');
  static final _usernameStartRegex = RegExp(r'^[0-9]');
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final _lowercaseRegex = RegExp(r'[a-z]');
  static final _uppercaseRegex = RegExp(r'[A-Z]');

  final AuthService _authService;
  final DateTime Function() _clock;

  int _loginAttempts = 0;
  DateTime? _lockoutUntil;

  Future<AuthInitializationState> loadInitialState() async {
    String? savedUsername;
    var userExists = false;

    try {
      userExists = await _authService.userExists();
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: 'AuthController.loadInitialState.userExists',
      );
    }

    savedUsername = await _authService.loadSavedUsername();

    return AuthInitializationState(
      userExists: userExists,
      savedUsername: savedUsername,
      isLogin: userExists,
    );
  }

  Future<AuthSubmissionResult> submit({
    required bool isLogin,
    required String username,
    required String email,
    required String password,
  }) {
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedEmail = email.trim();

    return isLogin
        ? _submitLogin(normalizedUsername, password)
        : _submitRegistration(normalizedUsername, normalizedEmail, password);
  }

  Future<AuthSubmissionResult> _submitLogin(
    String username,
    String password,
  ) async {
    final now = _clock();
    if (_lockoutUntil != null && now.isBefore(_lockoutUntil!)) {
      return AuthSubmissionResult(
        message: AuthMessage(
          AuthMessageCode.tooManyAttempts,
          remainingSeconds: max(1, _lockoutUntil!.difference(now).inSeconds),
        ),
      );
    }

    if (username.isEmpty || password.isEmpty) {
      return const AuthSubmissionResult(
        message: AuthMessage(AuthMessageCode.usernameAndPasswordRequired),
      );
    }

    try {
      final user = await _authService.authenticate(
        username: username,
        password: password,
      );
      if (user == null) {
        _recordFailedLoginAttempt();
        return const AuthSubmissionResult(
          message: AuthMessage(AuthMessageCode.invalidCredentials),
        );
      }

      _loginAttempts = 0;
      _lockoutUntil = null;
      await _authService.saveUsername(username);

      return AuthSubmissionResult(user: user, shouldClearPassword: true);
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: 'AuthController.submitLogin',
      );
      return const AuthSubmissionResult(
        message: AuthMessage(AuthMessageCode.unexpectedError),
      );
    }
  }

  Future<AuthSubmissionResult> _submitRegistration(
    String username,
    String email,
    String password,
  ) async {
    final validationMessage =
        _validateUsername(username) ??
        _validateEmail(email) ??
        _validatePassword(password);
    if (validationMessage != null) {
      return AuthSubmissionResult(message: validationMessage);
    }

    try {
      final exists = await _authService.userExists();
      if (exists) {
        return const AuthSubmissionResult(
          message: AuthMessage(AuthMessageCode.onlyOneUser),
        );
      }

      await _authService.registerUser(
        username: username,
        email: email,
        password: password,
      );

      return const AuthSubmissionResult(
        message: AuthMessage(AuthMessageCode.registrationSuccess),
        shouldSwitchToLogin: true,
        shouldClearPassword: true,
        userExists: true,
      );
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: 'AuthController.submitRegistration',
      );
      return const AuthSubmissionResult(
        message: AuthMessage(AuthMessageCode.unexpectedError),
      );
    }
  }

  void _recordFailedLoginAttempt() {
    _loginAttempts++;
    if (_loginAttempts < 5) return;
    _lockoutUntil = _clock().add(const Duration(seconds: 30));
    _loginAttempts = 0;
  }

  AuthMessage? _validateUsername(String username) {
    if (username.isEmpty) {
      return const AuthMessage(AuthMessageCode.usernameEmpty);
    }
    if (username.length < 3) {
      return const AuthMessage(AuthMessageCode.usernameMinLength);
    }
    if (username.length > 20) {
      return const AuthMessage(AuthMessageCode.usernameMaxLength);
    }
    if (!_usernameRegex.hasMatch(username)) {
      return const AuthMessage(AuthMessageCode.usernameInvalidChars);
    }
    if (_usernameStartRegex.hasMatch(username)) {
      return const AuthMessage(AuthMessageCode.usernameStartsWithNumber);
    }
    return null;
  }

  AuthMessage? _validateEmail(String email) {
    if (email.isEmpty) {
      return const AuthMessage(AuthMessageCode.emailEmpty);
    }
    if (!_emailRegex.hasMatch(email)) {
      return const AuthMessage(AuthMessageCode.emailInvalid);
    }
    return null;
  }

  AuthMessage? _validatePassword(String password) {
    if (password.isEmpty) {
      return const AuthMessage(AuthMessageCode.passwordEmpty);
    }
    if (password.length < 8) {
      return const AuthMessage(AuthMessageCode.passwordMinLength);
    }
    if (!_lowercaseRegex.hasMatch(password)) {
      return const AuthMessage(AuthMessageCode.passwordNeedsLowercase);
    }
    if (!_uppercaseRegex.hasMatch(password)) {
      return const AuthMessage(AuthMessageCode.passwordNeedsUppercase);
    }
    return null;
  }
}
