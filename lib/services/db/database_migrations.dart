import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabaseMigrations {
  static const int currentVersion = 18;

  Future<void> create(Database db) async {
    await _createUsersTable(db);
    await _createClientsTable(db);
    await _createBodyMeasurementsTable(db);
    await _createSessionSchedulesTable(db);
    await _createPeriodsTable(db);
    await _createAttendancesTable(db);
    await createIndexes(db);
  }

  Future<void> upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE users ADD COLUMN password TEXT DEFAULT ''");
    }
    if (oldVersion < 3) {
      await _rehashLegacyPasswords(db);
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clients(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          firstName TEXT NOT NULL,
          lastName TEXT NOT NULL,
          sessionPackage INTEGER NOT NULL,
          FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 5) {
      await _createBodyMeasurementsTable(db);
      await _migrateLegacyMeasurements(db);
    }
    if (oldVersion < 6) {
      await _createSessionSchedulesTable(db);
    }
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE clients ADD COLUMN createdAt TEXT');
      } catch (_) {}
      final now = DateTime.now().toIso8601String();
      await db.execute(
        'UPDATE clients SET createdAt = ? WHERE createdAt IS NULL',
        [now],
      );
    }
    if (oldVersion < 8) {
      await _createPeriodsTable(db);
    }
    if (oldVersion < 9) {
      await _createAttendancesTable(db);
    }
    if (oldVersion < 10) {
      try {
        await db.execute('ALTER TABLE periods ADD COLUMN paymentAmount REAL');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE periods ADD COLUMN isPaid INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 11) {
      try {
        await db.execute(
          'ALTER TABLE periods ADD COLUMN postponedEndDate TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE attendances ADD COLUMN cancelled INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 12) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN salt TEXT');
      } catch (_) {}
      await _rehashExistingSaltedPasswords(db);
    }
    if (oldVersion < 13) {
      try {
        await db.execute(
          'ALTER TABLE clients ADD COLUMN registrationDate TEXT',
        );
      } catch (_) {}
      await db.execute(
        'UPDATE clients SET registrationDate = createdAt WHERE registrationDate IS NULL',
      );
    }
    if (oldVersion < 14) {
      try {
        await db.execute(
          'ALTER TABLE clients ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1',
        );
      } catch (_) {}
    }
    if (oldVersion < 15) {
      try {
        await db.execute('ALTER TABLE attendances ADD COLUMN reason INTEGER');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE attendances ADD COLUMN isPostponed INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 16) {
      await createIndexes(db);
    }
    if (oldVersion < 17) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN securityQuestion TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN securityAnswer TEXT');
      } catch (_) {}
    }
    if (oldVersion < 18) {
      try {
        await db.execute(
          "ALTER TABLE clients ADD COLUMN packageType TEXT NOT NULL DEFAULT 'daily'",
        );
      } catch (_) {}
    }
  }

  Future<void> createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_clients_user_id ON clients(userId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_body_measurements_client_date '
      'ON body_measurements(clientId, date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_session_schedules_client_day_time '
      'ON session_schedules(clientId, dayOfWeek, time)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_periods_client_start_date '
      'ON periods(clientId, startDate DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_attendances_client_period_lesson_makeup '
      'ON attendances(clientId, periodId, lessonDate, makeupDate)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_attendances_period_lesson_makeup '
      'ON attendances(periodId, lessonDate, makeupDate)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_attendances_client_lesson '
      'ON attendances(clientId, lessonDate)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_attendances_client_makeup '
      'ON attendances(clientId, makeupDate)',
    );
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        salt TEXT,
        securityQuestion TEXT,
        securityAnswer TEXT
      )
    ''');
  }

  Future<void> _createClientsTable(Database db) async {
    await db.execute('''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        sessionPackage INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        registrationDate TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        packageType TEXT NOT NULL DEFAULT 'daily',
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createBodyMeasurementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS body_measurements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        date TEXT NOT NULL,
        chest REAL,
        waist REAL,
        hips REAL,
        FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createSessionSchedulesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS session_schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        dayOfWeek TEXT NOT NULL,
        time TEXT NOT NULL,
        FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createPeriodsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS periods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        postponedEndDate TEXT,
        paymentAmount REAL,
        isPaid INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createAttendancesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendances(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        periodId INTEGER NOT NULL,
        lessonDate TEXT NOT NULL,
        attended INTEGER NOT NULL,
        cancelled INTEGER NOT NULL DEFAULT 0,
        isPostponed INTEGER NOT NULL DEFAULT 0,
        attendedDate TEXT,
        makeupDate TEXT,
        reason INTEGER,
        FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE CASCADE,
        FOREIGN KEY (periodId) REFERENCES periods(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _migrateLegacyMeasurements(Database db) async {
    final clients = await db.query('clients');
    for (final client in clients) {
      final chest = client['chest'] as double?;
      final waist = client['waist'] as double?;
      final hips = client['hips'] as double?;
      if (chest != null || waist != null || hips != null) {
        await db.insert('body_measurements', {
          'clientId': client['id'],
          'date': DateTime.now().toIso8601String(),
          'chest': chest,
          'waist': waist,
          'hips': hips,
        });
      }
    }
  }

  Future<void> _rehashLegacyPasswords(Database db) async {
    final maps = await db.query('users');
    for (final user in maps) {
      final password = user['password'] as String? ?? '';
      if (password.isNotEmpty && !_looksHashed(password)) {
        await db.update(
          'users',
          {'password': _hashUnsalted(password)},
          where: 'id = ?',
          whereArgs: [user['id']],
        );
      }
    }
  }

  Future<void> _rehashExistingSaltedPasswords(Database db) async {
    final users = await db.query('users');
    for (final user in users) {
      final existingHash = user['password'] as String? ?? '';
      if (existingHash.isNotEmpty) {
        final salt = _generateSalt();
        final saltedHash = _hashWithSalt(existingHash, salt);
        await db.update(
          'users',
          {'password': saltedHash, 'salt': salt},
          where: 'id = ?',
          whereArgs: [user['id']],
        );
      }
    }
  }

  bool _looksHashed(String value) {
    final hexRegex = RegExp(r'^[a-f0-9]{64}$');
    return hexRegex.hasMatch(value);
  }

  String _generateSalt() {
    final now = DateTime.now().microsecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(now)).toString().substring(0, 32);
  }

  String _hashWithSalt(String input, String salt) {
    return sha256.convert(utf8.encode(input + salt)).toString();
  }

  String _hashUnsalted(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
