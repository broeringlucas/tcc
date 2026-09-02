import 'package:dependencies/equatable.dart';

import '../../../main.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object> get props => [];
}

class LoadTasksWithFilter extends TaskEvent {
  final TodoTaskFilter filter;
  final int count;
  final String searchQuery;

  const LoadTasksWithFilter({this.filter = TodoTaskFilter.all, this.count = 0, this.searchQuery = ''});

  @override
  List<Object> get props => [filter, count, searchQuery];
}

class ChangeFilterEvent extends TaskEvent {
  final TodoTaskFilter filter;
  const ChangeFilterEvent(this.filter);
  @override
  List<Object> get props => [filter];
}

class SearchTasksEvent extends TaskEvent {
  final String query;
  const SearchTasksEvent(this.query);
  @override
  List<Object> get props => [query];
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

class ToggleTaskEvent extends TaskEvent {
  final TodoTask task;
  const ToggleTaskEvent(this.task);
  @override
  List<Object> get props => [task];
}

class UpdateTaskEvent extends TaskEvent {
  final TodoTask task;
  const UpdateTaskEvent(this.task);
  @override
  List<Object> get props => [task];
}
