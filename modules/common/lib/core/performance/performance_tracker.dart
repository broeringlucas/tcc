import 'dart:convert';
import 'dart:io';

class PerformanceTracker {
  static final PerformanceTracker _instance = PerformanceTracker._internal();
  factory PerformanceTracker() => _instance;
  PerformanceTracker._internal();

  static const int kFrameBudgetMicros = 16666;
  static const int _maxJsonLineLength = 3000;

  bool muted = false;

  final Map<String, int> _rebuildCounts = {};
  final Map<String, List<int>> _operationTimesMicros = {};
  final Map<String, List<double>> _memoryValues = {};
  final Map<String, int> _benchmarkRuns = {};
  final Map<String, int> _ticks = {};
  final Map<String, List<List<int>>> _frameRuns = {};

  void recordRebuild(String widgetName) {
    if (muted) return;
    _rebuildCounts[widgetName] = (_rebuildCounts[widgetName] ?? 0) + 1;
  }

  void recordRebuildWithContext(String context) {
    if (muted) return;
    _rebuildCounts[context] = (_rebuildCounts[context] ?? 0) + 1;
  }

  int getRebuildCount(String widgetName) {
    return _rebuildCounts[widgetName] ?? 0;
  }

  void recordOperationMicros(String operationName, int durationMicros) {
    _ticks[operationName] = (_ticks[operationName] ?? 0) + 1;
    if (muted) return;
    _operationTimesMicros.putIfAbsent(operationName, () => []);
    _operationTimesMicros[operationName]!.add(durationMicros);
  }

  void recordOperation(String operationName, Duration duration) {
    recordOperationMicros(operationName, duration.inMicroseconds);
  }

  void recordStopwatch(String operationName, Stopwatch stopwatch) {
    stopwatch.stop();
    recordOperationMicros(operationName, stopwatch.elapsedMicroseconds);
  }

  double getCurrentMemoryMB() {
    return ProcessInfo.currentRss / (1024 * 1024);
  }

  void recordMemory(String operationName, double memoryMB) {
    _ticks[operationName] = (_ticks[operationName] ?? 0) + 1;
    if (muted) return;
    _memoryValues.putIfAbsent(operationName, () => []);
    _memoryValues[operationName]!.add(memoryMB);
  }

  void recordBenchmarkRun(String key) {
    if (muted) return;
    _benchmarkRuns[key] = (_benchmarkRuns[key] ?? 0) + 1;
  }

  int tickCount(String key) => _ticks[key] ?? 0;

  Future<bool> waitForTick(String key, int previous, {Duration timeout = const Duration(seconds: 30)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (tickCount(key) > previous) return true;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return tickCount(key) > previous;
  }

  void beginFrameRun(String key) {
    if (muted) return;
    _frameRuns.putIfAbsent(key, () => []);
    _frameRuns[key]!.add(<int>[]);
  }

  void recordFrameMicros(String key, int micros) {
    recordOperationMicros(key, micros);
    if (muted) return;
    final runs = _frameRuns[key];
    if (runs != null && runs.isNotEmpty) {
      runs.last.add(micros);
    }
  }

  void reset() {
    _rebuildCounts.clear();
    _operationTimesMicros.clear();
    _memoryValues.clear();
    _benchmarkRuns.clear();
    _ticks.clear();
    _frameRuns.clear();
  }

  int _percentile(List<int> sortedValues, double p) {
    if (sortedValues.isEmpty) return 0;
    final index = ((sortedValues.length - 1) * p).round();
    return sortedValues[index];
  }

  void _printTimeGroup(String label, Map<String, List<int>> times) {
    if (times.isEmpty) return;
    print('\n    $label:');
    times.forEach((operation, values) {
      final avg = values.reduce((a, b) => a + b) ~/ values.length;
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);
      print(
        '      $operation: avg ${_formatTimeValue(avg)} | '
        'min ${_formatTimeValue(min)} | '
        'max ${_formatTimeValue(max)} '
        '(${values.length} samples)',
      );
    });
  }

