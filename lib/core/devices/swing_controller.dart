import 'dart:async';

import 'package:flutter/foundation.dart';

import '../spec/miot_spec.dart';
import 'device_controller.dart';
import 'swing_tracker.dart';

/// Где хранить калибровку и положение, чтобы не калибровать заново
/// после перезапуска приложения.
abstract interface class SwingCalibrations {
  Duration? swingSweep(String did);
  void saveSwingSweep(String did, Duration sweep);
  Duration? swingDwell(String did);
  void saveSwingDwell(String did, Duration dwell);
  SwingSnapshot? swingState(String did);
  void saveSwingState(String did, SwingSnapshot? state);
}

/// Сохранённое положение вентилятора.
class SwingSnapshot {
  const SwingSnapshot({
    required this.cycle,
    required this.since,
    required this.stoppedAt,
    required this.reverseAfter,
  });

  /// `null` — сохранено в старом формате, который уже не подходит.
  static SwingSnapshot? fromJson(Map<String, dynamic> json) {
    final cycle = json['cycle'];
    if (cycle is! num) return null;
    return SwingSnapshot(
      cycle: cycle.toDouble(),
      since: _time(json['since']),
      stoppedAt: _time(json['stoppedAt']),
      reverseAfter: Duration(milliseconds: json['reverseAfter'] as int),
    );
  }

  /// Место в цикле качания, микросекунды.
  final double cycle;

  /// Когда начал движение; `null` — стоял.
  final DateTime? since;
  final DateTime? stoppedAt;
  final Duration reverseAfter;

  Map<String, dynamic> toJson() => {
    'cycle': cycle,
    'since': since?.millisecondsSinceEpoch,
    'stoppedAt': stoppedAt?.millisecondsSinceEpoch,
    'reverseAfter': reverseAfter.inMilliseconds,
  };

  static DateTime? _time(Object? ms) =>
      ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
}

/// Поворот вентилятора в нужную сторону там, где есть только
/// «качаться / стоять». Положение вычисляется по времени после калибровки.
class SwingController extends ChangeNotifier {
  SwingController(
    this._device, {
    SwingCalibrations? calibrations,
    DateTime Function()? clock,
  }) : _calibrations = calibrations,
       _now = clock ?? DateTime.now,
       _tracker = SwingTracker(
         calibrations?.swingSweep(_device.device.did) ?? Duration.zero,
         dwell: calibrations?.swingDwell(_device.device.did) ?? Duration.zero,
       ) {
    _device.addListener(_watchSwing);
    _restore();
  }

  /// Дольше этого качания без приложения расчёт по времени слишком
  /// расходится с настоящим положением.
  static const _maxUnwatchedSwing = Duration(minutes: 2);

  /// Проход короче этого — случайное нажатие, а не движение по дуге.
  static const minSweep = Duration(milliseconds: 700);

  /// Дольше этого вентилятор у края не стоит — значит, кнопку держали
  /// не во время паузы.
  static const _maxDwell = Duration(seconds: 6);

  /// Проход дольше этого — кнопку другого края нажали не сразу.
  static const _maxSweep = Duration(seconds: 60);

  /// Когда и у какого края отпустили кнопку: для замера паузы у края.
  ({int edge, DateTime at})? _lastRelease;

  /// Сколько после своей команды не верить чужому состоянию качания:
  /// опрос мог уйти до команды и вернуть старое значение.
  static const _settle = Duration(seconds: 5);

  final DeviceController _device;
  final SwingCalibrations? _calibrations;
  final DateTime Function() _now;
  final SwingTracker _tracker;

  /// Задержка между отправкой команды и реакцией вентилятора.
  Duration _latency = const Duration(milliseconds: 300);
  DateTime? _holdStart;

  /// Кнопку какого края держат: 0 — нижнего, 1 — верхнего.
  int? holdingEdge;
  DateTime _lastCommand = DateTime.fromMillisecondsSinceEpoch(0);
  bool? _expectedSwing;
  Timer? _stopTimer;

  /// Пауза, после которой вентилятор разворачивает качание. Уточняется,
  /// когда пользователь нажимает «Не туда».
  Duration reverseAfter = const Duration(milliseconds: 3500);
  DateTime? _stoppedAt;
  Duration? _lastPause;
  bool? _predictedReverse;

  /// Куда поворачиваем сейчас; `null` — никуда.
  double? target;

  MiotProperty? get _swing => _device.spec?.property('horizontal-swing');

  bool get supported => _swing?.isSwitch ?? false;
  bool get calibrated => _tracker.sweep > Duration.zero;
  bool get moving => _tracker.moving;
  bool get holding => _holdStart != null;

  /// Сколько держат кнопку калибровки.
  Duration? get holdElapsed {
    final start = _holdStart;
    return start == null ? null : _now().difference(start);
  }

