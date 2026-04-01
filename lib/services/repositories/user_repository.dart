import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../models/user.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  const UserRepository(super.databaseProvider);

  Future<int> insertUser(User user) async {
    final db = await database;
    return db.insert('users', user.toMap());
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<User?> authenticate(String username, String password) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (maps.isEmpty) return null;

    final user = User.fromMap(maps.first);
    final salt = user.salt;
    final expectedHash = salt != null && salt.isNotEmpty
        ? _hashWithSalt(_hashUnsalted(password), salt)
        : _hashUnsalted(password);

    return user.password == expectedHash ? user : null;
  }

  Future<bool> userExists() async {
    final db = await database;
    final users = await db.query('users');
    return users.isNotEmpty;
  }

  static (String hash, String salt) hashPassword(String password) {
    final unsalted = _hashUnsalted(password);
    final salt = _generateSalt();
    final salted = _hashWithSalt(unsalted, salt);
    return (salted, salt);
  }

  static String _generateSalt() {
    final now = DateTime.now().microsecondsSinceEpoch.toString();
    final bytes = utf8.encode(now);
    return sha256.convert(bytes).toString().substring(0, 32);
  }

  static String _hashWithSalt(String input, String salt) {
    final bytes = utf8.encode(input + salt);
    return sha256.convert(bytes).toString();
  }

  static String _hashUnsalted(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
