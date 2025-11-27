import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> getDB() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'user.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE,
            password TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  static Future<void> insertUser(String email, String password) async {
    final db = await getDB();
    await db.insert(
      'users',
      {'email': email, 'password': password},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, String>?> getUser(String email) async {
    final db = await getDB();
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (res.isEmpty) return null;
    return {'email': res.first['email'] as String, 'password': res.first['password'] as String};
  }

  static Future<void> updatePassword(String email, String password) async {
    final db = await getDB();
    await db.update('users', {'password': password}, where: 'email = ?', whereArgs: [email]);
  }
}
