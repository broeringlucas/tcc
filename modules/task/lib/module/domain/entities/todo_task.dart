import 'package:dependencies/equatable.dart';

class TodoTask extends Equatable {
  final int? id;
  final String title;
  final String description;
  final bool completed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TodoTask({
    this.id,
    required this.title,
    this.description = '',
    this.completed = false,
    required this.createdAt,
    this.updatedAt,
  });

  TodoTask copyWith({
    int? id,
    String? title,
    String? description,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, description, completed, createdAt, updatedAt];
}
