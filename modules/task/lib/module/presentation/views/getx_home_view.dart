import 'package:common/main.dart';
import 'package:dependencies/get.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';

class GetxHomeView extends StatefulWidget {
  const GetxHomeView({super.key});

  @override
  State<GetxHomeView> createState() => _GetxHomeViewState();
}

class _GetxHomeViewState extends State<GetxHomeView> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<TaskListViewState> _listKey = GlobalKey();
  late final DebounceUtil _debounce;
  final TaskController _controller = Get.find<TaskController>();

  @override
  void initState() {
    super.initState();
    _debounce = DebounceUtil();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadTasksWithFilter(TodoTaskFilter.all, 0);
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    _debounce.run(() {
      _controller.searchTasks(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce.dispose();
    Get.delete<TaskController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = _controller;
      PerformanceTracker().recordRebuildWithContext('REBUILD_getx');

      return Theme(
        data: AppThemes.of(controller.isDarkMode),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('GetX'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            actions: [
              FilterDropdown(
                currentFilter: controller.currentFilter,
                onFilterChanged: (filter) => controller.changeFilter(filter),
              ),
              LoadMenu(onLoad: (count) => controller.loadTasksWithFilter(controller.currentFilter, count)),
              ThemeToggleButton(isDark: controller.isDarkMode, onToggle: controller.toggleTheme),
              BenchmarkMenu(
                approachKey: 'getx',
                onRunScroll: () async => _listKey.currentState?.runScrollBenchmark(),
                onThemeToggle: controller.toggleTheme,
              ),
              const PerfMenu(),
            ],
          ),
          body: Column(
            children: [
              CustomSearchBar(controller: _searchController),
              Expanded(child: _buildBody(controller)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => AddTaskView(onSubmit: controller.addTask))),
            child: const Icon(Icons.add),
          ),
        ),
      );
    });
  }

  Widget _buildBody(TaskController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null) {
      return Center(child: Text(controller.error!));
    }
    final tasks = controller.tasks;
    if (tasks.isEmpty) {
      return EmptyState(
        filter: controller.currentFilter,
        searchQuery: _searchController.text,
        onClearFilters: () {
          _searchController.clear();
          controller.searchTasks('');
          controller.changeFilter(TodoTaskFilter.all);
        },
      );
    }
    return TaskListView(
      key: _listKey,
      tasks: tasks,
      approachKey: 'getx',
      onToggle: (task) => controller.toggleTask(task),
      onDelete: (id) => controller.deleteTask(id),
      onEdit: (task) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditTaskView(task: task, onSubmit: controller.updateTask),
        ),
      ),
    );
  }
}
