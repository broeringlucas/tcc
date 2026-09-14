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

        return Theme(
          data: AppThemes.of(notifier.isDarkMode),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Provider'),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              actions: [
                FilterDropdown(
                  currentFilter: notifier.currentFilter,
                  onFilterChanged: (filter) => notifier.changeFilter(filter),
                ),
                LoadMenu(onLoad: (count) => notifier.loadTasksWithFilter(notifier.currentFilter, count)),
                ThemeToggleButton(isDark: notifier.isDarkMode, onToggle: notifier.toggleTheme),
                BenchmarkMenu(
                  approachKey: 'provider',
                  onRunScroll: () async => _listKey.currentState?.runScrollBenchmark(),
                  onThemeToggle: notifier.toggleTheme,
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
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => AddTaskView(onSubmit: notifier.addTask))),
              child: const Icon(Icons.add),
            ),
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
        MaterialPageRoute(
          builder: (_) => EditTaskView(task: task, onSubmit: notifier.updateTask),
        ),
      ),
    );
  }
}
