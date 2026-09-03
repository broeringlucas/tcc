import 'package:common/main.dart';
import 'package:dependencies/flutter_modular.dart';
import 'package:dependencies/flutter_riverpod.dart';
import 'package:dependencies/provider.dart' as provider_pkg;

import '../main.dart';

class TaskModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<AppDatabase>(AppDatabase.new);
    i.add<TodoTaskLocalDataSource>(TodoTaskLocalDataSource.new);
    i.add<TodoTaskRepository>(TodoTaskRepositoryImpl.new);

    i.add<GetTasks>(GetTasks.new);
    i.add<AddTask>(AddTask.new);
    i.add<DeleteTask>(DeleteTask.new);
    i.add<UpdateTask>(UpdateTask.new);

    i.addSingleton<TaskBloc>(
      () => TaskBloc(
        getTasks: Modular.get<GetTasks>(),
        addTask: Modular.get<AddTask>(),
        deleteTask: Modular.get<DeleteTask>(),
        updateTask: Modular.get<UpdateTask>(),
      ),
    );

    i.add<ProviderTaskNotifier>(
      () => ProviderTaskNotifier(
        getTasks: Modular.get<GetTasks>(),
        addTask: Modular.get<AddTask>(),
        deleteTask: Modular.get<DeleteTask>(),
        updateTask: Modular.get<UpdateTask>(),
      ),
    );
  }

  @override
  void routes(r) {
    r.child('/bloc', child: (_) => const BlocHomeView());

    r.child(
      '/provider',
      child: (_) {
        return provider_pkg.ChangeNotifierProvider(
          create: (context) => ProviderTaskNotifier(
            getTasks: Modular.get<GetTasks>(),
            addTask: Modular.get<AddTask>(),
            deleteTask: Modular.get<DeleteTask>(),
            updateTask: Modular.get<UpdateTask>(),
          ),
          child: const ProviderHomeView(),
        );
      },
    );

    r.child(
      '/riverpod',
      child: (_) {
        return ProviderScope(
          overrides: [
            getTasksProvider.overrideWith((ref) => Modular.get<GetTasks>()),
            addTaskProvider.overrideWith((ref) => Modular.get<AddTask>()),
            deleteTaskProvider.overrideWith((ref) => Modular.get<DeleteTask>()),
            updateTaskProvider.overrideWith((ref) => Modular.get<UpdateTask>()),
          ],
          child: const RiverpodHomeView(),
        );
      },
    );

    r.child('/add', child: (_) => const AddTaskView());
    r.child(
      '/edit',
      child: (context) {
        final task = Modular.args.data as TodoTask;
        return EditTaskView(task: task);
      },
    );
  }
}
