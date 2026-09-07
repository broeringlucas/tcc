import 'package:flutter/material.dart';

import '../../../main.dart';

class BenchmarkMenu extends StatefulWidget {
  final String approachKey;
  final Future<void> Function() onRunScroll;
  final VoidCallback onThemeToggle;

  const BenchmarkMenu({
    super.key,
    required this.approachKey,
    required this.onRunScroll,
    required this.onThemeToggle,
  });

  @override
  State<BenchmarkMenu> createState() => _BenchmarkMenuState();
}

class _BenchmarkMenuState extends State<BenchmarkMenu> {
  static const int _themeToggles = 30;
  static const Duration _themeGap = Duration(milliseconds: 100);

  final FrameMetricsRecorder _themeRecorder = FrameMetricsRecorder();
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _themeRecorder.attach();
  }

  @override
  void dispose() {
    _themeRecorder.detach();
    super.dispose();
  }

  Future<void> _runThemeBenchmark() async {
    if (_running) return;
    _running = true;
    _themeRecorder.start('THEME', widget.approachKey);
    for (var i = 0; i < _themeToggles; i++) {
      widget.onThemeToggle();
      await Future<void>.delayed(_themeGap);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _themeRecorder.stop();
    _running = false;
  }

  Future<void> _run(String kind) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Benchmark de $kind iniciado…'), duration: const Duration(milliseconds: 2500)),
    );
    if (kind == 'scroll') {
      await widget.onRunScroll();
    } else {
      await _runThemeBenchmark();
    }
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Benchmark concluído — ver PerfMenu')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.speed),
      tooltip: 'Benchmarks',
      onSelected: _run,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'scroll', child: Text('Rodar benchmark de scroll')),
        PopupMenuItem(value: 'tema', child: Text('Rodar benchmark de tema')),
      ],
    );
  }
}
