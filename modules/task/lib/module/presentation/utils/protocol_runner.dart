import 'dart:convert';
import 'dart:io';

import 'package:common/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ProtocolHooks {
  final String approachKey;
  final void Function(int count) load;
  final void Function(String query) search;
  final Future<int> Function() runScroll;
  final Future<int> Function() runTheme;

  const ProtocolHooks({
    required this.approachKey,
    required this.load,
    required this.search,
    required this.runScroll,
    required this.runTheme,
  });
}

class ProtocolRunner {
  static const bool _quick = bool.fromEnvironment('AUTO_QUICK');

  static const List<int> _loadVolumes = [1000, 10000, 100000];
  static const int _loadSamples = _quick ? 2 : 20;
  static const int _searchSamples = _quick ? 2 : 20;
  static const int _loadSettleDelayMs = 150;
  static const int _searchSettleDelayMs = 300;
  static const String _searchQuery = '500';
  static const int _searchListSize = 10000;
  static const int _scrollListSize = 10000;
  static const Duration _tickTimeout = Duration(seconds: 30);

  final ProtocolHooks hooks;
  final String session;
  final String order;
  final int position;
  final String flutterVersion;

  ProtocolRunner({required this.hooks, String? session, String? order, int? position, String? flutterVersion})
    : session = session ?? const String.fromEnvironment('SESSION_ID', defaultValue: 'local'),
      order = order ?? const String.fromEnvironment('RUN_ORDER', defaultValue: ''),
      position = position ?? const int.fromEnvironment('RUN_POSITION', defaultValue: 0),
      flutterVersion = flutterVersion ?? const String.fromEnvironment('APP_FLUTTER_VERSION', defaultValue: 'unknown');

  Future<void> run() async {
    if (kDebugMode) {
      print(
        '[ProtocolRunner] Rodando em modo debug — o protocolo automático só é válido em '
        '--profile ou --release (tempos de banco/frame não são representativos em debug). '
        'Abortando sem coletar nada.',
      );
      return;
    }

    _emitLine({
      'v': 1,
      'type': 'meta',
      'session': session,
      'approach': hooks.approachKey,
      'mode': 'profile',
      'order': order,
      'position': position,
      'flutter': flutterVersion,
    });

    final tracker = PerformanceTracker();

    if (!await _runLoadScenario(tracker)) return;
    if (!await _runSearchScenario(tracker)) return;
    if (!await _runScrollScenario(tracker)) return;
    if (!await _runThemeScenario(tracker)) return;

    _emitLine({'v': 1, 'type': 'done', 'session': session, 'approach': hooks.approachKey});

    await Future<void>.delayed(const Duration(milliseconds: 300));
    SystemNavigator.pop();
    await Future<void>.delayed(const Duration(seconds: 1));
    exit(0);
  }

  Future<bool> _runLoadScenario(PerformanceTracker tracker) async {
    tracker.reset();

    for (final count in _loadVolumes) {
      final key = 'AFTER_all_$count';

      final warmupOk = await _muted(tracker, () => _loadOnce(tracker, count, key));
      if (!warmupOk) {
        _emitError('load', 'warmup timeout for $key');
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: _loadSettleDelayMs));

      for (var i = 0; i < _loadSamples; i++) {
        final ok = await _loadOnce(tracker, count, key);
        if (!ok) {
          _emitError('load', 'timeout for $key (sample $i)');
          return false;
        }
        await Future<void>.delayed(const Duration(milliseconds: _loadSettleDelayMs));
      }
    }

    tracker.printSummary();
    _exportAndEmit(tracker, 'load');
    return true;
  }

  Future<bool> _runSearchScenario(PerformanceTracker tracker) async {
    tracker.reset();

    final setupOk = await _muted(tracker, () => _loadOnce(tracker, _searchListSize, 'AFTER_all_$_searchListSize'));
    if (!setupOk) {
      _emitError('busca', 'timeout loading $_searchListSize tasks for setup');
      return false;
    }

    final warmupOk = await _muted(tracker, () => _searchRound(tracker));
    if (!warmupOk) {
      _emitError('busca', 'warmup timeout');
      return false;
    }

    for (var i = 0; i < _searchSamples; i++) {
      final ok = await _searchRound(tracker);
      if (!ok) {
        _emitError('busca', 'timeout (sample $i)');
        return false;
      }
    }

    tracker.printSummary();
    _exportAndEmit(tracker, 'busca');
    return true;
  }

  Future<bool> _runScrollScenario(PerformanceTracker tracker) async {
    tracker.reset();

    final ok = await _muted(tracker, () => _loadOnce(tracker, _scrollListSize, 'AFTER_all_$_scrollListSize'));
    if (!ok) {
      _emitError('scroll', 'timeout loading $_scrollListSize tasks');
      return false;
    }

    await hooks.runScroll();

    tracker.printSummary();
    _exportAndEmit(tracker, 'scroll');
    return true;
  }

  Future<bool> _runThemeScenario(PerformanceTracker tracker) async {
    tracker.reset();
    await hooks.runTheme();

    tracker.printSummary();
    _exportAndEmit(tracker, 'tema');
    return true;
  }

  Future<bool> _muted(PerformanceTracker tracker, Future<bool> Function() action) async {
    tracker.muted = true;
    try {
      return await action();
    } finally {
      tracker.muted = false;
    }
  }

  Future<bool> _loadOnce(PerformanceTracker tracker, int count, String key) async {
    final previous = tracker.tickCount(key);
    hooks.load(count);
    return tracker.waitForTick(key, previous, timeout: _tickTimeout);
  }

  Future<bool> _searchOnce(PerformanceTracker tracker, String query, String key) async {
    final previous = tracker.tickCount(key);
    hooks.search(query);
    return tracker.waitForTick(key, previous, timeout: _tickTimeout);
  }

  Future<bool> _searchRound(PerformanceTracker tracker) async {
    if (!await _searchOnce(tracker, _searchQuery, 'SEARCH_${_searchQuery}_tasks')) return false;
    await Future<void>.delayed(const Duration(milliseconds: _searchSettleDelayMs));
    if (!await _searchOnce(tracker, '', 'SEARCH_empty_tasks')) return false;
    return true;
  }

  void _exportAndEmit(PerformanceTracker tracker, String scenario) {
    final lines = tracker.exportJsonLines(session: session, approach: hooks.approachKey, scenario: scenario);
    for (final line in lines) {
      print(line);
    }
  }

  void _emitError(String scenario, String message) {
    _emitLine({
      'v': 1,
      'type': 'error',
      'session': session,
      'approach': hooks.approachKey,
      'scenario': scenario,
      'message': message,
    });
  }

  void _emitLine(Map<String, dynamic> fields) => print('PERF ${jsonEncode(fields)}');
}
