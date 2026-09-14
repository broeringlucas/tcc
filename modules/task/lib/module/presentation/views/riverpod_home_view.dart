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
  final GlobalKey<TaskListViewState> _listKey = GlobalKey();
  late final DebounceUtil _debounce;

  @override
  void initState() {
    super.initState();
    _debounce = DebounceUtil();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riverpodTaskNotifierProvider.notifier).loadTasksWithFilter(TodoTaskFilter.all, 0);
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    _debounce.run(() {
      ref.read(riverpodTaskNotifierProvider.notifier).searchTasks(query);
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
    PerformanceTracker().recordRebuildWithContext('REBUILD_riverpod');

    return Theme(
      data: AppThemes.of(notifier.isDarkMode),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riverpod'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            FilterDropdown(
              currentFilter: notifier.currentFilter,
              onFilterChanged: (filter) => notifier.changeFilter(filter),
            ),
            LoadMenu(onLoad: (count) => notifier.loadTasksWithFilter(notifier.currentFilter, count)),
            ThemeToggleButton(isDark: notifier.isDarkMode, onToggle: notifier.toggleTheme),
            BenchmarkMenu(
              approachKey: 'riverpod',
              onRunScroll: () async => _listKey.currentState?.runScrollBenchmark(),
              onThemeToggle: notifier.toggleTheme,
            ),
            const PerfMenu(),
          ],
        ),
        body: Column(
          children: [
            CustomSearchBar(controller: _searchController),
            Expanded(child: _buildBody(notifier, state)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTaskView(onSubmit: notifier.addTask))),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody(RiverpodTaskNotifier notifier, AsyncValue<List<TodoTask>> state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.hasError) {
      return Center(child: Text(state.error.toString()));
    }
    final tasks = state.value ?? <TodoTask>[];
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
      approachKey: 'riverpod',
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
