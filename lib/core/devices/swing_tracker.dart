/// Положение качающегося вентилятора, вычисленное по времени.
///
/// Положение — доля дуги качания: 0 — один край, 1 — другой. Считается,
/// что вентилятор движется с постоянной скоростью, проходит дугу за [sweep]
/// и у края сразу разворачивается.
class SwingTracker {
  SwingTracker(this.sweep);

  /// Время прохода от края до края.
  Duration sweep;

  /// Фаза: 0…1 — путь к краю 1, 1…2 — обратно к краю 0.
  double? _phase;

  /// Когда вентилятор начал движение от фазы [_phase]; `null` — стоит.
  DateTime? _since;

  bool get known => _phase != null;
  bool get moving => known && _since != null;

  /// Вентилятор дошёл до края [edge] (0 или 1) и развернулся.
  void reachedEdge(int edge, DateTime at) {
    _phase = edge == 1 ? 1 : 0;
    _since = at;
  }

  void stop(DateTime at) {
    _phase = _phaseAt(at);
    _since = null;
  }

  /// Продолжает движение в текущую сторону; разворот — [reverse].
  void resume(DateTime at) {
    if (known) _since = at;
  }

  /// Вентилятор идёт (или пойдёт после остановки) в обратную сторону —
  /// с того же места.
  void reverse(DateTime at) {
    final phase = _phaseAt(at);
    if (phase == null) return;
    _phase = (2 - phase) % 2;
    if (_since != null) _since = at;
  }

  /// Фаза и начало движения — чтобы сохранить и восстановить положение.
  ({double phase, DateTime? since})? get state {
    final phase = _phase;
    return phase == null ? null : (phase: phase, since: _since);
  }

  void restore(double phase, DateTime? since) {
    _phase = phase;
    _since = since;
  }

  /// Движение от фазы [phase], начатое в [since] и законченное в [until],
  /// на самом деле шло в обратную сторону: пересчитываем, где вентилятор
  /// остановился.
  void replayReversed(double phase, DateTime since, DateTime until) {
    final travelled =
        until.difference(since).inMicroseconds / sweep.inMicroseconds;
    _phase = ((2 - phase) % 2 + travelled) % 2;
    _since = null;
  }

  void forget() {
    _phase = null;
    _since = null;
  }

  double? positionAt(DateTime at) {
    final phase = _phaseAt(at);
    if (phase == null) return null;
    return phase <= 1 ? phase : 2 - phase;
  }

  /// Через сколько вентилятор окажется в [target], если продолжит движение.
  Duration? timeTo(double target, DateTime now) {
    final phase = _phaseAt(now);
    if (phase == null) return null;
    final candidates = [target, 2 - target, target + 2, 4 - target];
    final next = candidates.where((c) => c >= phase).reduce(_min);
    return sweep * (next - phase);
  }

  double? _phaseAt(DateTime at) {
    final phase = _phase;
    final since = _since;
    if (phase == null || since == null || sweep <= Duration.zero) return phase;
    final travelled =
        at.difference(since).inMicroseconds / sweep.inMicroseconds;
    return (phase + travelled) % 2;
  }

  static double _min(double a, double b) => a < b ? a : b;
}
