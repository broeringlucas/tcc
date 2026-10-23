import '../../../main.dart';

abstract class TaskState {}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TodoTask> tasks;
  final TodoTaskFilter currentFilter;
  final String searchQuery;

  TaskLoaded(this.tasks, {this.currentFilter = TodoTaskFilter.all, this.searchQuery = ''});
}

class TaskError extends TaskState {
  final String message;
  TaskError(this.message);
}
