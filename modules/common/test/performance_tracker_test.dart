import 'dart:async';
import 'dart:convert';

import 'package:common/main.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _capturePrints(void Function() action) {
  final captured = <String>[];
  runZoned(action, zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) => captured.add(line)));
  return captured;
}

void main() {
  late PerformanceTracker tracker;

  setUp(() {
    tracker = PerformanceTracker();
    tracker.reset();
    tracker.muted = false;
  });

  test('muted: nada é gravado, mas os ticks continuam subindo', () {
    tracker.muted = true;
    tracker.recordOperationMicros('OP_A', 100);
    tracker.recordMemory('MEM_A', 10.0);
    tracker.recordRebuildWithContext('REBUILD_x');
    tracker.recordBenchmarkRun('RUN_x');
    tracker.muted = false;

    expect(tracker.tickCount('OP_A'), 1);
    expect(tracker.tickCount('MEM_A'), 1);
    expect(tracker.getRebuildCount('REBUILD_x'), 0);

    final lines = tracker.exportJsonLines(session: 's', approach: 'a', scenario: 'sc');
    expect(lines.where((l) => l.contains('"key":"OP_A"')), isEmpty);
    expect(lines.where((l) => l.contains('"key":"MEM_A"')), isEmpty);
    expect(lines.where((l) => l.contains('"key":"RUN_x"')), isEmpty);
  });

  test('depois de desmutar, as gravações voltam a contar normalmente', () {
    tracker.muted = true;
    tracker.recordOperationMicros('OP_A', 100);
    tracker.muted = false;
    tracker.recordOperationMicros('OP_A', 200);

    expect(tracker.tickCount('OP_A'), 2);
    final lines = tracker.exportJsonLines(session: 's', approach: 'a', scenario: 'sc');
    final line = lines.firstWhere((l) => l.contains('"key":"OP_A"'));
    expect(line, contains('[200]'));
  });

  test('waitForTick resolve quando o tick avança', () async {
    final previous = tracker.tickCount('OP_B');
    Future<void>.delayed(const Duration(milliseconds: 50), () => tracker.recordOperationMicros('OP_B', 1));

    final ok = await tracker.waitForTick('OP_B', previous, timeout: const Duration(seconds: 2));

    expect(ok, isTrue);
    expect(tracker.tickCount('OP_B'), previous + 1);
  });

  test('waitForTick expira se o tick nunca avançar', () async {
    final previous = tracker.tickCount('OP_C');

    final ok = await tracker.waitForTick('OP_C', previous, timeout: const Duration(milliseconds: 100));

    expect(ok, isFalse);
  });

  test('beginFrameRun/recordFrameMicros separam amostras por execução e agregam igual à soma', () {
    tracker.beginFrameRun('SCROLL_BUILD_x');
    tracker.recordFrameMicros('SCROLL_BUILD_x', 100);
    tracker.recordFrameMicros('SCROLL_BUILD_x', 200);

    tracker.beginFrameRun('SCROLL_BUILD_x');
    tracker.recordFrameMicros('SCROLL_BUILD_x', 300);

    final lines = tracker.exportJsonLines(session: 's', approach: 'a', scenario: 'scroll');
    final runLines = lines.where((l) => l.contains('"key":"SCROLL_BUILD_x"')).toList();
    expect(runLines.length, 2);
    expect(runLines[0], contains('"run":1'));
    expect(runLines[0], contains('[100,200]'));
    expect(runLines[1], contains('"run":2'));
    expect(runLines[1], contains('[300]'));

    expect(tracker.tickCount('SCROLL_BUILD_x'), 3);

    final output = _capturePrints(() => tracker.printSummary()).join('\n');
    expect(output, contains('avg 200µs'));
  });

  test('exportJsonLines devolve linhas com prefixo PERF e JSON válido', () {
    tracker.recordOperationMicros('DB_all_1000', 500);
    tracker.recordMemory('BEFORE_all_1000', 12.5);
    tracker.recordRebuildWithContext('REBUILD_bloc');
    tracker.recordBenchmarkRun('SCROLL_bloc');

    final lines = tracker.exportJsonLines(session: 's1', approach: 'bloc', scenario: 'load');

    expect(lines, isNotEmpty);
    for (final line in lines) {
      expect(line, startsWith('PERF '));
      final decoded = jsonDecode(line.substring('PERF '.length));
      expect(decoded, isA<Map<String, dynamic>>());
      expect(decoded['v'], 1);
      expect(decoded['session'], 's1');
      expect(decoded['approach'], 'bloc');
    }
  });

  test('exportJsonLines divide amostras grandes em várias linhas com part/parts', () {
    for (var i = 0; i < 2000; i++) {
      tracker.recordOperationMicros('DB_all_100000', i);
    }

    final lines = tracker.exportJsonLines(session: 's1', approach: 'bloc', scenario: 'load');
    final dbLines = lines.where((l) => l.contains('"key":"DB_all_100000"')).toList();

    expect(dbLines.length, greaterThan(1));
    for (final line in dbLines) {
      expect(line.length, lessThanOrEqualTo(900));
      final decoded = jsonDecode(line.substring('PERF '.length)) as Map<String, dynamic>;
      expect(decoded['part'], isNotNull);
      expect(decoded['parts'], dbLines.length);
    }
  });

  test('exportJsonLines mantém linhas dentro do limite do logcat e reconstrói as amostras originais', () {
    final originalSamples = List<int>.generate(400, (i) => 10000 + i);
    for (final sample in originalSamples) {
      tracker.recordOperationMicros('DB_all_100000', sample);
    }

    final lines = tracker.exportJsonLines(session: 's1', approach: 'bloc', scenario: 'load');
    final dbLines = lines.where((l) => l.contains('"key":"DB_all_100000"')).toList();

    for (final line in dbLines) {
      expect(line.length, lessThanOrEqualTo(900));
    }

    final decodedParts = dbLines.map((l) => jsonDecode(l.substring('PERF '.length)) as Map<String, dynamic>).toList()
      ..sort((a, b) => (a['part'] as int).compareTo(b['part'] as int));

    final reconstructed = <int>[];
    for (final part in decodedParts) {
      expect(part['n'], originalSamples.length);
      reconstructed.addAll((part['samples'] as List).cast<int>());
    }

    expect(reconstructed, originalSamples);
  });
}
