import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/app_environment.dart';
import 'l10n/app_localizations.dart';
import 'pages/auth_page.dart';
import 'services/app_language_service.dart';
import 'services/session_timeout_service.dart';
import 'widgets/session_activity_detector.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLanguageService = AppLanguageService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appLanguageService,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: SessionTimeoutService.instance.navigatorKey,
          title: AppEnvironmentConfig().appTitle,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: _appLanguageService.selectedLocale,
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
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00BCD4),
            ),
          ),
          builder: (context, child) {
            final data = MediaQuery.of(context);
            final screenWidth = data.size.width;
            const designWidth = 375.0;
            final widthScale = (screenWidth / designWidth).clamp(0.82, 1.15);
            final systemScale = data.textScaler.scale(1.0);
            return SessionActivityDetector(
              child: MediaQuery(
                data: data.copyWith(
                  textScaler: TextScaler.linear(systemScale * widthScale),
                ),
                child: child!,
              ),
            );
          },
          home: const AuthPage(),
        );
      },
    );
  }
}
