import 'package:common/main.dart';
import 'package:dependencies/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';

class RiverpodHomeView extends ConsumerStatefulWidget {
  const RiverpodHomeView({super.key});

  @override
  ConsumerState<RiverpodHomeView> createState() => _RiverpodHomeViewState();
}

class _RiverpodHomeViewState extends ConsumerState<RiverpodHomeView> {
  final TextEditingController _searchController = TextEditingController();
  TodoTaskFilter _currentFilter = TodoTaskFilter.all;
  late final DebounceUtil _debounce;

  @override
  void initState() {
    super.initState();
    _debounce = DebounceUtil();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(riverpodTaskNotifierProvider.notifier);
      notifier.loadTasksWithFilter(TodoTaskFilter.all, 0);
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    _debounce.run(() {
      final notifier = ref.read(riverpodTaskNotifierProvider.notifier);
      notifier.searchTasks(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riverpodTaskNotifierProvider);
    final notifier = ref.read(riverpodTaskNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod - To-Do List'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          FilterDropdown(
            currentFilter: notifier.currentFilter,
            onFilterChanged: (filter) {
              _currentFilter = filter;
              notifier.changeFilter(filter);
            },
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
          CustomSearchBar(controller: _searchController),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text(error.toString())),
              data: (tasks) {
                if (tasks.isEmpty) {
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
                  itemCount: tasks.length,
                  itemBuilder: (_, index) {
                    final task = tasks[index];
                    return TaskTile(
                      key: ValueKey(task.id),
                      task: task,
                      onToggle: () => notifier.toggleTask(task),
                      onDelete: () => notifier.deleteTask(task.id!),
                      onEdit: null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
