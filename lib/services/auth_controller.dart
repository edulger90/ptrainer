import 'dart:math';

import '../models/user.dart';
import 'auth_service.dart';
import 'error_logger.dart';

enum AuthMessageCode {
  registrationSuccess,
  passwordResetSuccess,
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
  securityQuestionEmpty,
  securityAnswerEmpty,
  securityAnswerWrong,
  userNotFound,
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
    required this.savedPassword,
    required this.rememberMe,
    required this.isLogin,
  });

  final bool userExists;
  final String? savedUsername;
  final String? savedPassword;
  final bool rememberMe;
  final bool isLogin;
}

class AuthSubmissionResult {
  const AuthSubmissionResult({
    this.user,
    this.message,
    this.shouldSwitchToLogin = false,
    this.shouldClearPassword = false,
    this.userExists,
    this.securityQuestion,
  });

  final User? user;
  final AuthMessage? message;
  final bool shouldSwitchToLogin;
  final bool shouldClearPassword;
  final bool? userExists;
  final String? securityQuestion;
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
    String? savedPassword;
    var rememberMe = false;
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
    final rememberedCredentials = await _authService
        .loadRememberedCredentials();
    if (rememberedCredentials != null) {
      savedUsername = rememberedCredentials.username;
      savedPassword = rememberedCredentials.password;
      rememberMe = true;
    }

    return AuthInitializationState(
      userExists: userExists,
      savedUsername: savedUsername,
      savedPassword: savedPassword,
      rememberMe: rememberMe,
      isLogin: userExists,
    );
  }

  Future<AuthSubmissionResult> submit({
    required bool isLogin,
    required String username,
    required String email,
    required String password,
    bool rememberMe = false,
    String securityQuestion = '',
    String securityAnswer = '',
  }) {
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedEmail = email.trim();

    return isLogin
        ? _submitLogin(normalizedUsername, password, rememberMe)
        : _submitRegistration(
            normalizedUsername,
            normalizedEmail,
            password,
            securityQuestion.trim(),
            securityAnswer.trim(),
          );
  }

  Future<AuthSubmissionResult> submitForgotPassword({
    required String username,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.isEmpty) {
      return const AuthSubmissionResult(
        message: AuthMessage(AuthMessageCode.usernameEmpty),
      );
    }
    try {
      final user = await _authService.getUserByUsername(normalizedUsername);
      if (user == null || user.securityQuestion == null) {
        return const AuthSubmissionResult(
          message: AuthMessage(AuthMessageCode.userNotFound),
        );
      }
      return AuthSubmissionResult(securityQuestion: user.securityQuestion);
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: 'AuthController.submitForgotPassword',
      );
      return const AuthSubmissionResult(
        message: AuthMessage(AuthMessageCode.unexpectedError),
      );
    }
  }

  Future<AuthSubmissionResult> submitResetPassword({
    required String username,
    required String securityAnswer,
    required String newPassword,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();

    final passwordValidation = _validatePassword(newPassword);
    if (passwordValidation != null) {
      return AuthSubmissionResult(message: passwordValidation);
    }

    try {
      final user = await _authService.getUserByUsername(normalizedUsername);
      if (user == null) {
        return const AuthSubmissionResult(
          message: AuthMessage(AuthMessageCode.userNotFound),
        );
      }

      if (!_authService.verifySecurityAnswer(user, securityAnswer)) {
        return const AuthSubmissionResult(
          message: AuthMessage(AuthMessageCode.securityAnswerWrong),
        );
      }

      await _authService.resetPassword(
        userId: user.id!,
        newPassword: newPassword,
      );

      return const AuthSubmissionResult(
        message: AuthMessage(AuthMessageCode.passwordResetSuccess),
        shouldSwitchToLogin: true,
        shouldClearPassword: true,
      );
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: 'AuthController.submitResetPassword',
      );
      return const AuthSubmissionResult(
        message: AuthMessage(AuthMessageCode.unexpectedError),
      );
    }
  }

  Future<AuthSubmissionResult> _submitLogin(
    String username,
    String password,
    bool rememberMe,
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
      if (rememberMe) {
        await _authService.saveRememberedCredentials(
          username: username,
          password: password,
        );
      } else {
        await _authService.clearRememberedCredentials();
      }

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

  Future<void> clearRememberedCredentials() {
    return _authService.clearRememberedCredentials();
  }

  Future<AuthSubmissionResult> _submitRegistration(
    String username,
    String email,
    String password,
    String securityQuestion,
    String securityAnswer,
  ) async {
    final validationMessage =
        _validateUsername(username) ??
        _validateEmail(email) ??
        _validatePassword(password);
    if (validationMessage != null) {
      return AuthSubmissionResult(message: validationMessage);
    }
    if (securityQuestion.isEmpty) {
      return const AuthSubmissionResult(
        message: AuthMessage(AuthMessageCode.securityQuestionEmpty),
      );
    }
    if (securityAnswer.isEmpty) {
      return const AuthSubmissionResult(
        message: AuthMessage(AuthMessageCode.securityAnswerEmpty),
      );
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
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
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
