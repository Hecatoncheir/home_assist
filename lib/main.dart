import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'core/preferences.dart';
import 'core/spec/spec_repository.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await Preferences.load();
  final specs = SpecRepository(
    cacheDir: await getApplicationSupportDirectory(),
  );
  runApp(HomeAssistApp(prefs: prefs, specs: specs));
}
