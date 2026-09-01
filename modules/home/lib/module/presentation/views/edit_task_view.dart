import 'package:dependencies/flutter_modular.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';

class EditTaskView extends StatefulWidget {
  final TodoTask task;

  const EditTaskView({super.key, required this.task});

  @override
  State<EditTaskView> createState() => _EditTaskViewState();
}

class _EditTaskViewState extends State<EditTaskView> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveTask)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created: ${_formatDate(widget.task.createdAt)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    if (widget.task.updatedAt != null)
                      Text(
                        'Last updated: ${_formatDate(widget.task.updatedAt!)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final updatedTask = widget.task.copyWith(
      title: title,
      description: _descriptionController.text.trim(),
      updatedAt: DateTime.now(),
    );

    context.read<TaskBloc>().add(UpdateTaskEvent(updatedTask));
    Modular.to.pop();
  }
}
