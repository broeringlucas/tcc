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

final riverpodTaskNotifierProvider = NotifierProvider<RiverpodTaskNotifier, AsyncValue<List<TodoTask>>>(
  RiverpodTaskNotifier.new,
);
