import 'package:common/main.dart';
import 'package:dependencies/flutter_riverpod.dart';

import '../../../main.dart';

class RiverpodTaskNotifier extends Notifier<AsyncValue<List<TodoTask>>> {
  late final GetTasks _getTasks;
  late final AddTask _addTask;
  late final DeleteTask _deleteTask;
  late final UpdateTask _updateTask;

  List<TodoTask> _allTasks = [];
  List<TodoTask> _filteredTasks = [];
  TodoTaskFilter _currentFilter = TodoTaskFilter.all;
  String _searchQuery = '';

  @override
  AsyncValue<List<TodoTask>> build() {
    _getTasks = ref.read(getTasksProvider);
    _addTask = ref.read(addTaskProvider);
    _deleteTask = ref.read(deleteTaskProvider);
    _updateTask = ref.read(updateTaskProvider);
    return const AsyncValue.loading();
  }

  List<TodoTask> get tasks => _filteredTasks;
  bool get isLoading => state.isLoading;
  String? get error => state.error?.toString();
  TodoTaskFilter get currentFilter => _currentFilter;

  void loadTasksWithFilter(TodoTaskFilter filter, int count) {
    _currentFilter = filter;
    state = const AsyncValue.loading();

    if (count > 0) {
      final tracker = PerformanceTracker();

      final memBefore = tracker.getCurrentMemoryMB();
      tracker.recordMemory('BEFORE_${filter.name}_$count', memBefore);

      final dbStopwatch = Stopwatch()..start();
      _getTasks(GetTasksParams(count)).then((result) {
        dbStopwatch.stop();
        tracker.recordOperationMicros('DB_${filter.name}_$count', dbStopwatch.elapsedMicroseconds);

        final processStopwatch = Stopwatch()..start();

        result.fold(
          (failure) {
            state = AsyncValue.error(failure.message, StackTrace.current);
          },
          (tasks) {
            _allTasks = tasks;
            _applyFilters();
            state = AsyncValue.data(_filteredTasks);
          },
        );

        processStopwatch.stop();
        tracker.recordOperationMicros('PROCESS_${filter.name}_$count', processStopwatch.elapsedMicroseconds);

        final memAfter = tracker.getCurrentMemoryMB();
        tracker.recordMemory('AFTER_${filter.name}_$count', memAfter);
      });
    } else {
      _getTasks(GetTasksParams(0)).then((result) {
        result.fold(
          (failure) {
            state = AsyncValue.error(failure.message, StackTrace.current);
          },
          (tasks) {
            _allTasks = tasks;
            _applyFilters();
            state = AsyncValue.data(_filteredTasks);
          },
        );
      });
    }
  }

  void changeFilter(TodoTaskFilter filter) {
    _currentFilter = filter;
    _applyFilters();
    state = AsyncValue.data(_filteredTasks);
  }

  void searchTasks(String query) {
    final tracker = PerformanceTracker();

    _searchQuery = query;

    final memBefore = tracker.getCurrentMemoryMB();

    final stopwatch = Stopwatch()..start();
    _applyFilters();
    stopwatch.stop();

    tracker.recordOperationMicros('SEARCH_${query.isEmpty ? "empty" : query}_tasks', stopwatch.elapsedMicroseconds);

    final memAfter = tracker.getCurrentMemoryMB();
    tracker.recordMemory('SEARCH_BEFORE_${query.isEmpty ? "empty" : query}', memBefore);
    tracker.recordMemory('SEARCH_AFTER_${query.isEmpty ? "empty" : query}', memAfter);

    state = AsyncValue.data(_filteredTasks);
  }

  void _applyFilters() {
    _filteredTasks = TaskFilterUtils.applyFilters(_allTasks, _currentFilter, _searchQuery);
  }

  Future<void> addTask(TodoTask task) async {
    final result = await _addTask(AddTaskParams(task));
    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (_) {
        loadTasksWithFilter(_currentFilter, 0);
      },
    );
  }

  Future<void> updateTask(TodoTask task) async {
    final result = await _updateTask(UpdateTaskParams(task));
    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (_) {
        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = task;
          _applyFilters();
          state = AsyncValue.data(_filteredTasks);
        }
      },
    );
  }

  Future<void> deleteTask(int id) async {
    final result = await _deleteTask(DeleteTaskParams(id));
    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (_) {
        _allTasks = _allTasks.where((task) => task.id != id).toList();
        _applyFilters();
        state = AsyncValue.data(_filteredTasks);
      },
    );
  }

  Future<void> toggleTask(TodoTask task) async {
    final updatedTask = task.copyWith(completed: !task.completed, updatedAt: DateTime.now());
    final result = await _updateTask(UpdateTaskParams(updatedTask));
    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (_) {
        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = updatedTask;
          _applyFilters();
          state = AsyncValue.data(_filteredTasks);
        }
      },
    );
  }

  void clearError() {
    final currentData = state.value;
    if (currentData != null) {
      state = AsyncValue.data(currentData);
    } else {
      state = const AsyncValue.loading();
    }
  }
}
