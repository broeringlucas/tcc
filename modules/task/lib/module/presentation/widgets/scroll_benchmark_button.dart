import 'package:flutter/material.dart';

/// Ação de AppBar compartilhada pelas 4 views: dispara a rolagem programática
/// instrumentada do `TaskListView` (cenário de Scroll). Feedback visual por
/// SnackBar porque a rolagem leva ~2,5 s.
class ScrollBenchmarkButton extends StatelessWidget {
  final Future<void> Function() onRun;

  const ScrollBenchmarkButton({super.key, required this.onRun});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.swap_vert),
      tooltip: 'Rodar benchmark de scroll',
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Scroll benchmark iniciado…'), duration: Duration(milliseconds: 2500)),
        );
        await onRun();
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Scroll benchmark concluído — ver PerfMenu')),
        );
      },
    );
  }
}
