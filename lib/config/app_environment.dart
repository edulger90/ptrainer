enum AppEnvironment { main, dev }

class AppEnvironmentConfig {
  static final AppEnvironmentConfig _instance =
      AppEnvironmentConfig._internal();

  factory AppEnvironmentConfig() => _instance;

  AppEnvironmentConfig._internal();

  AppEnvironment _current = AppEnvironment.main;

  AppEnvironment get current => _current;

  bool get isDev => _current == AppEnvironment.dev;

  String get name => _current.name;

  String get appTitle => isDev ? 'P-Trainer Dev' : 'P-Trainer';

  void setEnvironment(AppEnvironment environment) {
    _current = environment;
  }
}
