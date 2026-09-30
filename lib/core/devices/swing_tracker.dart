/// Положение качающегося вентилятора, вычисленное по времени.
///
/// Положение — доля дуги качания: 0 — один край, 1 — другой. Вентилятор
/// проходит дугу за [sweep] с постоянной скоростью, у каждого края замирает
/// на [dwell] и идёт обратно. Полный цикл:
/// вверх (sweep) → пауза у 1 (dwell) → вниз (sweep) → пауза у 0 (dwell).
class SwingTracker {
  SwingTracker(this.sweep, {this.dwell = Duration.zero});

  /// Время прохода от края до края.
  Duration sweep;

  /// Сколько вентилятор стоит у края перед разворотом.
  Duration dwell;

  /// Место в цикле, микросекунды от начала движения вверх от края 0.
  double? _cycle;

  /// Когда вентилятор начал движение от [_cycle]; `null` — стоит.
  DateTime? _since;

  double get _sweep => sweep.inMicroseconds.toDouble();
  double get _dwell => dwell.inMicroseconds.toDouble();
  double get _period => 2 * (_sweep + _dwell);

  bool get known => _cycle != null;
  bool get moving => known && _since != null;

  /// Вентилятор дошёл до края [edge] (0 или 1) и замер перед разворотом.
  void reachedEdge(int edge, DateTime at) =>
      _set(edge == 1 ? _sweep : 2 * _sweep + _dwell, at);

  /// Вентилятор тронулся от края [edge] в обратную сторону.
  void leftEdge(int edge, DateTime at) =>
      _set(edge == 1 ? _sweep + _dwell : 0, at);

  void stop(DateTime at) {
    _cycle = _cycleAt(at);
    _since = null;
  }

  /// Продолжает движение в текущую сторону; разворот — [reverse].
  void resume(DateTime at) {
    if (known) _since = at;
  }

  /// Вентилятор идёт (или пойдёт после остановки) в обратную сторону —
  /// с того же места.
  void reverse(DateTime at) {
    final cycle = _cycleAt(at);
    if (cycle == null) return;
    _cycle = _mirror(cycle);
    if (_since != null) _since = at;
  }

  /// Движение от места [cycle], начатое в [since] и законченное в [until],
  /// на самом деле шло в обратную сторону: пересчитываем, где вентилятор
  /// остановился.
  void replayReversed(double cycle, DateTime since, DateTime until) {
    final travelled = until.difference(since).inMicroseconds;
    _cycle = (_mirror(cycle) + travelled) % _period;
    _since = null;
  }

  /// Место в цикле и начало движения — чтобы сохранить и восстановить.
  ({double cycle, DateTime? since})? get state {
    final cycle = _cycle;
    return cycle == null ? null : (cycle: cycle, since: _since);
  }

  void restore(double cycle, DateTime? since) => _set(cycle, since);

  void forget() => _set(null, null);

  double? positionAt(DateTime at) {
    final cycle = _cycleAt(at);
    return cycle == null ? null : _positionOf(cycle);
  }

  /// Через сколько вентилятор окажется в [target], если продолжит движение.
  Duration? timeTo(double target, DateTime now) {
    final cycle = _cycleAt(now);
    if (cycle == null) return null;
    final up = target * _sweep;
    final down = _sweep + _dwell + (1 - target) * _sweep;
    final candidates = [up, down, up + _period, down + _period];
    final next = candidates.where((c) => c >= cycle).reduce(_min);
    return Duration(microseconds: (next - cycle).round());
  }

  void _set(double? cycle, DateTime? since) {
    _cycle = cycle;
    _since = since;
  }

  double _positionOf(double cycle) {
    if (cycle < _sweep) return cycle / _sweep;
    if (cycle < _sweep + _dwell) return 1;
    if (cycle < 2 * _sweep + _dwell) {
      return 1 - (cycle - _sweep - _dwell) / _sweep;
    }
    return 0;
  }

  /// То же место, но движение в обратную сторону. Во время паузы у края
  /// разворачиваться некуда — место не меняется.
  double _mirror(double cycle) {
    final moving =
        cycle < _sweep ||
        (cycle >= _sweep + _dwell && cycle < 2 * _sweep + _dwell);
    return moving ? 2 * _sweep + _dwell - cycle : cycle;
  }

  double? _cycleAt(DateTime at) {
    final cycle = _cycle;
    final since = _since;
    if (cycle == null || since == null || _sweep <= 0) return cycle;
    return (cycle + at.difference(since).inMicroseconds) % _period;
  }

  static double _min(double a, double b) => a < b ? a : b;
}
