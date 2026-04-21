import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Offline hata loglama servisi.
/// Tüm hatalar SQLite veritabanına kaydedilir.
/// Kullanıcı hata loglarını görüntüleyebilir ve dışa aktarabilir.
class ErrorLogger {
  static final ErrorLogger _instance = ErrorLogger._internal();
  factory ErrorLogger() => _instance;
  ErrorLogger._internal();

  static Database? _db;
  static const int _maxLogEntries = 500; // Maksimum log sayısı

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'error_logs.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE error_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            level TEXT NOT NULL,
            error TEXT NOT NULL,
            stackTrace TEXT,
            route TEXT,
            appVersion TEXT,
            dartVersion TEXT,
            platform TEXT,
            deviceInfo TEXT,
            extra TEXT
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_error_logs_timestamp ON error_logs(timestamp DESC)
        ''');
        await db.execute('''
          CREATE INDEX idx_error_logs_level ON error_logs(level)
        ''');
      },
    );
  }

  /// Hata logla
  Future<void> logError({
    required String error,
    String? stackTrace,
    String level = 'ERROR',
    String? route,
    String? appVersion,
    String? extra,
  }) async {
    try {
      final db = await _database;

      await db.insert('error_logs', {
        'timestamp': DateTime.now().toIso8601String(),
        'level': level,
        'error': error,
        'stackTrace': stackTrace,
        'route': route,
        'appVersion': appVersion ?? AppVersionInfo.version,
        'dartVersion': Platform.version.split(' ').first,
        'platform':
            '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        'deviceInfo': _getDeviceInfo(),
        'extra': extra,
      });

      // Log limitini aş, eski logları temizle
      await _pruneOldLogs(db);
    } catch (e) {
      // Hata loglarken hata olursa sessizce devam et
      debugPrint('ErrorLogger: Loglama hatası: $e');
    }
  }

  /// Uyarı logla
  Future<void> logWarning({
    required String message,
    String? stackTrace,
    String? route,
    String? extra,
  }) async {
    await logError(
      error: message,
      stackTrace: stackTrace,
      level: 'WARNING',
      route: route,
      extra: extra,
    );
  }

  /// Bilgi logla
  Future<void> logInfo({
    required String message,
    String? route,
    String? extra,
  }) async {
    await logError(error: message, level: 'INFO', route: route, extra: extra);
  }

  /// Flutter framework hatalarını logla
  Future<void> logFlutterError(FlutterErrorDetails details) async {
    await logError(
      error: details.exceptionAsString(),
      stackTrace: details.stack?.toString(),
      level: 'FLUTTER_ERROR',
      extra: details.context?.toString(),
    );
  }

  /// Tüm logları getir (en yeniden en eskiye)
  Future<List<Map<String, dynamic>>> getAllLogs({
    int limit = 100,
    int offset = 0,
    String? level,
  }) async {
    final db = await _database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (level != null) {
      where = 'level = ?';
      whereArgs = [level];
    }

    return db.query(
      'error_logs',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Toplam log sayısı
  Future<int> getLogCount({String? level}) async {
    final db = await _database;
    String sql = 'SELECT COUNT(*) as count FROM error_logs';
    List<dynamic> args = [];

    if (level != null) {
      sql += ' WHERE level = ?';
      args = [level];
    }

    final result = await db.rawQuery(sql, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Logları metin dosyasına dışa aktar
  Future<String> exportLogs() async {
    final db = await _database;
    final logs = await db.query('error_logs', orderBy: 'timestamp DESC');

    final buffer = StringBuffer();
    buffer.writeln('=== P-Trainer Error Logs ===');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln('App Version: ${AppVersionInfo.version}');
    buffer.writeln('Build: ${AppVersionInfo.buildNumber}');
    buffer.writeln('Total Entries: ${logs.length}');
    buffer.writeln('${'=' * 40}\n');

    for (final log in logs) {
      buffer.writeln('--- [${log['level']}] ${log['timestamp']} ---');
      buffer.writeln('Error: ${log['error']}');
      if (log['stackTrace'] != null &&
          (log['stackTrace'] as String).isNotEmpty) {
        buffer.writeln('Stack Trace:');
        buffer.writeln(log['stackTrace']);
      }
      if (log['route'] != null) buffer.writeln('Route: ${log['route']}');
      buffer.writeln('Version: ${log['appVersion']}');
      buffer.writeln('Platform: ${log['platform']}');
      if (log['extra'] != null) buffer.writeln('Extra: ${log['extra']}');
      buffer.writeln();
    }

    // Dosyaya kaydet
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'ptrainer_error_logs.txt'));
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  /// Tüm logları temizle
  Future<void> clearAllLogs() async {
    final db = await _database;
    await db.delete('error_logs');
  }

  /// Tek bir logu sil
  Future<void> deleteLog(int id) async {
    final db = await _database;
    await db.delete('error_logs', where: 'id = ?', whereArgs: [id]);
  }

  /// Eski logları temizle (limit aşıldığında)
  Future<void> _pruneOldLogs(Database db) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM error_logs'),
        ) ??
        0;

    if (count > _maxLogEntries) {
      final overflow = count - _maxLogEntries;
      await db.rawDelete(
        'DELETE FROM error_logs WHERE id IN '
        '(SELECT id FROM error_logs ORDER BY timestamp ASC LIMIT ?)',
        [overflow],
      );
    }
  }

  String _getDeviceInfo() {
    try {
      return '${Platform.localHostname} | '
          '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (e) {
      return 'unknown';
    }
  }
}

/// Uygulama versiyon bilgileri.
/// pubspec.yaml'daki version alanından alınır.
class AppVersionInfo {
  // Bu değerler her build'de güncellenmelidir
  static const String version = '1.0.5';
  static const String buildNumber = '13';
  static const String fullVersion = '$version+$buildNumber';
  static const String copyrightNotice =
      'Copyright © 2026 Ece Geçit. All rights reserved.';

  // Versiyon geçmişi (her release'de güncelle)
  static const List<Map<String, String>> changelog = [
    {
      'version': '1.0.0',
      'date': '2025-01-01',
      'changes':
          'İlk sürüm: Sporcu yönetimi, periyot takibi, '
          'beden ölçümleri, haftalık plan, çoklu dil desteği (TR/EN/ES/NL).',
    },
  ];
}
