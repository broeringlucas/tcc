import 'package:flutter/material.dart';

import '../../../main.dart';

class TaskListView extends StatefulWidget {
  final List<TodoTask> tasks;
  final String approachKey;
  final void Function(TodoTask task) onToggle;
  final void Function(int id) onDelete;
  final void Function(TodoTask task) onEdit;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.approachKey,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TaskListView> createState() => TaskListViewState();
}

class TaskListViewState extends State<TaskListView> {
  static const double _scrollDistance = 5000;
  static const Duration _scrollDuration = Duration(seconds: 2);

  final ScrollController _scrollController = ScrollController();
  final FrameMetricsRecorder _recorder = FrameMetricsRecorder();
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _recorder.attach();
  }

  @override
  void dispose() {
    _recorder.detach();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> runScrollBenchmark() async {
    if (_running || !_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    _running = true;
    final target = _scrollDistance.clamp(0.0, maxExtent);

    _scrollController.jumpTo(0);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    _recorder.start('SCROLL', widget.approachKey);
    await _scrollController.animateTo(target, duration: _scrollDuration, curve: Curves.linear);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _recorder.stop();
    _running = false;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.tasks.length,
      itemBuilder: (_, index) {
        final task = widget.tasks[index];
        return TaskTile(
          key: ValueKey(task.id),
          task: task,
          onToggle: () => widget.onToggle(task),
          onDelete: () => widget.onDelete(task.id!),
          onEdit: () => widget.onEdit(task),
        );
      },
    );
  }
}
