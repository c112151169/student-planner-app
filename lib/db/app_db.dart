import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'tasks.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            done INTEGER NOT NULL DEFAULT 0,
            date TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT '其他',
            created_at INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v2: date
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE tasks ADD COLUMN date TEXT");
          await db.execute(
            "UPDATE tasks SET date = date('now') WHERE date IS NULL",
          );
        }
        // v3: category + created_at
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE tasks ADD COLUMN category TEXT DEFAULT '其他'",
          );
          await db.execute(
            "ALTER TABLE tasks ADD COLUMN created_at INTEGER DEFAULT 0",
          );
          await db.execute(
            "UPDATE tasks SET category='其他' WHERE category IS NULL",
          );
          await db.execute(
            "UPDATE tasks SET created_at=0 WHERE created_at IS NULL",
          );
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> getTasks({
    String orderBy = 'date ASC, id DESC',
  }) async {
    final db = await database;
    return db.query('tasks', orderBy: orderBy);
  }

  Future<void> addTask({
    required String title,
    required String date,
    required String category,
  }) async {
    final db = await database;
    await db.insert('tasks', {
      'title': title,
      'done': 0,
      'date': date,
      'category': category,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateDone(int id, bool done) async {
    final db = await database;
    await db.update(
      'tasks',
      {'done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
