import 'package:flutter/material.dart';
import 'package:dependencies/flutter_modular.dart';

class AppModule extends Module {
  @override
  final List<Module> imports = [];

  @override
  void binds(i) {}

  @override
  void routes(r) {
    r.child('/', child: (_) => const _PlaceholderScreen());
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('To-Do List - TCC')),
      body: const Center(
        child: Text(
          'Aplicação rodando!\n\n'
              'Estrutura configurada com sucesso.\n'
              'Próximo passo: implementar o módulo Home.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}