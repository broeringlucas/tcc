import 'dart:async';
import 'dart:ui';

class DebounceUtil {
  final Duration duration;
  Timer? _timer;

  DebounceUtil({this.duration = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, () {
      action();
      _timer = null;
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}
