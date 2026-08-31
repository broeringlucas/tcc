import 'package:dependencies/flutter_modular.dart';
import 'package:home/main.dart';

class AppModule extends Module {
  @override
  final List<Module> imports = [];

  @override
  void binds(i) {}

  @override
  void routes(r) {
    r.module('/', module: HomeModule());
  }
}
