import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/client.dart';
import '../models/body_measurement.dart';
import '../models/session_schedule.dart';
import '../models/period.dart';

class AppDatabase {
  /// Update a body measurement
  Future<int> updateBodyMeasurement(BodyMeasurement measurement) async {
    final db = await database;
    if (measurement.id == null) {
      throw ArgumentError('Measurement id is required for update');
    }
    return db.update(
      'body_measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  static Database? _db;

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
      version: 15,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            email TEXT NOT NULL,
            password TEXT NOT NULL,
            salt TEXT
          )
        ''');
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
            FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE body_measurements(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clientId INTEGER NOT NULL,
            date TEXT NOT NULL,
            chest REAL,
            waist REAL,
            hips REAL,
            FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE session_schedules(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            clientId INTEGER NOT NULL,
            dayOfWeek TEXT NOT NULL,
            time TEXT NOT NULL,
            FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE periods(
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
        await db.execute('''
          CREATE TABLE attendances(
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
      },
      onOpen: (db) async {
        // Foreign key desteğini etkinleştir
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 15) {
          // Add reason column to attendances
          try {
            await db.execute(
              'ALTER TABLE attendances ADD COLUMN reason INTEGER',
            );
          } catch (e) {
            // column may already exist
          }
          // Add isPostponed column to attendances
          try {
            await db.execute(
              'ALTER TABLE attendances ADD COLUMN isPostponed INTEGER NOT NULL DEFAULT 0',
            );
          } catch (e) {
            // column may already exist
          }
        }
        if (oldVersion < 2) {
          // add password column for older databases
          await db.execute('''
            ALTER TABLE users ADD COLUMN password TEXT DEFAULT ''
          ''');
        }
        if (oldVersion < 3) {
          // re-hash any existing plaintext passwords (legacy unsalted)
          final maps = await db.query('users');
          for (final m in maps) {
            final pwd = m['password'] as String? ?? '';
            if (pwd.isNotEmpty && !_looksHashed(pwd)) {
              final hashed = _hashUnsalted(pwd);
              await db.update(
                'users',
                {'password': hashed},
                where: 'id = ?',
                whereArgs: [m['id']],
              );
            }
          }
        }
        if (oldVersion < 4) {
          // create clients table
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
          // create body_measurements table
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
          // Migrate existing measurements if they exist
          final clients = await db.query('clients');
          for (final c in clients) {
            final chest = c['chest'] as double?;
            final waist = c['waist'] as double?;
            final hips = c['hips'] as double?;
            if (chest != null || waist != null || hips != null) {
              await db.insert('body_measurements', {
                'clientId': c['id'],
                'date': DateTime.now().toIso8601String(),
                'chest': chest,
                'waist': waist,
                'hips': hips,
              });
            }
          }
        }
        if (oldVersion < 6) {
          // create session_schedules table
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
        if (oldVersion < 7) {
          // add createdAt column to clients and backfill existing rows
          try {
            await db.execute('ALTER TABLE clients ADD COLUMN createdAt TEXT');
          } catch (e) {
            // column may already exist
          }
          final now = DateTime.now().toIso8601String();
          await db.execute(
            "UPDATE clients SET createdAt = ? WHERE createdAt IS NULL",
            [now],
          );
        }
        if (oldVersion < 8) {
          // add periods table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS periods(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clientId INTEGER NOT NULL,
              startDate TEXT NOT NULL,
              endDate TEXT NOT NULL,
              FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS attendances(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clientId INTEGER NOT NULL,
              periodId INTEGER NOT NULL,
              lessonDate TEXT NOT NULL,
              attended INTEGER NOT NULL,
              attendedDate TEXT,
              makeupDate TEXT,
              FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE CASCADE,
              FOREIGN KEY (periodId) REFERENCES periods(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 10) {
          // Add payment fields to periods table
          try {
            await db.execute(
              'ALTER TABLE periods ADD COLUMN paymentAmount REAL',
            );
          } catch (e) {
            // column may already exist
          }
          try {
            await db.execute(
              'ALTER TABLE periods ADD COLUMN isPaid INTEGER NOT NULL DEFAULT 0',
            );
          } catch (e) {
            // column may already exist
          }
        }
        if (oldVersion < 11) {
          // Add postponedEndDate to periods
          try {
            await db.execute(
              'ALTER TABLE periods ADD COLUMN postponedEndDate TEXT',
            );
          } catch (e) {
            // column may already exist
          }
          // Add cancelled column to attendances
          try {
            await db.execute(
              'ALTER TABLE attendances ADD COLUMN cancelled INTEGER NOT NULL DEFAULT 0',
            );
          } catch (e) {
            // column may already exist
          }
        }
        if (oldVersion < 12) {
          // Add salt column to users table
          try {
            await db.execute('ALTER TABLE users ADD COLUMN salt TEXT');
          } catch (e) {
            // column may already exist
          }
          // Re-hash existing passwords with salt
          final users = await db.query('users');
          for (final u in users) {
            final existingHash = u['password'] as String? ?? '';
            if (existingHash.isNotEmpty) {
              final salt = _generateSalt();
              final saltedHash = _hashWithSalt(existingHash, salt);
              await db.update(
                'users',
                {'password': saltedHash, 'salt': salt},
                where: 'id = ?',
                whereArgs: [u['id']],
              );
            }
          }
        }
        if (oldVersion < 13) {
          // Add registrationDate column to clients
          try {
            await db.execute(
              'ALTER TABLE clients ADD COLUMN registrationDate TEXT',
            );
          } catch (e) {
            // column may already exist
          }
          // Backfill registrationDate from createdAt for existing clients
          await db.execute(
            'UPDATE clients SET registrationDate = createdAt WHERE registrationDate IS NULL',
          );
        }
        if (oldVersion < 14) {
          // Add isActive column to clients
          try {
            await db.execute(
              'ALTER TABLE clients ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1',
            );
          } catch (e) {
            // column may already exist
          }
        }
      },
    );
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return db.insert('users', user.toMap());
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((m) => User.fromMap(m)).toList();
  }

  Future<User?> authenticate(String username, String password) async {
    final db = await database;
    // First fetch user by username to get their salt
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (maps.isEmpty) return null;

    final user = User.fromMap(maps.first);
    final salt = user.salt;
    String expectedHash;
    if (salt != null && salt.isNotEmpty) {
      expectedHash = _hashWithSalt(_hashUnsalted(password), salt);
    } else {
      // Legacy fallback for users without salt (shouldn't happen after migration)
      expectedHash = _hashUnsalted(password);
    }

    if (user.password == expectedHash) {
      return user;
    }
    return null;
  }

  /// Generate a cryptographically random salt (32 hex chars)
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return saltBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hash with salt: SHA-256(existingHash + salt)
  static String _hashWithSalt(String input, String salt) {
    final bytes = utf8.encode(input + salt);
    return sha256.convert(bytes).toString();
  }

  /// Hash input with SHA-256 and a random salt. Returns (hash, salt).
  static (String hash, String salt) hashPassword(String password) {
    final unsalted = _hashUnsalted(password);
    final salt = _generateSalt();
    final salted = _hashWithSalt(unsalted, salt);
    return (salted, salt);
  }

  /// Plain SHA-256 (used as intermediate step before salting)
  static String _hashUnsalted(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  bool _looksHashed(String s) {
    // naive check: SHA-256 produces 64 lowercase hex characters
    final hexRegex = RegExp(r'^[a-f0-9]{64}$');
    return hexRegex.hasMatch(s);
  }

  /// Insert a new client
  Future<int> insertClient(Client client) async {
    final db = await database;
    return db.insert('clients', client.toMap());
  }

  /// Update an existing client
  Future<int> updateClient(Client client) async {
    final db = await database;
    return db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  /// Get all clients for a user
  Future<List<Client>> getClientsByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      'clients',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  /// Insert a body measurement for a client
  Future<int> insertBodyMeasurement(BodyMeasurement measurement) async {
    final db = await database;
    return db.insert('body_measurements', measurement.toMap());
  }

  /// Get all body measurements for a client, ordered by date (newest first)
  Future<List<BodyMeasurement>> getBodyMeasurementsByClient(
    int clientId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'body_measurements',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => BodyMeasurement.fromMap(m)).toList();
  }

  /// Get the latest body measurement for a client
  Future<BodyMeasurement?> getLatestBodyMeasurement(int clientId) async {
    final db = await database;
    final maps = await db.query(
      'body_measurements',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return BodyMeasurement.fromMap(maps.first);
    }
    return null;
  }

  /// Insert a session schedule for a client
  Future<int> insertSessionSchedule(SessionSchedule schedule) async {
    final db = await database;
    return db.insert('session_schedules', schedule.toMap());
  }

  /// Insert a new training period record
  Future<int> insertPeriod(Period period) async {
    final db = await database;
    return db.insert('periods', period.toMap());
  }

  /// Update a period
  Future<int> updatePeriod(Period period) async {
    final db = await database;
    return db.update(
      'periods',
      period.toMap(),
      where: 'id = ?',
      whereArgs: [period.id],
    );
  }

  /// Get the latest period for a given client (most recent by startDate)
  Future<Period?> getLatestPeriodForClient(int clientId) async {
    final db = await database;
    final maps = await db.query(
      'periods',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'startDate DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Period.fromMap(maps.first);
  }

  /// Get completed lesson count for a specific period
  /// "Completed" = attendance record exists AND cancelled == 0
  /// Get all periods for a given client (ordered by start date desc)
  Future<List<Period>> getPeriodsByClient(int clientId) async {
    final db = await database;
    final maps = await db.query(
      'periods',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'startDate DESC',
    );
    return maps.map((m) => Period.fromMap(m)).toList();
  }

  /// Get all session schedules for a client
  Future<List<SessionSchedule>> getSessionSchedulesByClient(
    int clientId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'session_schedules',
      where: 'clientId = ?',
      whereArgs: [clientId],
    );
    return maps.map((m) => SessionSchedule.fromMap(m)).toList();
  }

  /// Update a session schedule
  Future<int> updateSessionSchedule(SessionSchedule schedule) async {
    final db = await database;
    return db.update(
      'session_schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  /// Delete a session schedule
  Future<int> deleteSessionSchedule(int scheduleId) async {
    final db = await database;
    return db.delete(
      'session_schedules',
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  /// Toggle client active/passive status
  Future<void> toggleClientActive(int clientId, bool isActive) async {
    final db = await database;
    await db.update(
      'clients',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [clientId],
    );
  }

  /// Delete a client and all associated data
  Future<int> deleteClient(int clientId) async {
    final db = await database;
    return db.delete('clients', where: 'id = ?', whereArgs: [clientId]);
  }

  /// Insert or update attendance for a lesson day
  Future<void> upsertAttendance({
    required int clientId,
    required int periodId,
    required DateTime lessonDate,
    required bool attended,
    bool cancelled = false,
    bool isPostponed = false,
    DateTime? attendedDate,
    DateTime? makeupDate,
    int? reason,
  }) async {
    final db = await database;
    final lessonDateStr = lessonDate.toIso8601String();
    final attendedDateStr = attendedDate?.toIso8601String();
    final makeupDateStr = makeupDate?.toIso8601String();
    // Check if record exists
    final existing = await db.query(
      'attendances',
      where: 'clientId = ? AND periodId = ? AND lessonDate = ?',
      whereArgs: [clientId, periodId, lessonDateStr],
    );
    if (existing.isNotEmpty) {
      await db.update(
        'attendances',
        {
          'attended': attended ? 1 : 0,
          'cancelled': cancelled ? 1 : 0,
          'isPostponed': isPostponed ? 1 : 0,
          'attendedDate': attendedDateStr,
          'makeupDate': makeupDateStr,
          'reason': reason,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('attendances', {
        'clientId': clientId,
        'periodId': periodId,
        'lessonDate': lessonDateStr,
        'attended': attended ? 1 : 0,
        'cancelled': cancelled ? 1 : 0,
        'isPostponed': isPostponed ? 1 : 0,
        'attendedDate': attendedDateStr,
        'makeupDate': makeupDateStr,
        'reason': reason,
      });
    }
  }

  /// Get attendance records for a period
  Future<Map<DateTime, Map<String, dynamic>>> getAttendanceForPeriod(
    int clientId,
    int periodId,
  ) async {
    final db = await database;
    final records = await db.query(
      'attendances',
      where: 'clientId = ? AND periodId = ?',
      whereArgs: [clientId, periodId],
    );
    final result = <DateTime, Map<String, dynamic>>{};
    for (final r in records) {
      final lessonDate = DateTime.parse(r['lessonDate'] as String);
      result[lessonDate] = r;
    }
    return result;
  }

  /// Check if a user already exists
  Future<bool> userExists() async {
    final db = await database;
    final users = await db.query('users');
    return users.isNotEmpty;
  }
}
