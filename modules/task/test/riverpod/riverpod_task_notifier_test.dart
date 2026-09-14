import 'package:common/main.dart';
import 'package:dependencies/dartz.dart';
import 'package:dependencies/flutter_riverpod.dart';
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
  late ProviderContainer container;
  late RiverpodTaskNotifier notifier;
  late List<TodoTask> tasks;

  setUpAll(registerTaskFallbackValues);

  setUp(() {
    mockGetTasks = MockGetTasks();
    mockAddTask = MockAddTask();
    mockDeleteTask = MockDeleteTask();
    mockUpdateTask = MockUpdateTask();
    tasks = buildSampleTasks();
    container = ProviderContainer(
      overrides: [
        getTasksProvider.overrideWithValue(mockGetTasks),
        addTaskProvider.overrideWithValue(mockAddTask),
        deleteTaskProvider.overrideWithValue(mockDeleteTask),
        updateTaskProvider.overrideWithValue(mockUpdateTask),
      ],
    );
    notifier = container.read(riverpodTaskNotifierProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('carrega tarefas com sucesso', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));

    notifier.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    final state = container.read(riverpodTaskNotifierProvider);
    expect(state.value, tasks);
    expect(state.isLoading, isFalse);
  });

  test('define erro quando o carregamento falha', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => const Left(DatabaseFailure('falha no banco')));

    notifier.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    final state = container.read(riverpodTaskNotifierProvider);
    expect(state.hasError, isTrue);
    expect(notifier.error, 'falha no banco');
  });

  test('filtra em memória ao buscar', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    notifier.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    notifier.searchTasks('Task 2');

    expect(notifier.tasks.map((t) => t.id).toList(), [2]);
  });

  test('adiciona uma tarefa e recarrega a lista', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    when(() => mockAddTask(any())).thenAnswer((_) async => const Right(null));

    await notifier.addTask(TodoTask(title: 'Nova', createdAt: DateTime(2026, 1, 4)));
    await flushMicrotasks();

    verify(() => mockAddTask(any())).called(1);
    expect(notifier.tasks, tasks);
  });

  test('edita uma tarefa existente', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    when(() => mockUpdateTask(any())).thenAnswer((_) async => const Right(null));
    notifier.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    await notifier.updateTask(tasks[0].copyWith(title: 'Editada'));

    expect(notifier.tasks.firstWhere((t) => t.id == 1).title, 'Editada');
  });

  test('remove uma tarefa', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    when(() => mockDeleteTask(any())).thenAnswer((_) async => const Right(null));
    notifier.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    await notifier.deleteTask(2);

    expect(notifier.tasks.map((t) => t.id).toList(), [1, 3]);
  });

  test('alterna a conclusão de uma tarefa', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    when(() => mockUpdateTask(any())).thenAnswer((_) async => const Right(null));
    notifier.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    await notifier.toggleTask(tasks[0]);

    expect(notifier.tasks.firstWhere((t) => t.id == 1).completed, isTrue);
  });

  test('troca o filtro em memória', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    notifier.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    notifier.changeFilter(TodoTaskFilter.completed);

    expect(notifier.tasks.map((t) => t.id).toList(), [2]);
  });

  test('alterna o tema', () {
    expect(notifier.isDarkMode, isFalse);
    notifier.toggleTheme();
    expect(notifier.isDarkMode, isTrue);
  });
}
