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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 8, right: 4, top: 2, bottom: 2),
        leading: Checkbox(
          value: _completed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (_) {
            setState(() {
              _completed = !_completed;
            });
            widget.onToggle();
          },
        ),
        title: Text(
          widget.task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: widget.task.completed ? TextDecoration.lineThrough : null,
            color: widget.task.completed ? Theme.of(context).disabledColor : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.task.description.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 2), child: Text(widget.task.description)),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                CustomDateUtils.formatDate(widget.task.createdAt),
                style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: widget.onEdit,
              ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              tooltip: 'Delete',
              onPressed: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
