import 'package:dependencies/flutter_modular.dart';
import 'package:dependencies/get.dart';

import '../../../main.dart';

class TaskBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<TaskController>(
      TaskController(
        getTasks: Modular.get<GetTasks>(),
        addTask: Modular.get<AddTask>(),
        deleteTask: Modular.get<DeleteTask>(),
        updateTask: Modular.get<UpdateTask>(),
      ),
    );
  }
}
