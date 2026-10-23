import 'package:task/main.dart';

List<TodoTask> buildSampleTasks() {
  return [
    TodoTask(id: 1, title: 'Task 1', description: 'Description 1', createdAt: DateTime(2026, 1, 1)),
    TodoTask(id: 2, title: 'Task 2', description: 'Description 2', completed: true, createdAt: DateTime(2026, 1, 2)),
    TodoTask(id: 3, title: 'Task 3', description: 'Description 3', createdAt: DateTime(2026, 1, 3)),
  ];
}

Future<void> flushMicrotasks() => Future<void>.delayed(Duration.zero);
