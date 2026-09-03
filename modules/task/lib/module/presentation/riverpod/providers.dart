import 'package:dependencies/flutter_riverpod.dart';

import '../../../main.dart';

final getTasksProvider = Provider<GetTasks>((ref) {
  throw UnimplementedError('Must be overridden');
});

final addTaskProvider = Provider<AddTask>((ref) {
  throw UnimplementedError('Must be overridden');
});

final deleteTaskProvider = Provider<DeleteTask>((ref) {
  throw UnimplementedError('Must be overridden');
});

final updateTaskProvider = Provider<UpdateTask>((ref) {
  throw UnimplementedError('Must be overridden');
});

final riverpodTaskNotifierProvider = StateNotifierProvider<RiverpodTaskNotifier, AsyncValue<List<TodoTask>>>((ref) {
  final getTasks = ref.watch(getTasksProvider);
  final addTask = ref.watch(addTaskProvider);
  final deleteTask = ref.watch(deleteTaskProvider);
  final updateTask = ref.watch(updateTaskProvider);

  return RiverpodTaskNotifier(getTasks: getTasks, addTask: addTask, deleteTask: deleteTask, updateTask: updateTask);
});
