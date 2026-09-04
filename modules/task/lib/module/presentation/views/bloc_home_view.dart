import 'package:common/main.dart';
import 'package:dependencies/bloc.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';

class BlocHomeView extends StatefulWidget {
  const BlocHomeView({super.key});

  @override
  State<BlocHomeView> createState() => _BlocHomeViewState();
}

class _BlocHomeViewState extends State<BlocHomeView> {
  final TextEditingController _searchController = TextEditingController();
  late final DebounceUtil _debounce;

  @override
  void initState() {
    super.initState();
    _debounce = DebounceUtil();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskBloc>().loadTasksWithFilter(TodoTaskFilter.all, 0);
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    _debounce.run(() {
      context.read<TaskBloc>().searchTasks(query);
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
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final bloc = context.read<TaskBloc>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('BLoC - To-Do List'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              FilterDropdown(
                currentFilter: bloc.currentFilter,
                onFilterChanged: (filter) => bloc.changeFilter(filter),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.play_arrow),
                onSelected: (value) {
                  final count = int.parse(value);
                  if (count >= 0) {
                    bloc.loadTasksWithFilter(bloc.currentFilter, count);
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
              const PerfMenu(),
            ],
          ),
          body: Column(
            children: [
              CustomSearchBar(controller: _searchController),
              Expanded(child: _buildBody(bloc, state)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddTaskView(onSubmit: bloc.addTask)),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(TaskBloc bloc, TaskState state) {
    if (state is TaskLoading || state is TaskInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is TaskError) {
      return Center(child: Text(state.message));
    }
    final tasks = state is TaskLoaded ? state.tasks : <TodoTask>[];
    if (tasks.isEmpty) {
      return EmptyState(
        filter: bloc.currentFilter,
        searchQuery: _searchController.text,
        onClearFilters: () {
          _searchController.clear();
          bloc.searchTasks('');
          bloc.changeFilter(TodoTaskFilter.all);
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
          onToggle: () => bloc.add(ToggleTaskEvent(task)),
          onDelete: () => bloc.add(DeleteTaskEvent(task.id!)),
          onEdit: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EditTaskView(task: task, onSubmit: bloc.updateTask)),
          ),
        );
      },
    );
  }
}
