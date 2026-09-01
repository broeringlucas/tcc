import 'package:common/main.dart';
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
  TodoTaskFilter _currentFilter = TodoTaskFilter.all;

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
    PerformanceTracker().recordRebuild('BlocHomeView');

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLoC - To-Do List'),
        actions: [
          AppBarActions(
            currentFilter: _currentFilter,
            onFilterChanged: (filter) => _bloc.changeFilter(filter),
            onLoadTasks: (count) => _bloc.loadTasksWithFilter(_currentFilter, count),
            implementationName: 'BLoC',
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
                  _currentFilter = state.currentFilter;
                  if (state.tasks.isEmpty) {
                    return EmptyState(
                      filter: state.currentFilter,
                      searchQuery: state.searchQuery,
                      onClearFilters: () {
                        _searchController.clear();
                        _bloc.searchTasks('');
                        _bloc.changeFilter(TodoTaskFilter.all);
                      },
                    );
                  }
                  return ListView.builder(
                    itemCount: state.tasks.length,
                    itemBuilder: (_, index) => TaskTile(
                      key: ValueKey(state.tasks[index].id),
                      task: state.tasks[index],
                      onToggle: () => _bloc.add(ToggleTaskEvent(state.tasks[index])),
                      onDelete: () => _bloc.add(DeleteTaskEvent(state.tasks[index].id!)),
                      onEdit: () => Modular.to.pushNamed('/edit', arguments: state.tasks[index]),
                    ),
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
