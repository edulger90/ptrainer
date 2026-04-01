import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'error_logger.dart';
import 'premium_service.dart';

class StartupService {
  Future<void> bootstrap(Future<void> Function() appRunner) async {
    runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();
        _configureFlutterErrorHandling();
        _configurePlatformErrorHandling();
        _configureErrorWidget();

        PremiumService().init();

        await appRunner();
        _logAppStart();
      },
      (error, stack) {
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

  void _configureFlutterErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      try {
        ErrorLogger().logFlutterError(details);
      } catch (_) {}
    };
  }

  void _configurePlatformErrorHandling() {
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
  }

  void _configureErrorWidget() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
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
                'Uygulamayi yeniden baslatin.',
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
  }

  void _logAppStart() {
    try {
      ErrorLogger().logInfo(
        message:
            'App started - v${AppVersionInfo.fullVersion} | '
            '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      );
    } catch (_) {}
  }
}
