import 'package:common/main.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';

class TaskTile extends StatefulWidget {
  final TodoTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const TaskTile({super.key, required this.task, required this.onToggle, required this.onDelete, this.onEdit});

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _completed = widget.task.completed;
  }

  @override
  void didUpdateWidget(TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.completed != widget.task.completed) {
      _completed = widget.task.completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: _completed,
        onChanged: (_) {
          setState(() {
            _completed = !_completed;
          });
          widget.onToggle();
        },
      ),
      title: Text(
        widget.task.title,
        style: TextStyle(decoration: widget.task.completed ? TextDecoration.lineThrough : null),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.task.description.isNotEmpty) Text(widget.task.description),
          Text(
            CustomDateUtils.formatDate(widget.task.createdAt),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: widget.onEdit,
            ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
