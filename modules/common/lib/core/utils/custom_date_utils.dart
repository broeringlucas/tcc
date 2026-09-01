class CustomDateUtils {
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    String dayText;
    if (dateOnly == today) {
      dayText = 'Hoje';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      dayText = 'Ontem';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      const weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
      dayText = weekdays[date.weekday % 7];
    } else {
      dayText = '${date.day}/${date.month}/${date.year}';
    }

    return '$dayText ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
