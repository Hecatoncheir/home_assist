import 'package:flutter_test/flutter_test.dart';
import 'package:home_assist/core/devices/swing_tracker.dart';

void main() {
  final t0 = DateTime(2026);
  DateTime at(double seconds) =>
      t0.add(Duration(milliseconds: (seconds * 1000).round()));

  SwingTracker tracker() => SwingTracker(const Duration(seconds: 10));

  test('без калибровки положение неизвестно', () {
    expect(tracker().positionAt(t0), isNull);
  });

  test('от верхнего края идёт вниз, у нижнего разворачивается', () {
    final swing = tracker()..reachedEdge(1, t0);

    expect(swing.positionAt(at(0)), 1);
    expect(swing.positionAt(at(2.5)), closeTo(.75, 1e-9));
    expect(swing.positionAt(at(10)), closeTo(0, 1e-9));
    expect(swing.positionAt(at(12.5)), closeTo(.25, 1e-9));
    expect(swing.positionAt(at(25)), closeTo(.5, 1e-9));
  });

  test('время до цели учитывает направление движения', () {
    final swing = tracker()..reachedEdge(0, t0);

    // Идёт вверх: до 0.3 — 3 с, а до уже пройденной 0.3 на обратном пути — 17 с.
    expect(swing.timeTo(.3, at(0)), const Duration(seconds: 3));
    expect(swing.timeTo(.3, at(4)), const Duration(seconds: 13));
  });

  test('после остановки стоит, после возобновления продолжает', () {
    final swing = tracker()..reachedEdge(0, t0);
    swing.stop(at(4));

    expect(swing.moving, isFalse);
    expect(swing.positionAt(at(100)), closeTo(.4, 1e-9));

    swing.resume(at(100));
    expect(swing.positionAt(at(102)), closeTo(.6, 1e-9));
  });

  test('forget сбрасывает положение', () {
    final swing = tracker()
      ..reachedEdge(1, t0)
      ..forget();

    expect(swing.known, isFalse);
    expect(swing.timeTo(.5, t0), isNull);
  });
}
