import 'package:common/main.dart';
import 'package:dependencies/flutter_modular.dart';
import 'package:flutter/material.dart';

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
    i.add<SeedTasks>(SeedTasks.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (_) => const Center(
      child: Text('Home Module loaded successfully!'),
    ));

    r.child('/add', child: (_) => const Center(
      child: Text('Add Task Screen - under construction'),
    ));
  }
}