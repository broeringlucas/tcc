import 'package:common/main.dart';
import 'package:dependencies/dartz.dart';
import 'package:dependencies/equatable.dart';

import '../../../main.dart';

class DeleteTask implements UseCase<void, DeleteTaskParams> {
  final TodoTaskRepository repository;

  DeleteTask(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteTaskParams params) async {
    return await repository.deleteTask(params.id);
  }
}

class DeleteTaskParams extends Equatable {
  final int id;
  const DeleteTaskParams(this.id);
  @override
  List<Object> get props => [id];
}