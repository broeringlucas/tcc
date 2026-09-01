import 'package:flutter/material.dart';

import '../../../main.dart';

class AppBarActions extends StatelessWidget {
  final TodoTaskFilter currentFilter;
  final ValueChanged<TodoTaskFilter> onFilterChanged;
  final ValueChanged<int> onLoadTasks;
  final String implementationName;

  const AppBarActions({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.onLoadTasks,
    this.implementationName = 'BLoC',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Filtro
        PopupMenuButton<TodoTaskFilter>(
          icon: const Icon(Icons.filter_list),
          onSelected: onFilterChanged,
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: TodoTaskFilter.all,
              child: Row(children: [Icon(Icons.list, size: 20), SizedBox(width: 8), Text('Todas')]),
            ),
            const PopupMenuItem(
              value: TodoTaskFilter.pending,
              child: Row(
                children: [
                  Icon(Icons.pending, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Pendentes'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: TodoTaskFilter.completed,
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Concluídas'),
                ],
              ),
            ),
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.play_arrow),
          onSelected: (value) {
            final count = int.parse(value);
            if (count >= 0) {
              onLoadTasks(count);
            }
          },
          tooltip: 'Load tasks',
          itemBuilder: (_) => const [
            PopupMenuItem(value: '0', child: Text('Load all tasks')),
            PopupMenuItem(value: '1000', child: Text('Load 1,000 tasks')),
            PopupMenuItem(value: '10000', child: Text('Load 10,000 tasks')),
            PopupMenuItem(value: '100000', child: Text('Load 100,000 tasks')),
          ],
        ),
      ],
    );
  }
}
