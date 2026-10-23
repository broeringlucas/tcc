import 'package:common/main.dart';
import 'package:dependencies/dartz.dart';
import 'package:dependencies/equatable.dart';

import '../../../main.dart';

class UpdateTaskParams extends Equatable {
  final TodoTask task;
  const UpdateTaskParams(this.task);
  @override
  List<Object> get props => [task];
}

class UpdateTask implements UseCase<void, UpdateTaskParams> {
  final TodoTaskRepository _repository;

  UpdateTask(this._repository);

  @override
  Future<Either<Failure, void>> call(UpdateTaskParams params) {
    return _repository.updateTask(params.task);
  }
}
