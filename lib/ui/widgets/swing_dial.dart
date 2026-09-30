import 'package:flutter/material.dart';

import '../../core/devices/swing_controller.dart';
import '../l10n.dart';
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
          _hint(context.l10n),
          textAlign: TextAlign.center,
          style: TextStyle(color: c.muted, fontSize: 13),
        ),
        if (_swing.canRetry)
          TextButton.icon(
            onPressed: _swing.retry,
            icon: const Icon(Icons.swap_horiz),
            label: Text(context.l10n.swingRecalibrate),
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
    tooltip: context.l10n.swingHoldTooltip,
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

  String _hint(AppLocalizations l) {
    final result = _swing.holdResult;
    if (_swing.holding) return l.swingRelease(_seconds(_swing.holdElapsed!));
    if (result != null && !result.accepted) return l.swingNotCounted;
    if (_swing.awaitingOtherEdge) return l.swingOtherEdge;
    if (_swing.calibrating || !_swing.calibrated) {
      return l.swingCalibrationIntro;
    }
    if (_swing.position == null) return l.swingLost;
    if (_swing.target != null) return l.swingTurning;
    return l.swingReady(_seconds(_swing.sweep), _seconds(_swing.dwell));
  }

  static String _seconds(Duration duration) =>
      (duration.inMilliseconds / 1000).toStringAsFixed(1);
}

/// Лицевая сторона ручки: что сейчас происходит.
class _KnobFace extends StatelessWidget {
  const _KnobFace({required this.swing});

  final SwingController swing;

  String _status(AppLocalizations l) {
    if (swing.holding) return l.swingStatusHolding;
    if (swing.calibrating) return l.swingStatusWaitingEdge;
    if (swing.position == null) return l.swingStatusNoData;
    if (swing.target != null) return l.swingStatusTurning;
    return swing.moving ? l.swingStatusSwinging : l.swingStatusStill;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.explore_outlined, size: 26, color: c.glowB),
        const SizedBox(height: 4),
        Text(
          _status(context.l10n),
          style: TextStyle(color: c.muted, fontSize: 13),
        ),
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
          child: Text(context.l10n.calibrate),
        ),
      ],
    );
  }
}
