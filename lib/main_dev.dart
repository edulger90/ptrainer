import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_environment.dart';
import 'services/startup_service.dart';

Future<void> main() async {
  AppEnvironmentConfig().setEnvironment(AppEnvironment.dev);

  await StartupService().bootstrap(() async {
    runApp(const MyApp());
  });
}
