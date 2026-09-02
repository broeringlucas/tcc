import 'package:common/main.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';

class TaskNotifier extends ChangeNotifier {
  final GetTasks _getTasks;
  final AddTask _addTask;
  final DeleteTask _deleteTask;
  final UpdateTask _updateTask;

  List<TodoTask> _allTasks = [];
  List<TodoTask> _filteredTasks = [];
  TodoTaskFilter _currentFilter = TodoTaskFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  List<TodoTask> get tasks => _filteredTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TodoTaskFilter get currentFilter => _currentFilter;

  TaskNotifier({
    required GetTasks getTasks,
    required AddTask addTask,
    required DeleteTask deleteTask,
    required UpdateTask updateTask,
  }) : _getTasks = getTasks,
       _addTask = addTask,
       _deleteTask = deleteTask,
       _updateTask = updateTask;

  void loadTasksWithFilter(TodoTaskFilter filter, int count) {
    _currentFilter = filter;
    _isLoading = true;
    _error = null;
    notifyListeners();

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
            _error = failure.message;
            _isLoading = false;
            notifyListeners();
          },
          (tasks) {
            _allTasks = tasks;
            _applyFilters();
            _isLoading = false;
            notifyListeners();
          },
        );

        processStopwatch.stop();
        tracker.recordOperationMicros('PROCESS_${filter.name}_${count}', processStopwatch.elapsedMicroseconds);

        final memAfter = tracker.getCurrentMemoryMB();
        tracker.recordMemory('AFTER_${filter.name}_$count', memAfter);

        tracker.printSummary();
      });
    } else {
      _getTasks(GetTasksParams(0)).then((result) {
        result.fold(
          (failure) {
            _error = failure.message;
            _isLoading = false;
            notifyListeners();
          },
          (tasks) {
            _allTasks = tasks;
            _applyFilters();
            _isLoading = false;
            notifyListeners();
          },
        );
      });
    }
  }

  void changeFilter(TodoTaskFilter filter) {
    _currentFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void searchTasks(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredTasks = TaskFilterUtils.applyFilters(_allTasks, _currentFilter, _searchQuery);
  }

  Future<void> addTask(TodoTask task) async {
    final result = await _addTask(AddTaskParams(task));
    result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
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
        _error = failure.message;
        notifyListeners();
      },
      (_) {
        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = task;
          _applyFilters();
          notifyListeners();
        }
      },
    );
  }

  Future<void> deleteTask(int id) async {
    final result = await _deleteTask(DeleteTaskParams(id));
    result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
      },
      (_) {
        _allTasks = _allTasks.where((task) => task.id != id).toList();
        _applyFilters();
        notifyListeners();
      },
    );
  }

  Future<void> toggleTask(TodoTask task) async {
    final updatedTask = task.copyWith(completed: !task.completed, updatedAt: DateTime.now());
    final result = await _updateTask(UpdateTaskParams(updatedTask));
    result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
      },
      (_) {
        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = updatedTask;
          _applyFilters();
          notifyListeners();
        }
      },
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
