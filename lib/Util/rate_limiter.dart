import 'dart:async';

class RateLimiter {
  final Duration interval;
  Timer? _timer;
  bool _isReady = true;

  RateLimiter({required this.interval});

  bool get isReady => _isReady;

  void reset() {
    _isReady = false;
    _timer?.cancel();
    _timer = Timer(interval, () {
      _isReady = true;
    });
  }
}