  String _formatTimeValue(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}s';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}ms';
    } else {
      return '$valueµs';
    }
  }

  void printSummary() {
    print('\n\n');
    print('=' * 70);
    print('  PERFORMANCE SUMMARY');
    print('=' * 70);

    if (_rebuildCounts.isNotEmpty) {
      print('\n  REBUILDS:');
      _rebuildCounts.forEach((widget, count) {
        print('    $widget: $count rebuilds');
      });
      print('');
    }

    if (_operationTimesMicros.isNotEmpty) {
      print('  OPERATION TIMES:');
      print('  ' + '-' * 60);

      final dbTimes = <String, List<int>>{};
      final processTimes = <String, List<int>>{};
      final frameTimes = <String, List<int>>{};

      _operationTimesMicros.forEach((key, value) {
        if (key.startsWith('DB_')) {
          dbTimes[key] = value;
        } else if (key.startsWith('SCROLL_') || key.startsWith('THEME_')) {
          frameTimes[key] = value;
        } else {
          processTimes[key] = value;
        }
      });

      _printTimeGroup('DATABASE', dbTimes);
      _printTimeGroup('PROCESSING', processTimes);

      if (frameTimes.isNotEmpty) {
        print('\n    FRAME TIMES — SCROLL / THEME (jank = frame > ${_formatTimeValue(kFrameBudgetMicros)}):');
        frameTimes.forEach((operation, times) {
          final sorted = List<int>.from(times)..sort();
          final avg = times.reduce((a, b) => a + b) ~/ times.length;
          final p90 = _percentile(sorted, 0.90);
          final p99 = _percentile(sorted, 0.99);
          final worst = sorted.last;
          final jank = times.where((t) => t > kFrameBudgetMicros).length;
          final runKey = operation.replaceFirst('_BUILD_', '_').replaceFirst('_RASTER_', '_');
          final runs = _benchmarkRuns[runKey];
          final runsLabel = runs != null ? ' | $runs run(s)' : '';
          print(
            '      $operation: avg ${_formatTimeValue(avg)} | '
            'p90 ${_formatTimeValue(p90)} | '
            'p99 ${_formatTimeValue(p99)} | '
            'worst ${_formatTimeValue(worst)} | '
            'jank $jank/${times.length} frames'
            '$runsLabel',
          );
        });
      }
    }

    if (_memoryValues.isNotEmpty) {
      print('\n  MEMORY USAGE (MB):');
      print('  ' + '-' * 60);
      _memoryValues.forEach((operation, values) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        final min = values.reduce((a, b) => a < b ? a : b);
        final max = values.reduce((a, b) => a > b ? a : b);
        print(
          '    $operation: avg ${avg.toStringAsFixed(2)}MB | '
          'min ${min.toStringAsFixed(2)}MB | '
          'max ${max.toStringAsFixed(2)}MB '
          '(${values.length} samples)',
        );
      });
    }

    print('\n' + '=' * 70);
    print('  END OF SUMMARY');
    print('=' * 70 + '\n\n');
  }

  List<String> exportJsonLines({required String session, required String approach, required String scenario}) {
    final lines = <String>[];

    final plainTimes = <String, List<int>>{};
    _operationTimesMicros.forEach((key, value) {
      if (_frameRuns.containsKey(key)) return;
      plainTimes[key] = value;
    });

    plainTimes.forEach((key, samples) {
      lines.addAll(
        _encodeSampleLines({
          'v': 1,
          'type': 'samples',
          'session': session,
          'approach': approach,
          'scenario': scenario,
          'key': key,
          'unit': 'us',
        }, samples),
      );
    });

    _frameRuns.forEach((key, runs) {
      for (var i = 0; i < runs.length; i++) {
        lines.addAll(
          _encodeSampleLines({
            'v': 1,
            'type': 'samples',
            'session': session,
            'approach': approach,
            'scenario': scenario,
            'key': key,
            'run': i + 1,
            'unit': 'us',
          }, runs[i]),
        );
      }
    });

    _memoryValues.forEach((key, values) {
      lines.addAll(
        _encodeSampleLines({
          'v': 1,
          'type': 'memory',
          'session': session,
          'approach': approach,
          'scenario': scenario,
          'key': key,
          'unit': 'MB',
        }, values),
      );
    });

    _rebuildCounts.forEach((key, count) {
      lines.add(
        _perfLine({
          'v': 1,
          'type': 'rebuilds',
          'session': session,
          'approach': approach,
          'scenario': scenario,
          'key': key,
          'count': count,
        }),
      );
    });

    _benchmarkRuns.forEach((key, count) {
      lines.add(
        _perfLine({
          'v': 1,
          'type': 'runs',
          'session': session,
          'approach': approach,
          'scenario': scenario,
          'key': key,
          'count': count,
        }),
      );
    });

    return lines;
  }

  String _perfLine(Map<String, dynamic> fields) => 'PERF ${jsonEncode(fields)}';

  List<String> _encodeSampleLines(Map<String, dynamic> base, List<num> samples) {
    if (samples.isEmpty) {
      return [_perfLine({...base, 'samples': const <num>[]})];
    }

    var chunkSize = samples.length;
    List<List<num>> chunks;
    while (true) {
      chunks = <List<num>>[];
      for (var i = 0; i < samples.length; i += chunkSize) {
        final end = (i + chunkSize < samples.length) ? i + chunkSize : samples.length;
        chunks.add(samples.sublist(i, end));
      }
      final probe = _perfLine({...base, 'samples': chunks.first});
      if (probe.length <= _maxJsonLineLength || chunkSize == 1) break;
      chunkSize = (chunkSize / 2).ceil();
    }

    if (chunks.length == 1) {
      return [_perfLine({...base, 'samples': chunks.first})];
    }

    return [
      for (var i = 0; i < chunks.length; i++)
        _perfLine({...base, 'part': i + 1, 'parts': chunks.length, 'samples': chunks[i]}),
    ];
  }
}
