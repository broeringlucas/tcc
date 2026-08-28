import 'package:common/main.dart';
import 'package:dependencies/dartz.dart';

import '../../../main.dart';

class GetTasks implements UseCaseNoParams<List<TodoTask>> {
  final TodoTaskRepository repository;

  GetTasks(this.repository);

  @override
  Future<Either<Failure, List<TodoTask>>> call() async {
    return await repository.getTasks();
  }
}