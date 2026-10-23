import 'package:mocktail/mocktail.dart';
import 'package:task/main.dart';

class MockGetTasks extends Mock implements GetTasks {}

class MockAddTask extends Mock implements AddTask {}

class MockDeleteTask extends Mock implements DeleteTask {}

class MockUpdateTask extends Mock implements UpdateTask {}

class FakeGetTasksParams extends Fake implements GetTasksParams {}

class FakeAddTaskParams extends Fake implements AddTaskParams {}

class FakeDeleteTaskParams extends Fake implements DeleteTaskParams {}

class FakeUpdateTaskParams extends Fake implements UpdateTaskParams {}

void registerTaskFallbackValues() {
  registerFallbackValue(FakeGetTasksParams());
  registerFallbackValue(FakeAddTaskParams());
  registerFallbackValue(FakeDeleteTaskParams());
  registerFallbackValue(FakeUpdateTaskParams());
}
