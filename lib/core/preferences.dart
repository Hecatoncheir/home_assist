import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud/regions.dart';
import 'devices/swing_controller.dart';

/// Несекретные настройки: тема, опрашиваемые регионы, порядок плиток.
class Preferences extends ChangeNotifier implements SwingCalibrations {
  Preferences(this._prefs);

  static Future<Preferences> load() async =>
      Preferences(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  ThemeMode get themeMode =>
      ThemeMode.values.byName(_prefs.getString('theme') ?? 'system');

  set themeMode(ThemeMode mode) {
    _prefs.setString('theme', mode.name);
    notifyListeners();
  }

  static const _scaleStep = .1;
  static const _minScale = .8;
  static const _maxScale = 1.5;

  /// Масштаб всего интерфейса: 1 — как задумано.
  double get uiScale => _prefs.getDouble('scale') ?? 1;

  set uiScale(double scale) {
    final rounded = (scale.clamp(_minScale, _maxScale) * 10).round() / 10;
    _prefs.setDouble('scale', rounded);
    notifyListeners();
  }

  bool get canZoomIn => uiScale < _maxScale;
  bool get canZoomOut => uiScale > _minScale;
  void zoomIn() => uiScale += _scaleStep;
  void zoomOut() => uiScale -= _scaleStep;

  List<String> get regions => _prefs.getStringList('regions') ?? allRegions;

  void setRegionPolled(String region, bool polled) {
    final selected = {...regions};
    polled ? selected.add(region) : selected.remove(region);
    _prefs.setStringList(
      'regions',
      allRegions.where(selected.contains).toList(),
    );
    notifyListeners();
  }

  /// `did` устройств в том порядке, в каком пользователь расставил плитки.
  List<String> get deviceOrder => _prefs.getStringList('order') ?? const [];

  set deviceOrder(List<String> dids) => _prefs.setStringList('order', dids);

  @override
  Duration? swingSweep(String did) {
    final ms = _prefs.getInt('swing.$did');
    return ms == null ? null : Duration(milliseconds: ms);
  }

  @override
  void saveSwingSweep(String did, Duration sweep) =>
      _prefs.setInt('swing.$did', sweep.inMilliseconds);

  @override
  SwingSnapshot? swingState(String did) {
    final raw = _prefs.getString('swingState.$did');
    if (raw == null) return null;
    return SwingSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  void saveSwingState(String did, SwingSnapshot? state) => state == null
      ? _prefs.remove('swingState.$did')
      : _prefs.setString('swingState.$did', jsonEncode(state.toJson()));
}
