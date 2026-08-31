import 'dart:io';

class PerformanceTracker {
  static final PerformanceTracker _instance = PerformanceTracker._internal();
  factory PerformanceTracker() => _instance;
  PerformanceTracker._internal();

  final Map<String, int> _rebuildCounts = {};
  final Map<String, List<int>> _operationTimesMicros = {};
  final Map<String, List<double>> _memoryUsage = {};

  void recordRebuild(String widgetName) {
    _rebuildCounts[widgetName] = (_rebuildCounts[widgetName] ?? 0) + 1;
  }

  void recordRebuildWithContext(String context) {
    _rebuildCounts[context] = (_rebuildCounts[context] ?? 0) + 1;
  }

  int getRebuildCount(String widgetName) {
    return _rebuildCounts[widgetName] ?? 0;
  }

  void recordOperationMicros(String operationName, int durationMicros) {
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

  void recordMemoryDelta(String operationName, double beforeMB, double afterMB) {
    final delta = afterMB - beforeMB;
    _memoryUsage.putIfAbsent(operationName, () => []);
    _memoryUsage[operationName]!.add(delta);
  }

  void reset() {
    _rebuildCounts.clear();
    _operationTimesMicros.clear();
    _memoryUsage.clear();
  }

  void printSummary() {
    print('\n' + '=' * 50);
    print('PERFORMANCE SUMMARY');
    print('=' * 50);

    print('\n--- REBUILD COUNTS ---');
    if (_rebuildCounts.isEmpty) {
      print('No rebuilds recorded');
    } else {
      _rebuildCounts.forEach((widget, count) {
        print('$widget: $count rebuilds');
      });
    }

    print('\n--- OPERATION TIMES (µs) ---');
    if (_operationTimesMicros.isEmpty) {
      print('No operations recorded');
    } else {
      final sortedKeys = _operationTimesMicros.keys.toList()..sort();
      for (final operation in sortedKeys) {
        final times = _operationTimesMicros[operation]!;
        final avg = times.reduce((a, b) => a + b) ~/ times.length;
        final min = times.reduce((a, b) => a < b ? a : b);
        final max = times.reduce((a, b) => a > b ? a : b);
        print('$operation: avg ${avg}µs | min ${min}µs | max ${max}µs (${times.length} samples)');
      }
    }

    print('\n--- MEMORY USAGE (MB) ---');
    if (_memoryUsage.isEmpty) {
      print('No memory data recorded');
    } else {
      _memoryUsage.forEach((operation, values) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        final min = values.reduce((a, b) => a < b ? a : b);
        final max = values.reduce((a, b) => a > b ? a : b);
        print(
          '$operation: avg ${avg.toStringAsFixed(2)}MB | min ${min.toStringAsFixed(2)}MB | max ${max.toStringAsFixed(2)}MB (${values.length} samples)',
        );
      });
    }

    print('\n' + '=' * 50);
    print('END OF SUMMARY');
    print('=' * 50 + '\n');
  }
}
