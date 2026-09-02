import 'package:flutter/material.dart';

import '../../../main.dart';

class EmptyState extends StatelessWidget {
  final TodoTaskFilter filter;
  final String searchQuery;
  final VoidCallback onClearFilters;

  const EmptyState({super.key, required this.filter, required this.searchQuery, required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    final hasSearch = searchQuery.isNotEmpty;
    final hasFilter = filter != TodoTaskFilter.all;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIcon(), size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_getMessage(), style: TextStyle(color: Colors.grey.shade600)),
          if (hasSearch || hasFilter) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onClearFilters, child: const Text('Limpar filtros')),
          ],
        ],
      ),
    );
  }

  IconData _getIcon() {
    if (searchQuery.isNotEmpty) {
      return Icons.search_off;
    }
    switch (filter) {
      case TodoTaskFilter.pending:
        return Icons.pending;
      case TodoTaskFilter.completed:
        return Icons.check_circle;
      default:
        return Icons.list;
    }
  }

  String _getMessage() {
    if (searchQuery.isNotEmpty) {
      return 'Nenhuma tarefa encontrada para "$searchQuery"';
    }
    switch (filter) {
      case TodoTaskFilter.pending:
        return 'Nenhuma tarefa pendente';
      case TodoTaskFilter.completed:
        return 'Nenhuma tarefa concluída';
      default:
        return 'Nenhuma tarefa encontrada';
    }
  }
}
