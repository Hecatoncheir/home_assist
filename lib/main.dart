import 'package:flutter/material.dart';

import 'core/preferences.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(HomeAssistApp(prefs: await Preferences.load()));
}
