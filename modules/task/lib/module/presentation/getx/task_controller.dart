import 'package:common/main.dart';
import 'package:dependencies/get.dart';

import '../../../main.dart';

class TaskController extends GetxController {
  final GetTasks _getTasks;
  final AddTask _addTask;
  final DeleteTask _deleteTask;
  final UpdateTask _updateTask;

  TaskController({
    required this._getTasks,
    required this._addTask,
    required this._deleteTask,
    required this._updateTask,
  });

  final RxList<TodoTask> _filteredTasks = <TodoTask>[].obs;
  final RxBool _isLoading = true.obs;
  final RxnString _error = RxnString();
  final Rx<TodoTaskFilter> _currentFilter = TodoTaskFilter.all.obs;
  final RxBool _isDarkMode = false.obs;

  List<TodoTask> _allTasks = [];
  String _searchQuery = '';

  List<TodoTask> get tasks => _filteredTasks;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  TodoTaskFilter get currentFilter => _currentFilter.value;
  bool get isDarkMode => _isDarkMode.value;

  void loadTasksWithFilter(TodoTaskFilter filter, int count) {
    _currentFilter.value = filter;
    _isLoading.value = true;
    _error.value = null;

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
            _error.value = failure.message;
            _isLoading.value = false;
          },
          (tasks) {
            _allTasks = tasks;
            _applyFilters();
            _isLoading.value = false;
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
            _error.value = failure.message;
            _isLoading.value = false;
          },
          (tasks) {
            _allTasks = tasks;
            _applyFilters();
            _isLoading.value = false;
          },
        );
      });
    }
  }

  void changeFilter(TodoTaskFilter filter) {
    _currentFilter.value = filter;
    _applyFilters();
  }

  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
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
  }

  void _applyFilters() {
    _filteredTasks.value = TaskFilterUtils.applyFilters(_allTasks, _currentFilter.value, _searchQuery);
  }

  Future<void> addTask(TodoTask task) async {
    final result = await _addTask(AddTaskParams(task));
    result.fold(
      (failure) {
        _error.value = failure.message;
      },
      (_) {
        loadTasksWithFilter(_currentFilter.value, 0);
      },
    );
  }

  Future<void> updateTask(TodoTask task) async {
    final result = await _updateTask(UpdateTaskParams(task));
    result.fold(
      (failure) {
        _error.value = failure.message;
      },
      (_) {
        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = task;
          _applyFilters();
        }
      },
    );
  }

  Future<void> deleteTask(int id) async {
    final result = await _deleteTask(DeleteTaskParams(id));
    result.fold(
      (failure) {
        _error.value = failure.message;
      },
      (_) {
        _allTasks = _allTasks.where((task) => task.id != id).toList();
        _applyFilters();
      },
    );
  }

  Future<void> toggleTask(TodoTask task) async {
    final updatedTask = task.copyWith(completed: !task.completed, updatedAt: DateTime.now());
    final result = await _updateTask(UpdateTaskParams(updatedTask));
    result.fold(
      (failure) {
        _error.value = failure.message;
      },
      (_) {
        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = updatedTask;
          _applyFilters();
        }
      },
    );
  }

  void clearError() {
    _error.value = null;
  }
}
