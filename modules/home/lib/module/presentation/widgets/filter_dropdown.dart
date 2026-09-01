import 'package:flutter/material.dart';

import '../../../main.dart';

class FilterDropdown extends StatelessWidget {
  final TodoTaskFilter currentFilter;
  final ValueChanged<TodoTaskFilter> onFilterChanged;

  const FilterDropdown({super.key, required this.currentFilter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TodoTaskFilter>(
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
    );
  }
}
