import 'package:dependencies/flutter_modular.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';

class AddTaskView extends StatefulWidget {
  const AddTaskView({super.key});

  @override
  State<AddTaskView> createState() => _AddTaskViewState();
}

class _AddTaskViewState extends State<AddTaskView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Task')),
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
            ElevatedButton(onPressed: _addTask, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  void _addTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final task = TodoTask(title: title, description: _descriptionController.text.trim());

    Modular.get<TaskBloc>().add(AddTaskEvent(task));
    Modular.to.pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
