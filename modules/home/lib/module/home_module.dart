import 'package:dependencies/flutter_modular.dart';

import '../../main.dart';

class HomeModule extends Module {
  @override
  void binds(i) {}

  @override
  void routes(r) {
    r.child('/', child: (_) => const HomeView());
  }
}
