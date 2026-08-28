import 'package:common/main.dart';
import 'package:dependencies/dartz.dart';
import 'package:dependencies/equatable.dart';

import '../../../main.dart';

class SeedTasks implements UseCase<void, SeedTasksParams> {
  final TodoTaskRepository repository;

  SeedTasks(this.repository);

  @override
  Future<Either<Failure, void>> call(SeedTasksParams params) async {
    return await repository.seedTasks(params.count);
  }
}

class SeedTasksParams extends Equatable {
  final int count;
  const SeedTasksParams(this.count);
  @override
  List<Object> get props => [count];
}