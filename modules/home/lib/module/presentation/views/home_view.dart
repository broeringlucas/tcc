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

  @override
  void initState() {
    super.initState();
    _bloc = Modular.get<TaskBloc>();
    _bloc.loadTasksWithCount(0);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PerformanceTracker().recordRebuild('BlocHomeView');

    return Scaffold(
      appBar: _buildAppBar(),
      body: BlocBuilder<TaskBloc, TaskState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TaskError) {
            return Center(child: Text(state.message));
          }
          if (state is TaskLoaded) {
            return _buildTaskList(state.tasks);
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Modular.to.pushNamed('/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('BLoC - To-Do List'),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.play_arrow),
          onSelected: (value) {
            final count = int.parse(value);
            if (count >= 0) {
              _bloc.loadTasksWithCount(count);
            }
          },
          tooltip: 'Load tasks',
          itemBuilder: (_) => [
            const PopupMenuItem(value: '0', child: Text('Load all tasks')),
            const PopupMenuItem(value: '1000', child: Text('Load 1,000 tasks')),
            const PopupMenuItem(value: '10000', child: Text('Load 10,000 tasks')),
            const PopupMenuItem(value: '100000', child: Text('Load 100,000 tasks')),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskList(List<TodoTask> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks found'));
    }
    return ListView.builder(itemCount: tasks.length, itemBuilder: (_, index) => _buildTaskTile(tasks[index]));
  }

  Widget _buildTaskTile(TodoTask task) {
    return ListTile(
      leading: Checkbox(value: task.completed, onChanged: (_) {}),
      title: Text(task.title),
      subtitle: task.description.isNotEmpty ? Text(task.description) : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _bloc.add(DeleteTaskEvent(task.id!)),
      ),
    );
  }
}
