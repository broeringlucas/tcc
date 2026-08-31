import 'package:common/main.dart';
import 'package:dependencies/flutter_modular.dart';
import 'package:flutter/material.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  bool _isDatabaseReady = false;

  @override
  void initState() {
    super.initState();
    _prepareDatabase();
  }

  Future<void> _prepareDatabase() async {
    final db = AppDatabase();
    await db.ensureSeeded();
    setState(() {
      _isDatabaseReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDatabaseReady) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [CircularProgressIndicator(), SizedBox(height: 16), Text('Preparing database...')],
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'To-Do List - State Management',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      routerConfig: Modular.routerConfig,
      debugShowCheckedModeBanner: false,
    );
  }
}
