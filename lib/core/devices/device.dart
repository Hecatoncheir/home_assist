class Device {
  const Device({
    required this.did,
    required this.model,
    required this.name,
    required this.region,
    required this.accountId,
    required this.localIp,
    required this.token,
    required this.isOnline,
    required this.parentId,
  });

  factory Device.fromCloud(
    Map<String, dynamic> json, {
    required String region,
    required String accountId,
  }) => Device(
    did: '${json['did']}',
    model: json['model'] as String? ?? '',
    name: json['name'] as String? ?? '',
    region: region,
    accountId: accountId,
    localIp: json['localip'] as String? ?? '',
    token: json['token'] as String? ?? '',
    isOnline: json['isOnline'] == true,
    parentId: json['parent_id'] as String? ?? '',
  );

  final String did;
  final String model;
  final String name;
  final String region;
  final String accountId;
  final String localIp;
  final String token;
  final bool isOnline;

  /// Пусто, если устройство подключено напрямую, а не через шлюз.
  final String parentId;
}
