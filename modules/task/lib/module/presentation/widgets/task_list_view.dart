import 'package:common/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../main.dart';

/// Lista de tarefas compartilhada pelas 4 implementações (BLoC, Provider,
/// Riverpod, GetX). Além de renderizar o `ListView.builder` idêntico, concentra
/// a instrumentação do **cenário de Scroll**:
///
/// - registra um `addTimingsCallback` global e, enquanto `_measuring` está
///   ligado, grava `buildDuration` e `rasterDuration` de cada frame no
///   `PerformanceTracker` (chaves `SCROLL_BUILD_<abordagem>` /
///   `SCROLL_RASTER_<abordagem>`, 1 amostra por frame);
/// - `runScrollBenchmark()` roda uma rolagem programática de distância e
///   duração fixas (mesma velocidade para as 4), acionada pelo
///   `ScrollBenchmarkButton` na AppBar de cada view.
///
/// Manter a lista aqui — e não inline em cada view — é o que garante que a
/// medição de scroll seja bit-a-bit igual entre as abordagens.
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
  // Critério de rolagem — igual para as 4 implementações (comparação justa).
  static const double _scrollDistance = 5000;
  static const Duration _scrollDuration = Duration(seconds: 2);

  final ScrollController _scrollController = ScrollController();
  bool _measuring = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!_measuring) return;
    final tracker = PerformanceTracker();
    for (final timing in timings) {
      tracker.recordOperationMicros(
        'SCROLL_BUILD_${widget.approachKey}',
        timing.buildDuration.inMicroseconds,
      );
      tracker.recordOperationMicros(
        'SCROLL_RASTER_${widget.approachKey}',
        timing.rasterDuration.inMicroseconds,
      );
    }
  }

  Future<void> runScrollBenchmark() async {
    if (_measuring || !_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    final target = _scrollDistance.clamp(0.0, maxExtent);

    _scrollController.jumpTo(0);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    _measuring = true;
    await _scrollController.animateTo(target, duration: _scrollDuration, curve: Curves.linear);
    // Deixa os últimos frames de raster chegarem no callback antes de parar.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _measuring = false;
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
