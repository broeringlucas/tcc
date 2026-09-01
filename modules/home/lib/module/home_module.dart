import 'package:common/main.dart';
import 'package:dependencies/flutter_modular.dart';

import '../main.dart';

class HomeModule extends Module {
  @override
  void binds(i) {
    // Database
    i.addSingleton<AppDatabase>(AppDatabase.new);

    // Data Source
    i.add<TodoTaskLocalDataSource>(TodoTaskLocalDataSource.new);

    // Repository
    i.add<TodoTaskRepository>(TodoTaskRepositoryImpl.new);

    // Use Cases
    i.add<GetTasks>(GetTasks.new);
    i.add<AddTask>(AddTask.new);
    i.add<DeleteTask>(DeleteTask.new);
    i.add<UpdateTask>(UpdateTask.new);

    // BLoC
    i.addSingleton<TaskBloc>(
      () => TaskBloc(
        getTasks: Modular.get<GetTasks>(),
        addTask: Modular.get<AddTask>(),
        deleteTask: Modular.get<DeleteTask>(),
        updateTask: Modular.get<UpdateTask>(),
      ),
    );
  }

  @override
  void routes(r) {
    r.child('/', child: (_) => const BlocHomeView());

    r.child('/add', child: (_) => AddTaskView());

    r.child(
      '/edit',
      child: (context) {
        final args = Modular.args.data as TodoTask;
        return EditTaskView(task: args);
      },
    );
  }
}
