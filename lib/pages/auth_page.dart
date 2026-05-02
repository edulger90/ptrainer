import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_controller.dart';
import '../services/session_timeout_service.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _userExists = false;
  bool _isSuccessMessage = false;
  bool _isForgotPassword = false;
  bool _rememberMe = false;
  int _forgotStep = 0; // 0: enter username, 1: answer question, 2: new password
  String? _forgotSecurityQuestion;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _securityQuestionController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _authController = AuthController();

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    unawaited(SessionTimeoutService.instance.endSession());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _securityQuestionController.dispose();
    _securityAnswerController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    final state = await _authController.loadInitialState();
    if (!mounted) return;
    setState(() {
      _userExists = state.userExists;
      _isLogin = state.isLogin;
      _rememberMe = state.rememberMe;
      if (state.savedUsername != null) {
        _usernameController.text = state.savedUsername!;
      }
      if (state.savedPassword != null) {
        _passwordController.text = state.savedPassword!;
      }
    });
  }

  Future<void> _setRememberMe(bool value) async {
    setState(() {
      _rememberMe = value;
    });
    if (!value) {
      await _authController.clearRememberedCredentials();
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
      _isSuccessMessage = false;
      _isForgotPassword = false;
      _forgotStep = 0;
      _forgotSecurityQuestion = null;
    });
  }

  void _startForgotPassword() {
    setState(() {
      _isForgotPassword = true;
      _forgotStep = 0;
      _error = null;
      _isSuccessMessage = false;
      _securityAnswerController.clear();
      _newPasswordController.clear();
      _forgotSecurityQuestion = null;
    });
  }

  void _cancelForgotPassword() {
    setState(() {
      _isForgotPassword = false;
      _forgotStep = 0;
      _error = null;
      _isSuccessMessage = false;
      _forgotSecurityQuestion = null;
    });
  }

  String _messageText(AuthMessage message, AppLocalizations l) {
    switch (message.code) {
      case AuthMessageCode.registrationSuccess:
        return l.registrationSuccess;
      case AuthMessageCode.unexpectedError:
        return l.unexpectedError;
      case AuthMessageCode.usernameEmpty:
        return l.usernameEmpty;
      case AuthMessageCode.usernameMinLength:
        return l.usernameMinLength;
      case AuthMessageCode.usernameMaxLength:
        return l.usernameMaxLength;
      case AuthMessageCode.usernameInvalidChars:
        return l.usernameInvalidChars;
      case AuthMessageCode.usernameStartsWithNumber:
        return l.usernameStartsWithNumber;
      case AuthMessageCode.emailEmpty:
        return l.emailEmpty;
      case AuthMessageCode.emailInvalid:
        return l.emailInvalid;
      case AuthMessageCode.passwordEmpty:
        return l.passwordEmpty;
      case AuthMessageCode.passwordMinLength:
        return l.passwordMinLength;
      case AuthMessageCode.passwordNeedsLowercase:
        return l.passwordNeedsLowercase;
      case AuthMessageCode.passwordNeedsUppercase:
        return l.passwordNeedsUppercase;
      case AuthMessageCode.usernameAndPasswordRequired:
        return l.usernameAndPasswordRequired;
      case AuthMessageCode.invalidCredentials:
        return l.invalidCredentials;
      case AuthMessageCode.onlyOneUser:
        return l.onlyOneUser;
      case AuthMessageCode.tooManyAttempts:
        return l.tooManyAttempts(message.remainingSeconds ?? 0);
      case AuthMessageCode.passwordResetSuccess:
        return l.passwordResetSuccess;
      case AuthMessageCode.securityQuestionEmpty:
        return l.securityQuestionEmpty;
      case AuthMessageCode.securityAnswerEmpty:
        return l.securityAnswerEmpty;
      case AuthMessageCode.securityAnswerWrong:
        return l.securityAnswerWrong;
      case AuthMessageCode.userNotFound:
        return l.userNotFound;
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);

    if (_isForgotPassword) {
      await _submitForgotPassword(l);
      return;
    }

    final result = await _authController.submit(
      isLogin: _isLogin,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      rememberMe: _rememberMe,
      securityQuestion: _securityQuestionController.text,
      securityAnswer: _securityAnswerController.text,
    );

    if (result.shouldClearPassword) {
      _passwordController.clear();
    }

    if (result.user != null) {
      await SessionTimeoutService.instance.startSession();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(currentUser: result.user!)),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      if (result.userExists != null) {
        _userExists = result.userExists!;
      }
      if (result.shouldSwitchToLogin) {
        _isLogin = true;
        _isForgotPassword = false;
        _forgotStep = 0;
      }
      if (result.message != null) {
        _error = _messageText(result.message!, l);
        _isSuccessMessage = result.message!.isSuccess;
      } else {
        _error = null;
        _isSuccessMessage = false;
      }
    });
  }

  Future<void> _submitForgotPassword(AppLocalizations l) async {
    if (_forgotStep == 0) {
      // Step 0: look up user and get security question
      final result = await _authController.submitForgotPassword(
        username: _usernameController.text,
      );
      if (!mounted) return;
      setState(() {
        if (result.securityQuestion != null) {
          _forgotSecurityQuestion = result.securityQuestion;
          _forgotStep = 1;
          _error = null;
          _isSuccessMessage = false;
        } else if (result.message != null) {
          _error = _messageText(result.message!, l);
          _isSuccessMessage = false;
        }
      });
    } else if (_forgotStep == 1) {
      // Step 1: verify answer → show new password field
      if (_securityAnswerController.text.trim().isEmpty) {
        setState(() {
          _error = l.securityAnswerEmpty;
          _isSuccessMessage = false;
        });
        return;
      }
      setState(() {
        _forgotStep = 2;
        _error = null;
      });
    } else {
      // Step 2: reset password
      final result = await _authController.submitResetPassword(
        username: _usernameController.text,
        securityAnswer: _securityAnswerController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      setState(() {
        if (result.message != null) {
          _error = _messageText(result.message!, l);
          _isSuccessMessage = result.message!.isSuccess;
        }
        if (result.shouldSwitchToLogin) {
          _isForgotPassword = false;
          _forgotStep = 0;
          _isLogin = true;
          _passwordController.clear();
          _securityAnswerController.clear();
          _newPasswordController.clear();
        }
      });
    }
  }

  List<Widget> _buildForgotPasswordFields(AppLocalizations l) {
    return [
      // Step 0: username
      TextField(
        controller: _usernameController,
        enabled: _forgotStep == 0,
        decoration: InputDecoration(
          labelText: l.username,
          prefixIcon: const Icon(Icons.person),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      // Step 1: show question and answer field
      if (_forgotStep >= 1) ...[
        const SizedBox(height: 16),
        Text(
          _forgotSecurityQuestion ?? '',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _securityAnswerController,
          enabled: _forgotStep == 1,
          decoration: InputDecoration(
            labelText: l.securityAnswer,
            prefixIcon: const Icon(Icons.question_answer),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
      // Step 2: new password
      if (_forgotStep >= 2) ...[
        const SizedBox(height: 16),
        TextField(
          controller: _newPasswordController,
          decoration: InputDecoration(
            labelText: l.newPassword,
            prefixIcon: const Icon(Icons.lock_reset),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          obscureText: true,
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/background.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[200]);
                },
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Color(0xFF00BCD4),
                        ),
                        const SizedBox(height: 16),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _isForgotPassword
                                ? l.forgotPassword
                                : (_isLogin ? l.login : l.register),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_isForgotPassword)
                          ..._buildForgotPasswordFields(l)
                        else ...[
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: l.username,
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) {
                              final lower = value.toLowerCase();
                              if (_usernameController.text != lower) {
                                _usernameController.value = _usernameController
                                    .value
                                    .copyWith(
                                      text: lower,
                                      selection: TextSelection.collapsed(
                                        offset: lower.length,
                                      ),
                                    );
                              }
                            },
                          ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: l.email,
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: l.password,
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: true,
                          ),
                          if (_isLogin) ...[
                            const SizedBox(height: 8),
                            CheckboxListTile(
                              value: _rememberMe,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(l.rememberMe),
                              onChanged: (value) {
                                if (value == null) return;
                                _setRememberMe(value);
                              },
                            ),
                          ],
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            TextField(
                              controller: _securityQuestionController,
                              decoration: InputDecoration(
                                labelText: l.securityQuestion,
                                prefixIcon: const Icon(Icons.help_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _securityAnswerController,
                              decoration: InputDecoration(
                                labelText: l.securityAnswer,
                                prefixIcon: const Icon(Icons.question_answer),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 24),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: _isSuccessMessage
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isForgotPassword
                                ? (_forgotStep == 2
                                      ? l.resetPassword
                                      : l.continueText)
                                : (_isLogin ? l.login : l.register),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        if (_isLogin && _userExists && !_isForgotPassword)
                          TextButton(
                            onPressed: _startForgotPassword,
                            child: Text(l.forgotPassword),
                          ),
                        if (_isForgotPassword)
                          TextButton(
                            onPressed: _cancelForgotPassword,
                            child: Text(l.backToLogin),
                          ),
                        if (!_userExists && !_isForgotPassword)
                          TextButton(
                            onPressed: _toggleMode,
                            child: Text(
                              _isLogin ? l.createAccount : l.alreadyHaveAccount,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
