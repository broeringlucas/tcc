import 'package:common/main.dart';
import 'package:dependencies/dartz.dart';
import 'package:dependencies/equatable.dart';

import '../../../main.dart';

class AddTask implements UseCase<void, AddTaskParams> {
  final TodoTaskRepository repository;

  AddTask(this.repository);

  @override
  Future<Either<Failure, void>> call(AddTaskParams params) async {
    return await repository.addTask(params.task);
  }
}

class AddTaskParams extends Equatable {
  final TodoTask task;
  const AddTaskParams(this.task);
  @override
  List<Object> get props => [task];
}
