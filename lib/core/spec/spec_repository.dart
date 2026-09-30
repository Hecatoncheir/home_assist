import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'miot_spec.dart';

/// Загружает спецификации устройств с miot-spec.org и кэширует их на диске.
class SpecRepository {
  SpecRepository({required this.cacheDir, http.Client? client})
    : _http = client ?? http.Client();

  static const _host = 'miot-spec.org';
  static const _indexMaxAge = Duration(days: 7);

  final Directory cacheDir;
  final http.Client _http;
  final _specs = <String, Future<MiotSpec?>>{};
  Future<Map<String, dynamic>>? _index;

  /// `null`, если для модели нет опубликованной спецификации.
  Future<MiotSpec?> forModel(String model) =>
      _specs[model] ??= _loadSpec(model);

  Future<MiotSpec?> _loadSpec(String model) async {
    final file = File(p.join(cacheDir.path, 'spec', '$model.json'));
    if (file.existsSync()) return _parse(await file.readAsString());

    final type = (await (_index ??= _loadIndex()))[model];
    if (type == null) return null;
    final body = await _get('/miot-spec-v2/instance', {'type': '$type'});
    await _write(file, body);
    return _parse(body);
  }

  MiotSpec _parse(String body) =>
      MiotSpec.fromJson(jsonDecode(body) as Map<String, dynamic>);

  /// Соответствие «модель → тип спецификации».
  Future<Map<String, dynamic>> _loadIndex() async {
    final file = File(p.join(cacheDir.path, 'instances.json'));
    if (_isFresh(file)) return _readIndex(file);
    try {
      final body = await _get('/miot-spec-v2/instances', {
        'status': 'released',
      });
      await _write(file, jsonEncode(_latestTypes(body)));
    } on Exception {
      // Без сети годится и устаревший каталог.
      if (!file.existsSync()) rethrow;
    }
    return _readIndex(file);
  }

  bool _isFresh(File file) =>
      file.existsSync() &&
      DateTime.now().difference(file.lastModifiedSync()) < _indexMaxAge;

  Future<Map<String, dynamic>> _readIndex(File file) async =>
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;

  /// У модели бывает несколько версий спецификации — берём последнюю.
  Map<String, String> _latestTypes(String body) {
    final versions = <String, int>{};
    final types = <String, String>{};
    for (final item in jsonDecode(body)['instances'] as List) {
      final model = item['model'] as String;
      final version = item['version'] as int;
      if (version < (versions[model] ?? 0)) continue;
      versions[model] = version;
      types[model] = item['type'] as String;
    }
    return types;
  }

  Future<String> _get(String path, Map<String, String> query) async {
    final response = await _http.get(Uri.https(_host, path, query));
    if (response.statusCode != 200) {
      throw HttpException('miot-spec.org: HTTP ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes);
  }

  Future<void> _write(File file, String content) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }
}
