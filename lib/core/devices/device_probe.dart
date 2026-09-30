import '../spec/miot_spec.dart';
import 'device.dart';
import 'device_transport.dart';

/// Свойство, которое устройство отдало при опросе.
class ProbedProperty {
  const ProbedProperty(this.id, this.value, {this.spec});

  final PropertyId id;
  final Object? value;

  /// Описание из спецификации; `null` — свойства в ней нет.
  final MiotProperty? spec;

  bool get hidden => spec == null;
}

class PropertyChange {
  const PropertyChange(this.id, this.from, this.to, this.at);

  final PropertyId id;
  final Object? from;
  final Object? to;
  final DateTime at;
}

class ProbeReport {
  const ProbeReport(this.properties, {this.failedServices = const []});

  final List<ProbedProperty> properties;

  /// siid, на которые устройство ответило ошибкой целиком.
  final List<int> failedServices;

  int get hiddenCount => properties.where((p) => p.hidden).length;
}

/// Исследование устройства: какие свойства оно отдаёт, включая
/// отсутствующие в спецификации. Только чтение — устройство не меняется.
class DeviceProbe {
  DeviceProbe({
    required this.device,
    required MiotSpec? spec,
    required this.transport,
    this.maxSiid = 12,
    this.maxPiid = 20,
  }) : _known = {
         for (final service in spec?.services ?? const <MiotService>[])
           for (final property in service.properties) property.id: property,
       };

  final Device device;
  final int maxSiid;
  final int maxPiid;
  final DeviceTransport transport;
  final Map<PropertyId, MiotProperty> _known;

  /// Опрашивает siid 1…[maxSiid] × piid 1…[maxPiid], по одному запросу
  /// на сервис. Сбой одного сервиса не останавливает остальные.
  Future<ProbeReport> scan({void Function(int siid)? onProgress}) async {
    final found = <PropertyId, Object?>{};
    final failed = <int>[];
    for (var siid = 1; siid <= maxSiid; siid++) {
      onProgress?.call(siid);
      try {
        found.addAll(await read(_service(siid)));
      } catch (_) {
        failed.add(siid);
      }
    }
    final properties = [
      for (final MapEntry(key: id, value: value) in found.entries)
        ProbedProperty(id, value, spec: _known[id]),
    ]..sort((a, b) => _compare(a.id, b.id));
    return ProbeReport(properties, failedServices: failed);
  }

  Future<Map<PropertyId, Object?>> read(Iterable<PropertyId> ids) =>
      transport.getProperties(device, ids.toList());

  /// Что изменилось между двумя чтениями одних и тех же свойств.
  static List<PropertyChange> changes(
    Map<PropertyId, Object?> before,
    Map<PropertyId, Object?> after,
    DateTime at,
  ) => [
    for (final MapEntry(key: id, value: value) in after.entries)
      if (before.containsKey(id) && before[id] != value)
        PropertyChange(id, before[id], value, at),
  ];

  List<PropertyId> _service(int siid) => [
    for (var piid = 1; piid <= maxPiid; piid++) (siid: siid, piid: piid),
  ];

  static int _compare(PropertyId a, PropertyId b) =>
      a.siid != b.siid ? a.siid - b.siid : a.piid - b.piid;
}

String address(PropertyId id) => '${id.siid}.${id.piid}';
