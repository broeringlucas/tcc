import 'package:flutter/material.dart';

class LoadMenu extends StatelessWidget {
  final ValueChanged<int> onLoad;

  const LoadMenu({super.key, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.play_arrow),
      tooltip: 'Load tasks',
      onSelected: (value) {
        final count = int.parse(value);
        if (count >= 0) {
          onLoad(count);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: '0', child: Text('Load all tasks')),
        PopupMenuItem(value: '1000', child: Text('Load 1,000 tasks')),
        PopupMenuItem(value: '10000', child: Text('Load 10,000 tasks')),
        PopupMenuItem(value: '100000', child: Text('Load 100,000 tasks')),
      ],
    );
  }
}
