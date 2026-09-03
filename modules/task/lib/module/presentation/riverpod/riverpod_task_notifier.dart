import 'package:common/main.dart';
import 'package:dependencies/flutter_riverpod.dart';

import '../../../main.dart';

class RiverpodTaskNotifier extends StateNotifier<AsyncValue<List<TodoTask>>> {
  final GetTasks _getTasks;
  final AddTask _addTask;
  final DeleteTask _deleteTask;
  final UpdateTask _updateTask;

  List<TodoTask> _allTasks = [];
  TodoTaskFilter _currentFilter = TodoTaskFilter.all;
  String _searchQuery = '';

  RiverpodTaskNotifier({
    required this._getTasks,
    required this._addTask,
    required this._deleteTask,
    required this._updateTask,
  }) : super(const AsyncValue.loading());

  List<TodoTask> get tasks => state.value ?? [];
  bool get isLoading => state.isLoading;
  String? get error => state.error?.toString();
  TodoTaskFilter get currentFilter => _currentFilter;

  void loadTasksWithFilter(TodoTaskFilter filter, int count) {
    _currentFilter = filter;

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
            state = AsyncValue.data(_filteredTasks());
          },
        );

        processStopwatch.stop();
        tracker.recordOperationMicros('PROCESS_${filter.name}_$count', processStopwatch.elapsedMicroseconds);

        final memAfter = tracker.getCurrentMemoryMB();
        tracker.recordMemory('AFTER_${filter.name}_$count', memAfter);

        tracker.printSummary();
      });
    } else {
      state = const AsyncValue.loading();
      _getTasks(GetTasksParams(0)).then((result) {
        result.fold(
          (failure) {
            state = AsyncValue.error(failure.message, StackTrace.current);
          },
          (tasks) {
            _allTasks = tasks;
            _applyFilters();
            state = AsyncValue.data(_filteredTasks());
          },
        );
      });
    }
  }

  void changeFilter(TodoTaskFilter filter) {
    _currentFilter = filter;
    _applyFilters();
    state = AsyncValue.data(_filteredTasks());
  }

  void searchTasks(String query) {
    final tracker = PerformanceTracker();

    _searchQuery = query;

    final memBefore = tracker.getCurrentMemoryMB();

    final stopwatch = Stopwatch()..start();
    _applyFilters();
    final filtered = _filteredTasks();
    stopwatch.stop();

    tracker.recordOperationMicros('search_${query.isEmpty ? "empty" : query}_tasks', stopwatch.elapsedMicroseconds);

    final memAfter = tracker.getCurrentMemoryMB();

    // Valores absolutos
    tracker.recordMemory('SEARCH_BEFORE_${query.isEmpty ? "empty" : query}', memBefore);
    tracker.recordMemory('SEARCH_AFTER_${query.isEmpty ? "empty" : query}', memAfter);

    state = AsyncValue.data(filtered);

    tracker.printSummary();
  }

  void _applyFilters() {}

  List<TodoTask> _filteredTasks() {
    return TaskFilterUtils.applyFilters(_allTasks, _currentFilter, _searchQuery);
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
          state = AsyncValue.data(_filteredTasks());
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
        state = AsyncValue.data(_filteredTasks());
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
          state = AsyncValue.data(_filteredTasks());
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
