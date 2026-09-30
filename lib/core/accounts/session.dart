/// Сессия аккаунта Xiaomi. Одна и та же сессия подходит для всех регионов.
class Session {
  const Session({
    required this.userId,
    required this.ssecurity,
    required this.serviceToken,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    userId: json['userId'] as String,
    ssecurity: json['ssecurity'] as String,
    serviceToken: json['serviceToken'] as String,
  );

  final String userId;
  final String ssecurity;
  final String serviceToken;

  /// Сессия демо-режима: без настоящего аккаунта и без сети Xiaomi.
  bool get isDemo => userId == 'demo';

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'ssecurity': ssecurity,
    'serviceToken': serviceToken,
  };
}
