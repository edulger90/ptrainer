import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../repositories/base_repository.dart';
import 'database_migrations.dart';

class AppDatabaseConnection {
  AppDatabaseConnection._internal();

  static final AppDatabaseConnection _instance =
      AppDatabaseConnection._internal();

  factory AppDatabaseConnection() => _instance;

  Database? _db;
  final _migrations = AppDatabaseMigrations();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app.db');

    return openDatabase(
      path,
      version: AppDatabaseMigrations.currentVersion,
      onCreate: (db, version) async {
        await _migrations.create(db);
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrations.upgrade(db, oldVersion, newVersion);
      },
    );
  }
}

Future<Database> appDatabaseProvider() => AppDatabaseConnection().database;

DatabaseProvider get sharedDatabaseProvider => appDatabaseProvider;
