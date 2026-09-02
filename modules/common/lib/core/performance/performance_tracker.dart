import 'dart:io';

class PerformanceTracker {
  static final PerformanceTracker _instance = PerformanceTracker._internal();
  factory PerformanceTracker() => _instance;
  PerformanceTracker._internal();

  final Map<String, int> _rebuildCounts = {};
  final Map<String, List<int>> _operationTimesMicros = {};
  final Map<String, List<double>> _memoryValues = {};

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

  void recordMemory(String operationName, double memoryMB) {
    _memoryValues.putIfAbsent(operationName, () => []);
    _memoryValues[operationName]!.add(memoryMB);
  }

  void reset() {
    _rebuildCounts.clear();
    _operationTimesMicros.clear();
    _memoryValues.clear();
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

      _operationTimesMicros.forEach((key, value) {
        if (key.startsWith('DB_')) {
          dbTimes[key] = value;
        } else {
          processTimes[key] = value;
        }
      });

      if (dbTimes.isNotEmpty) {
        print('\n    DATABASE:');
        dbTimes.forEach((operation, times) {
          final avg = times.reduce((a, b) => a + b) ~/ times.length;
          final min = times.reduce((a, b) => a < b ? a : b);
          final max = times.reduce((a, b) => a > b ? a : b);
          print(
            '      $operation: avg ${_formatTimeValue(avg)} | '
            'min ${_formatTimeValue(min)} | '
            'max ${_formatTimeValue(max)} '
            '(${times.length} samples)',
          );
        });
      }

      if (processTimes.isNotEmpty) {
        print('\n    PROCESSING:');
        processTimes.forEach((operation, times) {
          final avg = times.reduce((a, b) => a + b) ~/ times.length;
          final min = times.reduce((a, b) => a < b ? a : b);
          final max = times.reduce((a, b) => a > b ? a : b);
          print(
            '      $operation: avg ${_formatTimeValue(avg)} | '
            'min ${_formatTimeValue(min)} | '
            'max ${_formatTimeValue(max)} '
            '(${times.length} samples)',
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
}
