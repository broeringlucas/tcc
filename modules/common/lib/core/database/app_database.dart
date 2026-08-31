import 'package:dependencies/path_provider.dart';
import 'package:dependencies/sqlite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;
  bool _isSeeded = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'tasks.db');

    return await openDatabase(dbPath, version: 2, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        completed INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> ensureSeeded() async {
    if (_isSeeded) return;

    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tasks'));

    if (count == 0) {
      print('Database is empty. Seeding 10,000 tasks...');
      final start = DateTime.now();

      final batch = db.batch();
      for (int i = 1; i <= 100000; i++) {
        batch.insert('tasks', {
          'title': 'Task $i',
          'description': 'Description for task $i.',
          'completed': i % 3 == 0 ? 1 : 0,
        });
      }
      await batch.commit(noResult: true);

      final duration = DateTime.now().difference(start);
      print('Seeded 10,000 tasks in ${duration.inMilliseconds}ms');
    }

    _isSeeded = true;
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasks({int limit = 0}) async {
    final db = await database;
    if (limit > 0) {
      return await db.query('tasks', limit: limit);
    }
    return await db.query('tasks');
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTask(int id, Map<String, dynamic> task) async {
    final db = await database;
    return await db.update('tasks', task, where: 'id = ?', whereArgs: [id]);
  }
}
