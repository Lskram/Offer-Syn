class SystemTimeChangeSignal {
  const SystemTimeChangeSignal({
    required this.action,
    required this.observedAt,
    required this.timeZoneId,
    required this.systemTime,
  });

  final String? action;
  final DateTime observedAt;
  final String? timeZoneId;
  final DateTime systemTime;

  factory SystemTimeChangeSignal.fromJson(Map<String, Object?> json) {
    return SystemTimeChangeSignal(
      action: json['action'] as String?,
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        json['observedAtMillis']! as int,
      ),
      timeZoneId: json['timeZoneId'] as String?,
      systemTime: DateTime.fromMillisecondsSinceEpoch(
        json['systemTimeMillis']! as int,
      ),
    );
  }
}
