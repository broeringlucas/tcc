import 'package:common/main.dart';
import 'package:dependencies/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task/main.dart';

import '../helpers/mock_usecases.dart';
import '../helpers/task_fixtures.dart';

void main() {
  late MockGetTasks mockGetTasks;
  late MockAddTask mockAddTask;
  late MockDeleteTask mockDeleteTask;
  late MockUpdateTask mockUpdateTask;
  late TaskController controller;
  late List<TodoTask> tasks;

  setUpAll(registerTaskFallbackValues);

  setUp(() {
    mockGetTasks = MockGetTasks();
    mockAddTask = MockAddTask();
    mockDeleteTask = MockDeleteTask();
    mockUpdateTask = MockUpdateTask();
    tasks = buildSampleTasks();
    controller = TaskController(
      getTasks: mockGetTasks,
      addTask: mockAddTask,
      deleteTask: mockDeleteTask,
      updateTask: mockUpdateTask,
    );
  });

  test('carrega tarefas com sucesso', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));

    controller.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    expect(controller.tasks, tasks);
    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
  });

  test('define erro quando o carregamento falha', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => const Left(DatabaseFailure('falha no banco')));

    controller.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    expect(controller.error, 'falha no banco');
    expect(controller.isLoading, isFalse);
  });

  test('filtra em memória ao buscar', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    controller.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    controller.searchTasks('Task 2');

    expect(controller.tasks.map((t) => t.id).toList(), [2]);
  });

  test('adiciona uma tarefa e recarrega a lista', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    when(() => mockAddTask(any())).thenAnswer((_) async => const Right(null));

    await controller.addTask(TodoTask(title: 'Nova', createdAt: DateTime(2026, 1, 4)));
    await flushMicrotasks();

    verify(() => mockAddTask(any())).called(1);
    expect(controller.tasks, tasks);
  });

  test('edita uma tarefa existente', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    when(() => mockUpdateTask(any())).thenAnswer((_) async => const Right(null));
    controller.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    await controller.updateTask(tasks[0].copyWith(title: 'Editada'));

    expect(controller.tasks.firstWhere((t) => t.id == 1).title, 'Editada');
  });

  test('remove uma tarefa', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    when(() => mockDeleteTask(any())).thenAnswer((_) async => const Right(null));
    controller.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    await controller.deleteTask(2);

    expect(controller.tasks.map((t) => t.id).toList(), [1, 3]);
  });

  test('alterna a conclusão de uma tarefa', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    when(() => mockUpdateTask(any())).thenAnswer((_) async => const Right(null));
    controller.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    await controller.toggleTask(tasks[0]);

    expect(controller.tasks.firstWhere((t) => t.id == 1).completed, isTrue);
  });

  test('troca o filtro em memória', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    controller.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    controller.changeFilter(TodoTaskFilter.completed);

    expect(controller.tasks.map((t) => t.id).toList(), [2]);
  });

  test('alterna o tema', () {
    expect(controller.isDarkMode, isFalse);
    controller.toggleTheme();
    expect(controller.isDarkMode, isTrue);
  });
}
