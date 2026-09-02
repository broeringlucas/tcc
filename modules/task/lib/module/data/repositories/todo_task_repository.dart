import 'package:common/main.dart';
import 'package:dependencies/dartz.dart';

import '../../../main.dart';

class TodoTaskRepositoryImpl implements TodoTaskRepository {
  final TodoTaskLocalDataSource dataSource;

  TodoTaskRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<TodoTask>>> getTasks({int limit = 0}) async {
    try {
      final maps = await dataSource.getTasks(limit: limit);
      final tasks = maps.map((map) => TodoTaskModel.fromMap(map).toEntity()).toList();
      return Right(tasks);
    } catch (e) {
      return Left(DatabaseFailure('Failed to load tasks: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addTask(TodoTask task) async {
    try {
      final model = TodoTaskModel.fromEntity(task);
      await dataSource.insertTask(model.toMap());
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to add task: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(int id) async {
    try {
      await dataSource.deleteTask(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete task: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTask(TodoTask task) async {
    try {
      if (task.id == null) {
        return Left(DatabaseFailure('Task ID cannot be null'));
      }
      final model = TodoTaskModel.fromEntity(task);
      await dataSource.updateTask(task.id!, model.toMap());
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update task: $e'));
    }
  }
}