  Duration get sweep => _tracker.sweep;
  bool get swinging => _device.values[_swing?.id] == true;

  /// Положение 0…1; `null` — неизвестно.
  double? get position => calibrated ? _tracker.positionAt(_now()) : null;

  /// Идёт калибровка: качание включено, ждём нажатия кнопки края.
  bool calibrating = false;

  /// Начинает калибровку: включает качание, чтобы пользователь мог
  /// засечь проход от края до края.
  Future<void> startCalibration() async {
    _stopTimer?.cancel();
    target = null;
    _lastMove = null;
    calibrating = true;
    notifyListeners();
    if (!await _setSwing(true)) calibrating = false;
    notifyListeners();
  }

  /// Вентилятор дошёл до края [edge] и замер — пользователь зажал кнопку
  /// этого края. Если перед этим отпускали кнопку другого края, промежуток
  /// между отпусканием и нажатием — чистый проход от края до края.
  void holdStart(int edge) {
    _resultTimer?.cancel();
    holdResult = null;
    _holdStart = _now();
    holdingEdge = edge;
    _measureSweep(edge);
    if (calibrated) _tracker.reachedEdge(edge, _now());
    notifyListeners();
  }

  void _measureSweep(int edge) {
    final release = _lastRelease;
    _lastRelease = null;
    if (release == null || release.edge == edge) return;
    final sweep = _now().difference(release.at);
    if (sweep < minSweep || sweep > _maxSweep) {
      _sweepRejected = true;
      return;
    }
    _tracker.sweep = sweep;
    _calibrations?.saveSwingSweep(_device.device.did, sweep);
    calibrating = false;
    _stoppedAt = null;
    _expectedSwing = true;
  }

  /// Кнопку одного края отпустили — ждём, когда отметят другой край.
  bool get awaitingOtherEdge =>
      (calibrating || !calibrated) && _lastRelease != null && !holding;

  /// Пауза у края замерена хотя бы раз.
  bool get dwellMeasured => _tracker.dwell > Duration.zero;
  Duration get dwell => _tracker.dwell;

  /// Последний проход не засчитан: слишком короткий или слишком длинный.
  bool _sweepRejected = false;

  /// Вентилятор тронулся от края — кнопку отпустили. Время удержания —
  /// пауза у края.
  void holdEnd() {
    final start = _holdStart;
    final edge = holdingEdge;
    _holdStart = null;
    holdingEdge = null;
    if (start == null || edge == null) return;
    final dwell = _now().difference(start);
    final accepted = dwell <= _maxDwell && !_sweepRejected;
    _sweepRejected = false;
    if (dwell <= _maxDwell) _leaveEdge(edge, dwell);
    _showResult((edge: edge, accepted: accepted));
  }

  void _leaveEdge(int edge, Duration dwell) {
    _tracker.dwell = dwell;
    _calibrations?.saveSwingDwell(_device.device.did, dwell);
    _lastRelease = (edge: edge, at: _now());
    if (!calibrated) return;
    _tracker.leftEdge(edge, _now());
    _persist();
  }

  /// Итог последнего нажатия кнопки края — показывается пару секунд.
  ({int edge, bool accepted})? holdResult;
  Timer? _resultTimer;

