import 'package:flutter/material.dart';

import 'widgets/widgets.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TCC'),
        centerTitle: true,
        elevation: 0,
        leading: Builder(
          builder: (context) =>
              IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
        ),
      ),
      drawer: const HomeDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Select a state manager:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const StateManagerCard(title: 'BLoC', color: Colors.blue, icon: Icons.code, route: '/task/bloc'),
            const SizedBox(height: 16),
            const StateManagerCard(
              title: 'Provider',
              color: Colors.purple,
              icon: Icons.code,
              route: '/task/provider',
            ),
            const SizedBox(height: 16),
            const StateManagerCard(
              title: 'Riverpod',
              color: Colors.green,
              icon: Icons.code,
              route: '/task/riverpod',
            ),
            const SizedBox(height: 16),
            const StateManagerCard(title: 'GetX', color: Colors.orange, icon: Icons.code, route: '/task/getx'),
            const Spacer(),
            const Text(
              'To-Do List App - Comparative Analysis',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
