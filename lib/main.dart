import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user.dart';
import 'services/database.dart';
import 'services/error_logger.dart';
import 'pages/home_page.dart';
import 'l10n/app_localizations.dart';

void main() {
  // WidgetsFlutterBinding MUTLAKA runZonedGuarded dışında başlatılmalı
  WidgetsFlutterBinding.ensureInitialized();

  // Tüm hataları yakalamak için runZonedGuarded kullan
  runZonedGuarded(
    () {
      // Flutter framework hatalarını yakala
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        // Hatayı logla - fire-and-forget
        try {
          ErrorLogger().logFlutterError(details);
        } catch (_) {}
      };

      // Platform dispatcher hataları (async hatalar)
      PlatformDispatcher.instance.onError = (error, stack) {
        try {
          ErrorLogger().logError(
            error: error.toString(),
            stackTrace: stack.toString(),
            level: 'PLATFORM_ERROR',
          );
        } catch (_) {}
        return true;
      };

      // Release modda beyaz ekran yerine kullanıcı dostu hata göster
      ErrorWidget.builder = (FlutterErrorDetails details) {
        // Hatayı logla - fire-and-forget
        try {
          ErrorLogger().logFlutterError(details);
        } catch (_) {}

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFFE57373),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Beklenmeyen bir hata oluştu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Uygulamayı yeniden başlatın.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      };

      runApp(const MyApp());

      // Uygulama başlangıcını logla - runApp'ten SONRA, fire-and-forget
      try {
        ErrorLogger().logInfo(
          message:
              'App started - v${AppVersionInfo.fullVersion} | '
              '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        );
      } catch (_) {}
    },
    (error, stack) {
      // Zone dışı hatalar (catch edilmeyen async hatalar)
      try {
        ErrorLogger().logError(
          error: error.toString(),
          stackTrace: stack.toString(),
          level: 'UNCAUGHT_ERROR',
        );
      } catch (_) {}
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P-Trainer',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('en');
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00BCD4)),
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _userExists = false;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _db = AppDatabase();

  // Performans: RegExp nesneleri her validasyonda yeniden oluşturulmasın
  static final _usernameRegex = RegExp(r'^[a-z0-9_.]+$');
  static final _usernameStartRegex = RegExp(r'^[0-9]');
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final _lowercaseRegex = RegExp(r'[a-z]');
  static final _uppercaseRegex = RegExp(r'[A-Z]');

  String? _error;
  int _loginAttempts = 0;
  DateTime? _lockoutUntil;

  @override
  void initState() {
    super.initState();
    _checkUserExists();
    _loadSavedUsername();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('saved_username');
      if (savedUsername != null && savedUsername.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _usernameController.text = savedUsername;
        });
      }
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: '_AuthPageState._loadSavedUsername',
      );
    }
  }

  Future<void> _saveUsername(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', username);
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: '_AuthPageState._saveUsername',
      );
    }
  }

  Future<void> _checkUserExists() async {
    try {
      final exists = await _db.userExists();
      if (!mounted) return;
      setState(() {
        _userExists = exists;
        if (exists) {
          _isLogin = true;
        }
      });
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: '_AuthPageState._checkUserExists',
      );
      if (!mounted) return;
      setState(() {
        _userExists = false;
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
    });
  }

  String? _validateUsername(String username) {
    final l = AppLocalizations.of(context);
    if (username.isEmpty) {
      return l.usernameEmpty;
    }
    if (username.length < 3) {
      return l.usernameMinLength;
    }
    if (username.length > 20) {
      return l.usernameMaxLength;
    }
    if (!_usernameRegex.hasMatch(username)) {
      return l.usernameInvalidChars;
    }
    if (_usernameStartRegex.hasMatch(username)) {
      return l.usernameStartsWithNumber;
    }
    return null;
  }

  String? _validateEmail(String email) {
    final l = AppLocalizations.of(context);
    if (email.isEmpty) {
      return l.emailEmpty;
    }
    if (!_emailRegex.hasMatch(email)) {
      return l.emailInvalid;
    }
    return null;
  }

  String? _validatePassword(String password) {
    final l = AppLocalizations.of(context);
    if (password.isEmpty) {
      return l.passwordEmpty;
    }
    if (password.length < 8) {
      return l.passwordMinLength;
    }
    if (!_lowercaseRegex.hasMatch(password)) {
      return l.passwordNeedsLowercase;
    }
    if (!_uppercaseRegex.hasMatch(password)) {
      return l.passwordNeedsUppercase;
    }
    return null;
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final l = AppLocalizations.of(context);

    if (_isLogin) {
      if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
        final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
        setState(() {
          _error = l.tooManyAttempts(remaining);
        });
        return;
      }

      if (username.isEmpty || password.isEmpty) {
        setState(() {
          _error = l.usernameAndPasswordRequired;
        });
        return;
      }
      final user = await _db.authenticate(username, password);
      if (user != null) {
        _loginAttempts = 0; // Başarılı girişte sayacı sıfırla
        _passwordController.clear(); // Şifreyi bellekten temizle
        if (!mounted) return;
        await _saveUsername(username); // Kullanıcı adını hatırla
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(currentUser: user)),
        );
      } else {
        _loginAttempts++;
        if (_loginAttempts >= 5) {
          _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
          _loginAttempts = 0;
        }
        setState(() {
          _error = l.invalidCredentials;
        });
      }
    } else {
      // Kayıt için detaylı validasyon
      final usernameError = _validateUsername(username);
      if (usernameError != null) {
        setState(() => _error = usernameError);
        return;
      }

      final email = _emailController.text.trim();
      final emailError = _validateEmail(email);
      if (emailError != null) {
        setState(() => _error = emailError);
        return;
      }

      final passwordError = _validatePassword(password);
      if (passwordError != null) {
        setState(() => _error = passwordError);
        return;
      }

      // Restrict registration to a single user
      final exists = await _db.userExists();
      if (exists) {
        setState(() {
          _error = l.onlyOneUser;
        });
        return;
      }

      final (hashed, salt) = AppDatabase.hashPassword(password);
      final user = User(
        username: username,
        email: email,
        password: hashed,
        salt: salt,
      );
      await _db.insertUser(user);
      _passwordController.clear();
      await _checkUserExists();
      setState(() {
        _isLogin = true;
        _error = l.registrationSuccess;
      });
    }
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
          // Login formu - Ortalanmış
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
                        // Logo/Başlık
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
                                color: _error!.contains(l.registrationSuccess)
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
