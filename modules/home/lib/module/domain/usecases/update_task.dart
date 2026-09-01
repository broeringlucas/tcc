import 'package:common/main.dart';
import 'package:dependencies/dartz.dart';

import '../../../main.dart';

class UpdateTaskParams {
  final TodoTask task;
  UpdateTaskParams(this.task);
}

class UpdateTask implements UseCase<void, UpdateTaskParams> {
  final TodoTaskRepository _repository;

  UpdateTask(this._repository);

  @override
  Future<Either<Failure, void>> call(UpdateTaskParams params) {
    return _repository.updateTask(params.task);
  }
}
