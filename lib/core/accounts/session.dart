/// Сессия аккаунта Xiaomi. Одна и та же сессия подходит для всех регионов.
class Session {
  const Session({
    required this.userId,
    required this.ssecurity,
    required this.serviceToken,
    String? label,
  }) : label = label ?? userId;

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    userId: json['userId'] as String,
    ssecurity: json['ssecurity'] as String,
    serviceToken: json['serviceToken'] as String,
    label: json['label'] as String?,
  );

  final String userId;
  final String ssecurity;
  final String serviceToken;

  /// Как аккаунт называется в интерфейсе: логин, с которым входили.
  final String label;

  /// Сессия демо-режима: без настоящего аккаунта и без сети Xiaomi.
  bool get isDemo => userId == 'demo';

  Session withLabel(String label) => Session(
    userId: userId,
    ssecurity: ssecurity,
    serviceToken: serviceToken,
    label: label.isEmpty ? null : label,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'ssecurity': ssecurity,
    'serviceToken': serviceToken,
    'label': label,
  };
}
