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
  }

  void stop() => _active = false;

  void _onTimings(List<FrameTiming> timings) {
    if (!_active) return;
    final tracker = PerformanceTracker();
    for (final timing in timings) {
      tracker.recordOperationMicros(_buildKey, timing.buildDuration.inMicroseconds);
      tracker.recordOperationMicros(_rasterKey, timing.rasterDuration.inMicroseconds);
    }
  }
}
