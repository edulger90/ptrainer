import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_controller.dart';
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
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController();

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    final state = await _authController.loadInitialState();
    if (!mounted) return;
    setState(() {
      _userExists = state.userExists;
      _isLogin = state.isLogin;
      if (state.savedUsername != null) {
        _usernameController.text = state.savedUsername!;
      }
    });
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
      _isSuccessMessage = false;
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
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final result = await _authController.submit(
      isLogin: _isLogin,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (result.shouldClearPassword) {
      _passwordController.clear();
    }

    if (result.user != null) {
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
                        Text(
                          _isLogin ? l.login : l.register,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
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
                            _isLogin ? l.login : l.register,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        if (!_userExists)
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
