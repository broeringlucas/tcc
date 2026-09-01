import '../../../main.dart';

class TaskFilterUtils {
  static List<TodoTask> filterByStatus(List<TodoTask> tasks, TodoTaskFilter filter) {
    switch (filter) {
      case TodoTaskFilter.pending:
        return tasks.where((task) => !task.completed).toList();
      case TodoTaskFilter.completed:
        return tasks.where((task) => task.completed).toList();
      case TodoTaskFilter.all:
        return tasks;
    }
  }

  static List<TodoTask> filterBySearch(List<TodoTask> tasks, String query) {
    if (query.isEmpty) return tasks;
    final lowerQuery = query.toLowerCase();
    return tasks.where((task) {
      final titleMatch = task.title.toLowerCase().contains(lowerQuery);
      final descMatch = task.description.toLowerCase().contains(lowerQuery);
      return titleMatch || descMatch;
    }).toList();
  }

  static List<TodoTask> applyFilters(List<TodoTask> tasks, TodoTaskFilter filter, String query) {
    final byStatus = filterByStatus(tasks, filter);
    return filterBySearch(byStatus, query);
  }

  static List<TodoTask> sortByDate(List<TodoTask> tasks) {
    final sorted = List<TodoTask>.from(tasks);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
}
