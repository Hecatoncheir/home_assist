import '../cloud/mi_cloud_client.dart';
import '../cloud/regions.dart';
import 'device.dart';

/// Итог опроса одного региона: либо устройства, либо ошибка.
class RegionResult {
  const RegionResult(
    this.region, {
    required this.accountId,
    this.devices = const [],
    this.error,
  });

  final String region;
  final String accountId;
  final List<Device> devices;
  final Object? error;
}

class DeviceRepository {
  DeviceRepository(this._cloud, {this.timeout = const Duration(seconds: 15)});

  final MiCloudClient _cloud;
  final Duration timeout;

  String get _accountId => _cloud.session.userId;

  /// Опрашивает регионы параллельно. Сбой одного региона не мешает остальным.
  Future<List<RegionResult>> loadAll([List<String> regions = allRegions]) =>
      Future.wait(regions.map(_loadRegionSafely));

  Future<RegionResult> _loadRegionSafely(String region) async {
    try {
      final devices = await _loadRegion(region).timeout(timeout);
      return RegionResult(region, accountId: _accountId, devices: devices);
    } catch (error) {
      return RegionResult(region, accountId: _accountId, error: error);
    }
  }

  Future<List<Device>> _loadRegion(String region) async {
    final result = await _cloud.call(region, '/home/device_list', {
      'getVirtualModel': true,
      'getHuamiDevices': 1,
      'get_split_device': false,
      'support_smart_home': true,
    });
    final list = result['list'] as List? ?? const [];
    return [
      for (final item in list)
        Device.fromCloud(
          item as Map<String, dynamic>,
          region: region,
          accountId: _accountId,
        ),
    ];
  }
}
