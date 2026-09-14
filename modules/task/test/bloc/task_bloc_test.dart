import 'package:bloc_test/bloc_test.dart';
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
  late TaskBloc bloc;
  late List<TodoTask> tasks;

  setUpAll(registerTaskFallbackValues);

  setUp(() {
    mockGetTasks = MockGetTasks();
    mockAddTask = MockAddTask();
    mockDeleteTask = MockDeleteTask();
    mockUpdateTask = MockUpdateTask();
    tasks = buildSampleTasks();
    bloc = TaskBloc(
      getTasks: mockGetTasks,
      addTask: mockAddTask,
      deleteTask: mockDeleteTask,
      updateTask: mockUpdateTask,
    );
  });

  tearDown(() => bloc.close());

  blocTest<TaskBloc, TaskState>(
    'carrega tarefas com sucesso',
    build: () {
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
      return bloc;
    },
    act: (bloc) => bloc.loadTasksWithFilter(TodoTaskFilter.all, 0),
    expect: () => [
      isA<TaskLoading>(),
      isA<TaskLoaded>().having((s) => s.tasks, 'tasks', tasks),
    ],
  );

  blocTest<TaskBloc, TaskState>(
    'define erro quando o carregamento falha',
    build: () {
      when(() => mockGetTasks(any())).thenAnswer((_) async => const Left(DatabaseFailure('falha no banco')));
      return bloc;
    },
    act: (bloc) => bloc.loadTasksWithFilter(TodoTaskFilter.all, 0),
    expect: () => [
      isA<TaskLoading>(),
      isA<TaskError>().having((s) => s.message, 'message', 'falha no banco'),
    ],
  );

  blocTest<TaskBloc, TaskState>(
    'filtra em memória ao buscar',
    build: () {
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
      return bloc;
    },
    act: (bloc) async {
      bloc.loadTasksWithFilter(TodoTaskFilter.all, 0);
      await flushMicrotasks();
      bloc.searchTasks('Task 2');
    },
    expect: () => [
      isA<TaskLoading>(),
      isA<TaskLoaded>().having((s) => s.tasks.length, 'tasks', 3),
      isA<TaskLoaded>().having((s) => s.tasks.map((t) => t.id).toList(), 'ids', [2]),
    ],
  );

  blocTest<TaskBloc, TaskState>(
    'adiciona uma tarefa e recarrega a lista',
    build: () {
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
      when(() => mockAddTask(any())).thenAnswer((_) async => const Right(null));
      return bloc;
    },
    act: (bloc) => bloc.addTask(TodoTask(title: 'Nova', createdAt: DateTime(2026, 1, 4))),
    expect: () => [
      isA<TaskLoading>(),
      isA<TaskLoaded>().having((s) => s.tasks, 'tasks', tasks),
    ],
    verify: (_) {
      verify(() => mockAddTask(any())).called(1);
    },
  );

  blocTest<TaskBloc, TaskState>(
    'edita uma tarefa existente',
    build: () {
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
      when(() => mockUpdateTask(any())).thenAnswer((_) async => const Right(null));
      return bloc;
    },
    act: (bloc) async {
      bloc.loadTasksWithFilter(TodoTaskFilter.all, 0);
      await flushMicrotasks();
      bloc.updateTask(tasks[0].copyWith(title: 'Editada'));
    },
    expect: () => [
      isA<TaskLoading>(),
      isA<TaskLoaded>(),
      isA<TaskLoaded>().having((s) => s.tasks.firstWhere((t) => t.id == 1).title, 'title', 'Editada'),
    ],
  );

  blocTest<TaskBloc, TaskState>(
    'remove uma tarefa',
    build: () {
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
      when(() => mockDeleteTask(any())).thenAnswer((_) async => const Right(null));
      return bloc;
    },
    act: (bloc) async {
      bloc.loadTasksWithFilter(TodoTaskFilter.all, 0);
      await flushMicrotasks();
      bloc.add(const DeleteTaskEvent(2));
    },
    expect: () => [
      isA<TaskLoading>(),
      isA<TaskLoaded>(),
      isA<TaskLoaded>().having((s) => s.tasks.map((t) => t.id).toList(), 'ids', [1, 3]),
    ],
  );

  blocTest<TaskBloc, TaskState>(
    'alterna a conclusão de uma tarefa',
    build: () {
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
      when(() => mockUpdateTask(any())).thenAnswer((_) async => const Right(null));
      return bloc;
    },
    act: (bloc) async {
      bloc.loadTasksWithFilter(TodoTaskFilter.all, 0);
      await flushMicrotasks();
      bloc.add(ToggleTaskEvent(tasks[0]));
    },
    expect: () => [
      isA<TaskLoading>(),
      isA<TaskLoaded>(),
      isA<TaskLoaded>().having((s) => s.tasks.firstWhere((t) => t.id == 1).completed, 'completed', isTrue),
    ],
  );

  blocTest<TaskBloc, TaskState>(
    'troca o filtro em memória',
    build: () {
      when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
      return bloc;
    },
    act: (bloc) async {
      bloc.loadTasksWithFilter(TodoTaskFilter.all, 0);
      await flushMicrotasks();
      bloc.changeFilter(TodoTaskFilter.completed);
    },
    expect: () => [
      isA<TaskLoading>(),
      isA<TaskLoaded>(),
      isA<TaskLoaded>().having((s) => s.tasks.map((t) => t.id).toList(), 'ids', [2]),
    ],
  );

  test('alterna o tema', () async {
    when(() => mockGetTasks(any())).thenAnswer((_) async => Right(tasks));
    bloc.loadTasksWithFilter(TodoTaskFilter.all, 0);
    await flushMicrotasks();

    expect(bloc.isDarkMode, isFalse);
    bloc.toggleTheme();
    await flushMicrotasks();
    expect(bloc.isDarkMode, isTrue);
  });
}
