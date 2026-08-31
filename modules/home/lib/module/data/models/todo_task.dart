import '../../../main.dart';

class TodoTaskModel {
  final int? id;
  final String title;
  final String description;
  final bool completed;

  TodoTaskModel({this.id, required this.title, this.description = '', this.completed = false});

  factory TodoTaskModel.fromEntity(TodoTask task) {
    return TodoTaskModel(id: task.id, title: task.title, description: task.description, completed: task.completed);
  }

  factory TodoTaskModel.fromMap(Map<String, dynamic> map) {
    return TodoTaskModel(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      completed: map['completed'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'description': description, 'completed': completed ? 1 : 0};
  }

  TodoTask toEntity() {
    return TodoTask(id: id, title: title, description: description, completed: completed);
  }
}
