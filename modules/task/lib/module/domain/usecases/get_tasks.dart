import 'package:common/main.dart';
import 'package:dependencies/dartz.dart';
import 'package:dependencies/equatable.dart';

import '../../../main.dart';

class GetTasks implements UseCase<List<TodoTask>, GetTasksParams> {
  final TodoTaskRepository repository;

  GetTasks(this.repository);

  @override
  Future<Either<Failure, List<TodoTask>>> call(GetTasksParams params) async {
    return await repository.getTasks(limit: params.limit);
  }
}

class GetTasksParams extends Equatable {
  final int limit;
  const GetTasksParams(this.limit);

  @override
  List<Object> get props => [limit];
}
