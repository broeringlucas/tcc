import 'package:dependencies/equatable.dart';

import '../../../main.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object> get props => [];
}

class LoadTasksWithCount extends TaskEvent {
  final int count;
  const LoadTasksWithCount(this.count);
  @override
  List<Object> get props => [count];
}

class AddTaskEvent extends TaskEvent {
  final TodoTask task;
  const AddTaskEvent(this.task);
  @override
  List<Object> get props => [task];
}

class DeleteTaskEvent extends TaskEvent {
  final int id;
  const DeleteTaskEvent(this.id);
  @override
  List<Object> get props => [id];
}
