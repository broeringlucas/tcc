import 'package:common/core/error/failures.dart';
import 'package:dependencies/dartz.dart';
import 'package:common/main.dart';

import '../../../main.dart';

abstract class TodoTaskRepository {
  Future<Either<Failure, List<TodoTask>>> getTasks();
  Future<Either<Failure, void>> addTask(TodoTask task);
  Future<Either<Failure, void>> deleteTask(int id);
  Future<Either<Failure, void>> updateTask(TodoTask task);
  Future<Either<Failure, void>> seedTasks(int count);
}