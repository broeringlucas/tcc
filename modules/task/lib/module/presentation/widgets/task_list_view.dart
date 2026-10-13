import 'package:flutter/material.dart';

import '../../../main.dart';

class TaskListView extends StatefulWidget {
  final List<TodoTask> tasks;
  final String approachKey;
  final void Function(TodoTask task) onToggle;
  final void Function(int id) onDelete;
  final void Function(TodoTask task) onEdit;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.approachKey,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TaskListView> createState() => TaskListViewState();
}

class TaskListViewState extends State<TaskListView> {
  // Protocolo documentado no CLAUDE.md / 04_metodologia.tex: 10 execuções,
  // descartando a 1ª (aquecimento de shader/JIT) — aqui rodadas automaticamente
  // numa única chamada, em vez de depender de 10 cliques manuais no benchmark.
  static const int _scrollRuns = 10;
  static const double _scrollDistance = 5000;
  static const Duration _scrollDuration = Duration(seconds: 2);

  final ScrollController _scrollController = ScrollController();
  final FrameMetricsRecorder _recorder = FrameMetricsRecorder();
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _recorder.attach();
  }

  @override
  void dispose() {
    _recorder.detach();
    _scrollController.dispose();
    super.dispose();
  }

  /// Roda o benchmark de scroll `_scrollRuns` vezes (+1 aquecimento descartado)
  /// e só então retorna — o print do resumo deve ser disparado depois, pelo
  /// `PerfMenu`. Retorna o número de execuções efetivamente registradas.
  Future<int> runScrollBenchmark() async {
    if (_running || !_scrollController.hasClients) return 0;

    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return 0;

    _running = true;
    final target = _scrollDistance.clamp(0.0, maxExtent);
    var recorded = 0;

    try {
      for (var run = 0; run <= _scrollRuns; run++) {
        final isWarmup = run == 0;

        _scrollController.jumpTo(0);
        await Future<void>.delayed(const Duration(milliseconds: 300));

        if (!isWarmup) _recorder.start('SCROLL', widget.approachKey);
        await _scrollController.animateTo(target, duration: _scrollDuration, curve: Curves.linear);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!isWarmup) {
          _recorder.stop();
          recorded++;
        }
      }
    } finally {
      _running = false;
    }

    return recorded;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.tasks.length,
      itemBuilder: (_, index) {
        final task = widget.tasks[index];
        return TaskTile(
          key: ValueKey(task.id),
          task: task,
          onToggle: () => widget.onToggle(task),
          onDelete: () => widget.onDelete(task.id!),
          onEdit: () => widget.onEdit(task),
        );
      },
    );
  }
}
