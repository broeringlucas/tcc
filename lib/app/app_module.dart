import 'package:dependencies/flutter_modular.dart';
import 'package:home/module/home_module.dart';
import 'package:task/module/task_module.dart';

class AppModule extends Module {
  @override
  final List<Module> imports = [];

  @override
  void binds(i) {}

  @override
  void routes(r) {
    r.module('/', module: HomeModule());
    r.module('/task', module: TaskModule());
  }
}
