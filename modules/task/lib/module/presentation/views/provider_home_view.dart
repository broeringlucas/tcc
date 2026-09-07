import 'package:common/main.dart';
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
  final GlobalKey<TaskListViewState> _listKey = GlobalKey();
  late final DebounceUtil _debounce;

  @override
  void initState() {
    super.initState();
    _debounce = DebounceUtil();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderTaskNotifier>().loadTasksWithFilter(TodoTaskFilter.all, 0);
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    _debounce.run(() {
      context.read<ProviderTaskNotifier>().searchTasks(query);
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
    return Consumer<ProviderTaskNotifier>(
      builder: (context, notifier, child) {
        PerformanceTracker().recordRebuildWithContext('REBUILD_provider');

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
                    notifier.loadTasksWithFilter(notifier.currentFilter, count);
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
              ScrollBenchmarkButton(
                onRun: () async => _listKey.currentState?.runScrollBenchmark(),
              ),
              const PerfMenu(),
            ],
          ),
          body: Column(
            children: [
              CustomSearchBar(controller: _searchController),
              Expanded(child: _buildBody(notifier)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddTaskView(onSubmit: notifier.addTask)),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(ProviderTaskNotifier notifier) {
    if (notifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifier.error != null) {
      return Center(child: Text(notifier.error!));
    }
    final tasks = notifier.tasks;
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
    return TaskListView(
      key: _listKey,
      tasks: tasks,
      approachKey: 'provider',
      onToggle: (task) => notifier.toggleTask(task),
      onDelete: (id) => notifier.deleteTask(id),
      onEdit: (task) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EditTaskView(task: task, onSubmit: notifier.updateTask)),
      ),
    );
  }
}
