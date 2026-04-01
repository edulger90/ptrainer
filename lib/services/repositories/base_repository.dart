import 'package:sqflite/sqflite.dart';

typedef DatabaseProvider = Future<Database> Function();

abstract class BaseRepository {
  const BaseRepository(this.databaseProvider);

  final DatabaseProvider databaseProvider;

  Future<Database> get database => databaseProvider();

  String placeholders(int count) {
    return List.filled(count, '?').join(', ');
  }
}
