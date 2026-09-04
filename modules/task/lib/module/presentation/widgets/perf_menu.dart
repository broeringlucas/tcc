import 'package:common/main.dart';
import 'package:flutter/material.dart';

class PerfMenu extends StatelessWidget {
  const PerfMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.assessment),
      tooltip: 'Métricas',
      onSelected: (value) {
        final tracker = PerformanceTracker();
        if (value == 'print') {
          tracker.printSummary();
        } else if (value == 'reset') {
          tracker.reset();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'print', child: Text('Imprimir resumo')),
        PopupMenuItem(value: 'reset', child: Text('Zerar métricas')),
      ],
    );
  }
}
