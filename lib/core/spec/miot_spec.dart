/// Адрес свойства внутри устройства.
typedef PropertyId = ({int siid, int piid});

/// Спецификация MIoT-Spec-V2: что устройство умеет.
class MiotSpec {
  const MiotSpec({required this.description, required this.services});

  factory MiotSpec.fromJson(Map<String, dynamic> json) => MiotSpec(
    description: json['description'] as String? ?? '',
    services: [
      for (final service in json['services'] as List? ?? const [])
        MiotService.fromJson(service as Map<String, dynamic>),
    ],
  );

  static const _infoService = 'device-information';

  final String description;
  final List<MiotService> services;

  /// Сервисы, которые есть смысл показывать пользователю.
  List<MiotService> get controls =>
      services.where((service) => service.name != _infoService).toList();

  Iterable<MiotProperty> get _properties =>
      controls.expand((service) => service.properties);

  List<PropertyId> get readableIds => [
    for (final property in _properties)
      if (property.readable) property.id,
  ];

  /// Первое свойство с именем [name], например `horizontal-swing`.
  MiotProperty? property(String name) {
    for (final property in _properties) {
      if (property.name == name) return property;
    }
    return null;
  }

  /// Главный выключатель: первое свойство `on`, которое можно менять.
  MiotProperty? get power {
    for (final property in _properties) {
      if (property.name == 'on' && property.isSwitch) return property;
    }
    return null;
  }
}

class MiotService {
  const MiotService({
    required this.name,
    required this.description,
    required this.properties,
    required this.actions,
  });

  factory MiotService.fromJson(Map<String, dynamic> json) {
    final siid = json['iid'] as int;
    return MiotService(
      name: _urnName(json['type']),
      description: json['description'] as String? ?? '',
      properties: [
        for (final property in json['properties'] as List? ?? const [])
          MiotProperty.fromJson(siid, property as Map<String, dynamic>),
      ],
      actions: [
        for (final action in json['actions'] as List? ?? const [])
          MiotAction.fromJson(siid, action as Map<String, dynamic>),
      ],
    );
  }

  final String name;
  final String description;
  final List<MiotProperty> properties;
  final List<MiotAction> actions;
}

class MiotProperty {
  const MiotProperty({
    required this.id,
    required this.name,
    required this.description,
    required this.format,
    required this.readable,
    required this.writable,
    required this.unit,
    required this.range,
    required this.values,
  });

  factory MiotProperty.fromJson(int siid, Map<String, dynamic> json) {
    final access = json['access'] as List? ?? const [];
    final range = json['value-range'] as List?;
    return MiotProperty(
      id: (siid: siid, piid: json['iid'] as int),
      name: _urnName(json['type']),
      description: json['description'] as String? ?? '',
      format: json['format'] as String? ?? '',
      readable: access.contains('read'),
      writable: access.contains('write'),
      unit: json['unit'] as String? ?? '',
      range: range == null ? null : MiotRange.fromJson(range),
      values: [
        for (final item in json['value-list'] as List? ?? const [])
          (value: item['value'] as int, label: '${item['description']}'),
      ],
    );
  }

  final PropertyId id;
  final String name;
  final String description;

  /// `bool`, `uint8`, `float`, `string` и т. д.
  final String format;
  final bool readable;
  final bool writable;
  final String unit;
  final MiotRange? range;
  final List<({int value, String label})> values;

  /// Подпись для интерфейса: у части свойств описание в спецификации пустое.
  String get label => description.isNotEmpty ? description : name;

  bool get isSwitch => format == 'bool' && readable && writable;
  bool get isFloat => format == 'float';
}

class MiotRange {
  const MiotRange(this.min, this.max, this.step);

  factory MiotRange.fromJson(List<dynamic> json) =>
      MiotRange(json[0] as num, json[1] as num, json[2] as num);

  final num min;
  final num max;
  final num step;
}

class MiotAction {
  const MiotAction({
    required this.siid,
    required this.aiid,
    required this.name,
    required this.description,
    required this.hasInputs,
  });

  factory MiotAction.fromJson(int siid, Map<String, dynamic> json) =>
      MiotAction(
        siid: siid,
        aiid: json['iid'] as int,
        name: _urnName(json['type']),
        description: json['description'] as String? ?? '',
        hasInputs: (json['in'] as List? ?? const []).isNotEmpty,
      );

  final int siid;
  final int aiid;
  final String name;
  final String description;

  /// Действия с параметрами приложение пока не вызывает.
  final bool hasInputs;

  String get label => description.isNotEmpty ? description : name;
}

/// `urn:miot-spec-v2:property:fan-level:00000016:dmaker-p5:1` → `fan-level`.
String _urnName(Object? urn) {
  final parts = '$urn'.split(':');
  return parts.length > 3 ? parts[3] : '';
}
