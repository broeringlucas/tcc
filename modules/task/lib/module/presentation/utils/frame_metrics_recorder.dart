import 'package:common/main.dart';
import 'package:flutter/scheduler.dart';

class FrameMetricsRecorder {
  bool _active = false;
  String _buildKey = '';
  String _rasterKey = '';

  void attach() => SchedulerBinding.instance.addTimingsCallback(_onTimings);

  void detach() => SchedulerBinding.instance.removeTimingsCallback(_onTimings);

  void start(String prefix, String approachKey) {
    _buildKey = '${prefix}_BUILD_$approachKey';
    _rasterKey = '${prefix}_RASTER_$approachKey';
    _active = true;
    final tracker = PerformanceTracker();
    tracker.recordBenchmarkRun('${prefix}_$approachKey');
    tracker.beginFrameRun(_buildKey);
    tracker.beginFrameRun(_rasterKey);
  }

  void stop() => _active = false;

  void _onTimings(List<FrameTiming> timings) {
    if (!_active) return;
    final tracker = PerformanceTracker();
    for (final timing in timings) {
      tracker.recordFrameMicros(_buildKey, timing.buildDuration.inMicroseconds);
      tracker.recordFrameMicros(_rasterKey, timing.rasterDuration.inMicroseconds);
    }
  }
}
