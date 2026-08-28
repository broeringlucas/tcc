import 'package:dependencies/equatable.dart';

class TodoTask extends Equatable {
  final int? id;
  final String title;
  final String description;
  final bool completed;

  const TodoTask({
    this.id,
    required this.title,
    this.description = '',
    this.completed = false,
  });

  TodoTask copyWith({
    int? id,
    String? title,
    String? description,
    bool? completed,
  }) {
    return TodoTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [id, title, description, completed];
}