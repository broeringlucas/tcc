import 'package:common/main.dart';
import 'package:dependencies/bloc.dart';

import '../../../main.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasks _getTasks;
  final AddTask _addTask;
  final DeleteTask _deleteTask;
  final UpdateTask _updateTask;

  TodoTaskFilter _currentFilter = TodoTaskFilter.all;
  String _searchQuery = '';
  List<TodoTask> _allTasks = [];

  TaskBloc({required this._getTasks, required this._addTask, required this._deleteTask, required this._updateTask})
    : super(TaskInitial()) {
    on<LoadTasksWithFilter>(_onLoadTasksWithFilter);
    on<ChangeFilterEvent>(_onChangeFilter);
    on<SearchTasksEvent>(_onSearchTasks);
    on<AddTaskEvent>(_onAddTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<ToggleTaskEvent>(_onToggleTask);
    on<UpdateTaskEvent>(_onUpdateTask);
  }

  TodoTaskFilter get currentFilter => _currentFilter;

  void loadTasksWithFilter(TodoTaskFilter filter, int count) {
    add(LoadTasksWithFilter(filter: filter, count: count));
  }

  void changeFilter(TodoTaskFilter filter) {
    add(ChangeFilterEvent(filter));
  }

  void searchTasks(String query) {
    add(SearchTasksEvent(query));
  }

  void addTask(TodoTask task) {
    add(AddTaskEvent(task));
  }

  void updateTask(TodoTask task) {
    add(UpdateTaskEvent(task));
  }

  Future<void> _onLoadTasksWithFilter(LoadTasksWithFilter event, Emitter<TaskState> emit) async {
    _currentFilter = event.filter;
    _searchQuery = event.searchQuery;
    emit(TaskLoading());

    if (event.count > 0) {
      final tracker = PerformanceTracker();

      final memBefore = tracker.getCurrentMemoryMB();
      tracker.recordMemory('BEFORE_${event.filter.name}_${event.count}', memBefore);

      final dbStopwatch = Stopwatch()..start();
      final dbResult = await _getTasks(GetTasksParams(event.count));
      dbStopwatch.stop();
      tracker.recordOperationMicros('DB_${event.filter.name}_${event.count}', dbStopwatch.elapsedMicroseconds);

      final blocStopwatch = Stopwatch()..start();

      dbResult.fold(
        (failure) {
          emit(TaskError(failure.message));
        },
        (tasks) {
          _allTasks = tasks;
          final filteredTasks = TaskFilterUtils.applyFilters(tasks, event.filter, event.searchQuery);
          emit(TaskLoaded(filteredTasks, currentFilter: event.filter, searchQuery: event.searchQuery));
        },
      );
      blocStopwatch.stop();

      tracker.recordOperationMicros('PROCESS_${event.filter.name}_${event.count}', blocStopwatch.elapsedMicroseconds);

      final memAfter = tracker.getCurrentMemoryMB();
      tracker.recordMemory('AFTER_${event.filter.name}_${event.count}', memAfter);
    } else {
      final dbResult = await _getTasks(GetTasksParams(0));

      dbResult.fold(
        (failure) {
          emit(TaskError(failure.message));
        },
        (tasks) {
          _allTasks = tasks;
          final filteredTasks = TaskFilterUtils.applyFilters(tasks, event.filter, event.searchQuery);
          emit(TaskLoaded(filteredTasks, currentFilter: event.filter, searchQuery: event.searchQuery));
        },
      );
    }
  }

  Future<void> _onChangeFilter(ChangeFilterEvent event, Emitter<TaskState> emit) async {
    _currentFilter = event.filter;
    final filteredTasks = TaskFilterUtils.applyFilters(_allTasks, _currentFilter, _searchQuery);
    emit(TaskLoaded(filteredTasks, currentFilter: _currentFilter, searchQuery: _searchQuery));
  }

  Future<void> _onSearchTasks(SearchTasksEvent event, Emitter<TaskState> emit) async {
    final tracker = PerformanceTracker();

    _searchQuery = event.query;

    final memBefore = tracker.getCurrentMemoryMB();

    final stopwatch = Stopwatch()..start();
    final result = TaskFilterUtils.applyFilters(_allTasks, _currentFilter, event.query);
    stopwatch.stop();

    tracker.recordOperationMicros(
      'SEARCH_${event.query.isEmpty ? "empty" : event.query}_tasks',
      stopwatch.elapsedMicroseconds,
    );

    final memAfter = tracker.getCurrentMemoryMB();
    tracker.recordMemory('SEARCH_BEFORE_${event.query.isEmpty ? "empty" : event.query}', memBefore);
    tracker.recordMemory('SEARCH_AFTER_${event.query.isEmpty ? "empty" : event.query}', memAfter);

    emit(TaskLoaded(result, currentFilter: _currentFilter, searchQuery: event.query));
  }

  Future<void> _onAddTask(AddTaskEvent event, Emitter<TaskState> emit) async {
    await _addTask(AddTaskParams(event.task));
    add(LoadTasksWithFilter(filter: _currentFilter, count: 0, searchQuery: _searchQuery));
  }

  Future<void> _onDeleteTask(DeleteTaskEvent event, Emitter<TaskState> emit) async {
    await _deleteTask(DeleteTaskParams(event.id));

    final currentState = state;
    if (currentState is TaskLoaded) {
      final updatedTasks = currentState.tasks.where((task) => task.id != event.id).toList();
      emit(TaskLoaded(updatedTasks, currentFilter: _currentFilter, searchQuery: _searchQuery));
    }
  }

  Future<void> _onToggleTask(ToggleTaskEvent event, Emitter<TaskState> emit) async {
    final updatedTask = event.task.copyWith(completed: !event.task.completed, updatedAt: DateTime.now());
    add(UpdateTaskEvent(updatedTask));
  }

  Future<void> _onUpdateTask(UpdateTaskEvent event, Emitter<TaskState> emit) async {
    final updatedTask = event.task.copyWith(updatedAt: DateTime.now());
    final result = await _updateTask(UpdateTaskParams(updatedTask));

    result.fold((failure) => emit(TaskError(failure.message)), (_) {
      final currentState = state;
      if (currentState is TaskLoaded) {
        final updatedTasks = currentState.tasks.map((task) {
          if (task.id == updatedTask.id) {
            return updatedTask;
          }
          return task;
        }).toList();

        final finalResult = TaskFilterUtils.applyFilters(updatedTasks, _currentFilter, _searchQuery);

        emit(TaskLoaded(finalResult, currentFilter: _currentFilter, searchQuery: _searchQuery));
      }
    });
  }
}
