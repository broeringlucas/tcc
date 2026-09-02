import 'package:dependencies/bloc.dart';
import 'package:dependencies/flutter_modular.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';

class BlocHomeView extends StatefulWidget {
  const BlocHomeView({super.key});

  @override
  State<BlocHomeView> createState() => _BlocHomeViewState();
}

class _BlocHomeViewState extends State<BlocHomeView> {
  late final TaskBloc _bloc;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = Modular.get<TaskBloc>();
    _bloc.loadTasksWithFilter(TodoTaskFilter.all, 0);
    _searchController.addListener(() {
      _bloc.searchTasks(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLoC - To-Do List'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          FilterDropdown(
            currentFilter: _bloc.state is TaskLoaded ? (_bloc.state as TaskLoaded).currentFilter : TodoTaskFilter.all,
            onFilterChanged: (filter) => _bloc.changeFilter(filter),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.play_arrow),
            onSelected: (value) {
              final count = int.parse(value);
              if (count >= 0) {
                final currentFilter = _bloc.state is TaskLoaded
                    ? (_bloc.state as TaskLoaded).currentFilter
                    : TodoTaskFilter.all;
                _bloc.loadTasksWithFilter(currentFilter, count);
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
          CustomSearchBar(controller: _searchController, onSearch: (query) => _bloc.searchTasks(query)),
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              bloc: _bloc,
              builder: (context, state) {
                if (state is TaskLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TaskError) {
                  return Center(child: Text(state.message));
                }
                if (state is TaskLoaded) {
                  if (state.tasks.isEmpty) {
                    return EmptyState(
                      filter: state.currentFilter,
                      searchQuery: _searchController.text,
                      onClearFilters: () {
                        _searchController.clear();
                        _bloc.searchTasks('');
                        _bloc.changeFilter(TodoTaskFilter.all);
                      },
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.tasks.length,
                    itemBuilder: (_, index) {
                      final task = state.tasks[index];
                      return TaskTile(
                        key: ValueKey(task.id),
                        task: task,
                        onToggle: () => _bloc.add(ToggleTaskEvent(task)),
                        onDelete: () => _bloc.add(DeleteTaskEvent(task.id!)),
                        onEdit: () => Modular.to.pushNamed('/edit', arguments: task),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Modular.to.pushNamed('/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
