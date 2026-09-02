import 'package:dependencies/provider.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';

class ProviderHomeView extends StatefulWidget {
  const ProviderHomeView({super.key});

  @override
  State<ProviderHomeView> createState() => _ProviderHomeViewState();
}

class _ProviderHomeViewState extends State<ProviderHomeView> {
  final TextEditingController _searchController = TextEditingController();
  TodoTaskFilter _currentFilter = TodoTaskFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = Provider.of<TaskNotifier>(context, listen: false);
      notifier.loadTasksWithFilter(TodoTaskFilter.all, 0);
    });
    _searchController.addListener(() {
      final notifier = Provider.of<TaskNotifier>(context, listen: false);
      notifier.searchTasks(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskNotifier>(
      builder: (context, notifier, child) {
        _currentFilter = notifier.currentFilter;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Provider - To-Do List'),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            actions: [
              FilterDropdown(
                currentFilter: notifier.currentFilter,
                onFilterChanged: (filter) => notifier.changeFilter(filter),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.play_arrow),
                onSelected: (value) {
                  final count = int.parse(value);
                  if (count >= 0) {
                    notifier.loadTasksWithFilter(_currentFilter, count);
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
          ),
          body: Column(
            children: [
              CustomSearchBar(controller: _searchController, onSearch: (query) => notifier.searchTasks(query)),
              Expanded(child: _buildBody(notifier)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(TaskNotifier notifier) {
    if (notifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifier.error != null) {
      return Center(child: Text(notifier.error!));
    }
    if (notifier.tasks.isEmpty) {
      return EmptyState(
        filter: notifier.currentFilter,
        searchQuery: _searchController.text,
        onClearFilters: () {
          _searchController.clear();
          notifier.searchTasks('');
          notifier.changeFilter(TodoTaskFilter.all);
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: notifier.tasks.length,
      itemBuilder: (_, index) {
        final task = notifier.tasks[index];
        return TaskTile(
          key: ValueKey(task.id),
          task: task,
          onToggle: () => notifier.toggleTask(task),
          onDelete: () => notifier.deleteTask(task.id!),
          onEdit: null,
        );
      },
    );
  }
}
