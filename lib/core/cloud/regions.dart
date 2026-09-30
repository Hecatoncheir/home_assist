/// Регионы серверов Xiaomi. Устройство привязано к одному из них.
/// Названия регионов — в переводах интерфейса (`regionName`).
const allRegions = ['cn', 'ru', 'de', 'us', 'sg', 'i2', 'tw'];

Uri regionApiUrl(String region, String path) {
  final host = region == 'cn' ? 'api.io.mi.com' : '$region.api.io.mi.com';
  return Uri.https(host, '/app$path');
}
