/// Регионы серверов Xiaomi. Устройство привязано к одному из них.
const regionNames = {
  'cn': 'Китай',
  'ru': 'Россия',
  'de': 'Европа',
  'us': 'США',
  'sg': 'Сингапур',
  'i2': 'Индия',
  'tw': 'Тайвань',
};

const allRegions = ['cn', 'ru', 'de', 'us', 'sg', 'i2', 'tw'];

Uri regionApiUrl(String region, String path) {
  final host = region == 'cn' ? 'api.io.mi.com' : '$region.api.io.mi.com';
  return Uri.https(host, '/app$path');
}
