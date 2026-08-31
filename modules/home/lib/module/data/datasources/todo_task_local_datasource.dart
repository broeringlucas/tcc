import 'package:common/main.dart';

class TodoTaskLocalDataSource {
  final AppDatabase database;

  TodoTaskLocalDataSource(this.database);

  Future<List<Map<String, dynamic>>> getTasks({int limit = 0}) async {
    return await database.getTasks(limit: limit);
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    return await database.insertTask(task);
  }

  Future<int> deleteTask(int id) async {
    return await database.deleteTask(id);
  }

  Future<int> updateTask(int id, Map<String, dynamic> task) async {
    return await database.updateTask(id, task);
  }
}