  void _showResult(({int edge, bool accepted}) result) {
    holdResult = result;
    _resultTimer?.cancel();
    _resultTimer = Timer(const Duration(milliseconds: 2500), () {
      holdResult = null;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Поворачивает к [position]: включает качание и выключает его,
  /// когда вентилятор окажется в нужном месте.
  Future<void> moveTo(double position) async {
    _stopTimer?.cancel();
    target = position.clamp(0.0, 1.0);
    notifyListeners();
    if (this.position == null) return;
    if (!_tracker.moving && !await _resume()) return;
    _rememberMove();
    _scheduleStop();
  }

  /// Можно ли нажать «Поехал не туда»: во время поворота или после него.
  bool get canRetry =>
      (target != null && _tracker.moving) || _lastMove?.stoppedAt != null;

  /// Вентилятор поехал не в ту сторону: считаем, что он развернулся
  /// на месте, и пересчитываем, когда остановить. Заодно уточняем,
  /// после какой паузы прошивка разворачивает качание.
  void retry() {
    if (target != null && _tracker.moving) return _retryMoving();
    final move = _lastMove;
    final stoppedAt = move?.stoppedAt;
    if (move == null || stoppedAt == null) return;
    // Уже остановился не там: он шёл в обратную сторону всё это время.
    _tracker.replayReversed(move.cycle, move.since, stoppedAt);
    _stoppedAt = stoppedAt;
    _learnReversal();
    _persist();
    moveTo(move.target);
  }

  void _retryMoving() {
    _tracker.reverse(_now());
    _learnReversal();
    _rememberMove();
    _persist();
    _scheduleStop();
    notifyListeners();
  }

  /// Откуда и куда поехали — чтобы исправить, если поехали не туда.
  ({double cycle, DateTime since, double target, DateTime? stoppedAt})?
  _lastMove;

  void _rememberMove() {
    final state = _tracker.state;
    final since = state?.since;
    if (state == null || since == null) return;
    _lastMove = (
      cycle: state.cycle,
      since: since,
      target: target!,
      stoppedAt: null,
    );
  }

  void _scheduleStop() {
    _stopTimer?.cancel();
    final wait = _tracker.timeTo(target!, _now())! - _latency;
    _stopTimer = Timer(wait.isNegative ? Duration.zero : wait, _stop);
  }

  /// Ошиблись с разворотом после паузы [_lastPause] — сдвигаем порог так,
  /// чтобы в следующий раз такая пауза дала верный прогноз.
  void _learnReversal() {
    final pause = _lastPause;
    final predicted = _predictedReverse;
    if (pause == null || predicted == null) return;
    reverseAfter = predicted
        ? _longer(reverseAfter, pause + const Duration(milliseconds: 200))
        : _shorter(reverseAfter, pause);
    _predictedReverse = !predicted;
  }

  static Duration _longer(Duration a, Duration b) => a > b ? a : b;
  static Duration _shorter(Duration a, Duration b) => a < b ? a : b;

  @override
  void dispose() {
    _stopTimer?.cancel();
    _resultTimer?.cancel();
    _device.removeListener(_watchSwing);
    super.dispose();
  }

  /// Восстанавливает положение после перезапуска. Если с тех пор качание
  /// включали или выключали без приложения, [_watchSwing] его сбросит.
  void _restore() {
    final saved = _calibrations?.swingState(_device.device.did);
    if (saved == null || !calibrated) return;
    final since = saved.since;
    final tooLong =
        since != null && _now().difference(since) > _maxUnwatchedSwing;
    if (tooLong) return;
    _tracker.restore(saved.cycle, since);
    _stoppedAt = saved.stoppedAt;
    reverseAfter = saved.reverseAfter;
    _expectedSwing = since != null;
    // Состояние устройства могло прийти раньше, чем открыли панель.
    _watchSwing();
  }

  void _persist() {
    final state = _tracker.state;
    _calibrations?.saveSwingState(
      _device.device.did,
      state == null
          ? null
          : SwingSnapshot(
              cycle: state.cycle,
              since: state.since,
              stoppedAt: _stoppedAt,
              reverseAfter: reverseAfter,
            ),
    );
  }

  /// После короткой паузы вентилятор продолжает в ту же сторону,
  /// после долгой — разворачивается (так ведёт себя прошивка p44).
  Future<bool> _resume() async {
    final sent = _now();
    final stoppedAt = _stoppedAt;
    final pause = stoppedAt == null
        ? Duration.zero
        : sent.difference(stoppedAt);
    final reverse = stoppedAt != null && pause >= reverseAfter;
    if (!await _setSwing(true)) return false;
    if (reverse) _tracker.reverse(sent);
    _tracker.resume(sent.add(_latency));
    _lastPause = stoppedAt == null ? null : pause;
    _predictedReverse = reverse;
    _persist();
    return true;
  }

  Future<void> _stop() async {
    final sent = _now();
    if (await _setSwing(false)) {
      _tracker.stop(sent.add(_latency));
      _stoppedAt = sent.add(_latency);
      final move = _lastMove;
      if (move != null) {
        _lastMove = (
          cycle: move.cycle,
          since: move.since,
          target: move.target,
          stoppedAt: _stoppedAt,
        );
      }
      _persist();
    }
    target = null;
    notifyListeners();
  }

  Future<bool> _setSwing(bool on) async {
    final swing = _swing;
    if (swing == null) return false;
    final sent = _now();
    final previous = _expectedSwing;
    // До отправки: иначе своё же изменение примем за чужое.
    _lastCommand = sent;
    _expectedSwing = on;
    await _device.setValue(swing, on);
    final ok = _device.error == null;
    if (ok) {
      _latency = _now().difference(sent) ~/ 2;
    } else {
      _expectedSwing = previous;
    }
    return ok;
  }

  /// Качание включили или выключили не мы (кнопкой на вентиляторе,
  /// в Mi Home) — вычисленному положению больше верить нельзя.
  void _watchSwing() {
    final actual = _device.values[_swing?.id];
    if (actual is! bool || holding) return;
    final ours = _now().difference(_lastCommand) < _settle;
    final changedElsewhere =
        !ours && _expectedSwing != null && actual != _expectedSwing;
    _expectedSwing = actual;
    if (!changedElsewhere) return;
    _lastMove = null;
    _tracker.forget();
    _persist();
    _stopTimer?.cancel();
    target = null;
    notifyListeners();
  }
}
