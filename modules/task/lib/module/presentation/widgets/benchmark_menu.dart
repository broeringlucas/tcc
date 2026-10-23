import 'package:common/main.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';

class BenchmarkMenu extends StatefulWidget {
  final String approachKey;
  final void Function(int count) onLoad;
  final void Function(String query) onSearch;
  final Future<int> Function() onRunScroll;
  final VoidCallback onThemeToggle;

  const BenchmarkMenu({
    super.key,
    required this.approachKey,
    required this.onLoad,
    required this.onSearch,
    required this.onRunScroll,
    required this.onThemeToggle,
  });

  @override
  State<BenchmarkMenu> createState() => _BenchmarkMenuState();
}

class _BenchmarkMenuState extends State<BenchmarkMenu> {
  static const int _themeRuns = 10;
  static const int _themeToggles = 30;
  static const Duration _themeGap = Duration(milliseconds: 100);

  final FrameMetricsRecorder _themeRecorder = FrameMetricsRecorder();
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _themeRecorder.attach();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoStart());
  }

  @override
  void dispose() {
    _themeRecorder.detach();
    super.dispose();
  }

  void _maybeAutoStart() {
    const autoApproach = String.fromEnvironment('AUTO_APPROACH');
    if (autoApproach.isEmpty || autoApproach != widget.approachKey) return;
    Future<void>.delayed(const Duration(seconds: 2), _runFullProtocol);
  }

  Future<int> runThemeBenchmark() async {
    if (_running) return 0;
    _running = true;
    final tracker = PerformanceTracker();
    var recorded = 0;

    try {
      for (var run = 0; run <= _themeRuns; run++) {
        final isWarmup = run == 0;
        if (isWarmup) tracker.muted = true;

        if (!isWarmup) _themeRecorder.start('THEME', widget.approachKey);
        for (var i = 0; i < _themeToggles; i++) {
          widget.onThemeToggle();
          await Future<void>.delayed(_themeGap);
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!isWarmup) {
          _themeRecorder.stop();
          recorded++;
        }

        if (isWarmup) tracker.muted = false;
      }
    } finally {
      _running = false;
      tracker.muted = false;
    }

    return recorded;
  }

  Future<void> _runFullProtocol() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full protocol started — see the console for PERF output.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    final runner = ProtocolRunner(
      hooks: ProtocolHooks(
        approachKey: widget.approachKey,
        load: widget.onLoad,
        search: widget.onSearch,
        runScroll: widget.onRunScroll,
        runTheme: runThemeBenchmark,
      ),
    );

    await runner.run();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Full protocol aborted — see the console for details.')));
  }

  Future<void> _run(String kind) async {
    if (kind == 'protocol') {
      await _runFullProtocol();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('$kind benchmark started…'), duration: const Duration(milliseconds: 2500)),
    );

    String resultMessage;
    if (kind == 'scroll') {
      final runs = await widget.onRunScroll();
      resultMessage = 'Scroll benchmark finished — $runs run(s) recorded. See PerfMenu.';
    } else {
      final runs = await runThemeBenchmark();
      resultMessage = 'Theme benchmark finished — $runs run(s) recorded ($_themeToggles toggles each). See PerfMenu.';
    }

    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(resultMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.speed),
      tooltip: 'Benchmarks',
      onSelected: _run,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'scroll', child: Text('Run scroll benchmark')),
        PopupMenuItem(value: 'theme', child: Text('Run theme benchmark')),
        PopupMenuItem(value: 'protocol', child: Text('Run full protocol')),
      ],
    );
  }
}
