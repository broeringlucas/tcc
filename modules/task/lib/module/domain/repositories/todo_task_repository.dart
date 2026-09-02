import 'package:common/core/error/failures.dart';
import 'package:common/main.dart';
import 'package:dependencies/dartz.dart';

import '../../../main.dart';

abstract class TodoTaskRepository {
  Future<Either<Failure, List<TodoTask>>> getTasks({int limit = 0});
  Future<Either<Failure, void>> addTask(TodoTask task);
  Future<Either<Failure, void>> deleteTask(int id);
  Future<Either<Failure, void>> updateTask(TodoTask task);
}
