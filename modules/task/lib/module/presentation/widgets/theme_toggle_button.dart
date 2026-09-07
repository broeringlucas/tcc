import 'package:flutter/material.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const ThemeToggleButton({super.key, required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
      tooltip: 'Alternar tema',
      onPressed: onToggle,
    );
  }
}
