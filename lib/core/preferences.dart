import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud/regions.dart';

/// Несекретные настройки: тема, опрашиваемые регионы, порядок плиток.
class Preferences extends ChangeNotifier {
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
}
