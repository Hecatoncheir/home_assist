import 'package:flutter/material.dart';

import '../../core/devices/swing_controller.dart';
import '../theme.dart';
import 'gauge.dart';

const _geometry = GaugeGeometry(250);

/// Насколько далеко от стрелки ещё светятся деления.
const _trail = .12;

/// Регулятор направления: дуга — ход качания, светящиеся деления и отметка
/// на ручке — где сейчас вентилятор. Кнопки у краёв дуги — для калибровки:
/// левая — край 0, правая — край 1.
class SwingDial extends StatefulWidget {
  const SwingDial({super.key, required this.swing});

  final SwingController swing;

  @override
  State<SwingDial> createState() => _SwingDialState();
}

class _SwingDialState extends State<SwingDial>
    with SingleTickerProviderStateMixin {
  late final _ticker = createTicker((_) => setState(() {}));

  /// Куда тянут прямо сейчас.
  double? _dragging;

  SwingController get _swing => widget.swing;

  @override
  void initState() {
    super.initState();
    _swing.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    _swing.removeListener(_sync);
    _ticker.dispose();
    super.dispose();
  }

  /// Пока вентилятор движется или держат кнопку, перерисовываем каждый кадр.
  void _sync() {
    final animate = _swing.moving || _swing.holding;
    if (animate && !_ticker.isActive) _ticker.start();
    if (!animate && _ticker.isActive) _ticker.stop();
    if (mounted) setState(() {});
  }

  void _release() {
    final target = _dragging;
    setState(() => _dragging = null);
    if (target != null) _swing.moveTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final position = _swing.position;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: GaugeLayout(
            geometry: _geometry,
            ring: GaugeRingPainter(
              geometry: _geometry,
              colors: c,
              ticks: 40,
              intensity: (at) => _glow(position, at),
              target: _dragging ?? _swing.target,
            ),
            knob: GaugeKnob(
              geometry: _geometry,
              marker: position,
              child: _KnobFace(swing: _swing),
            ),
            left: _edgeButton(0, Icons.chevron_left),
            right: _edgeButton(1, Icons.chevron_right),
            onAim: position == null
                ? null
                : (at) => setState(() => _dragging = at),
            onRelease: position == null ? null : _release,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _hint,
          textAlign: TextAlign.center,
          style: TextStyle(color: c.muted, fontSize: 13),
        ),
        if (_swing.canRetry)
          TextButton.icon(
            onPressed: _swing.retry,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Поехал не туда — пересчитать'),
          ),
      ],
    );
  }

  /// Деления у стрелки светятся, дальше — гаснут.
  double _glow(double? position, double at) {
    if (position == null) return 0;
    return 1 - (at - position).abs() / _trail;
  }

  Widget _edgeButton(int edge, IconData icon) => GaugeButton(
    icon: icon,
    tooltip: 'Держите, пока вентилятор идёт к этому краю',
    state: _buttonState(edge),
    onHoldStart: () => _swing.holdStart(edge),
    onHoldEnd: _swing.holdEnd,
  );

  GaugeButtonState _buttonState(int edge) {
    if (_swing.holdingEdge == edge) return GaugeButtonState.holding;
    final result = _swing.holdResult;
    if (result == null || result.edge != edge) return GaugeButtonState.idle;
    return result.accepted
        ? GaugeButtonState.accepted
        : GaugeButtonState.rejected;
  }

  String get _hint {
    final result = _swing.holdResult;
    if (_swing.holding) {
      final seconds = _swing.holdElapsed!.inMilliseconds / 1000;
      return 'Отпустите, когда вентилятор развернётся у края… '
          '${seconds.toStringAsFixed(1)} с';
    }
    if (_swing.calibrating) {
      return 'Вентилятор качается. Когда он развернётся у края, зажмите '
          'кнопку того края, к которому он пошёл, и отпустите, когда он '
          'развернётся у него.';
    }
    if (result != null && !result.accepted) {
      return 'Слишком короткое нажатие: держите кнопку весь проход '
          'от края до края.';
    }
    if (!_swing.calibrated) {
      return 'Нажмите «Калибровка»: вентилятор начнёт качаться, и вы '
          'засечёте один проход от края до края кнопками по бокам.';
    }
    if (_swing.position == null) {
      return 'Положение сбилось: качание включали не из приложения. '
          'Нажмите «Калибровка» — достаточно одного прохода.';
    }
    if (_swing.target != null) return 'Поворачиваю…';
    final seconds = _swing.sweep.inMilliseconds / 1000;
    return 'Нажмите на дугу, чтобы повернуть вентилятор. '
        'Проход от края до края — ${seconds.toStringAsFixed(1)} с.';
  }
}

/// Лицевая сторона ручки: что сейчас происходит.
class _KnobFace extends StatelessWidget {
  const _KnobFace({required this.swing});

  final SwingController swing;

  String get _status {
    if (swing.holding) return 'засекаю проход';
    if (swing.calibrating) return 'ждём края';
    if (swing.position == null) return 'нет данных';
    if (swing.target != null) return 'поворот';
    return swing.moving ? 'качается' : 'стоит';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.explore_outlined, size: 26, color: c.glowB),
        const SizedBox(height: 4),
        Text(_status, style: TextStyle(color: c.muted, fontSize: 13)),
        const SizedBox(height: 10),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            backgroundColor: swing.calibrating ? c.glowB : c.bg,
            foregroundColor: swing.calibrating ? c.glowInk : c.ink,
            shape: const StadiumBorder(),
          ),
          onPressed: swing.holding ? null : swing.startCalibration,
          child: const Text('Калибровка'),
        ),
      ],
    );
  }
}
