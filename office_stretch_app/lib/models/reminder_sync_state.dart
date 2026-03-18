class ScheduledReminderEntry {
  const ScheduledReminderEntry({
    required this.notificationId,
    required this.scheduledAt,
  });

  final int notificationId;
  final DateTime scheduledAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'notificationId': notificationId,
      'scheduledAt': scheduledAt.toIso8601String(),
    };
  }

  factory ScheduledReminderEntry.fromJson(Map<String, Object?> json) {
    return ScheduledReminderEntry(
      notificationId: json['notificationId']! as int,
      scheduledAt: DateTime.parse(json['scheduledAt']! as String),
    );
  }
}

class ReminderSyncState {
  const ReminderSyncState({
    required this.requestedReminderCount,
    required this.pendingRequestCount,
    required this.scheduledReminders,
    required this.usesExactScheduling,
    required this.notificationsPermissionAtSync,
    this.syncedAt,
    this.nextReminderAt,
    this.lastError,
  });

  const ReminderSyncState.empty()
    : requestedReminderCount = 0,
      pendingRequestCount = 0,
      scheduledReminders = const <ScheduledReminderEntry>[],
      usesExactScheduling = false,
      notificationsPermissionAtSync = null,
      syncedAt = null,
      nextReminderAt = null,
      lastError = null;

  final int requestedReminderCount;
  final int pendingRequestCount;
  final List<ScheduledReminderEntry> scheduledReminders;
  final bool usesExactScheduling;
  final bool? notificationsPermissionAtSync;
  final DateTime? syncedAt;
  final DateTime? nextReminderAt;
  final String? lastError;

  bool get canTrustMissedInference =>
      lastError == null &&
      notificationsPermissionAtSync == true &&
      pendingRequestCount > 0 &&
      scheduledReminders.isNotEmpty;

  String get scheduleModeLabel =>
      usesExactScheduling ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle';

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'requestedReminderCount': requestedReminderCount,
      'pendingRequestCount': pendingRequestCount,
      'scheduledReminders': scheduledReminders
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'usesExactScheduling': usesExactScheduling,
      'notificationsPermissionAtSync': notificationsPermissionAtSync,
      'syncedAt': syncedAt?.toIso8601String(),
      'nextReminderAt': nextReminderAt?.toIso8601String(),
      'lastError': lastError,
    };
  }

  factory ReminderSyncState.fromJson(Map<String, Object?> json) {
    final remindersJson =
        (json['scheduledReminders'] as List<Object?>? ?? const <Object?>[])
            .cast<Map<Object?, Object?>>();

    return ReminderSyncState(
      requestedReminderCount: json['requestedReminderCount'] as int? ?? 0,
      pendingRequestCount: json['pendingRequestCount'] as int? ?? 0,
      scheduledReminders: remindersJson
          .map(
            (entry) =>
                ScheduledReminderEntry.fromJson(entry.cast<String, Object?>()),
          )
          .toList(growable: false),
      usesExactScheduling: json['usesExactScheduling'] as bool? ?? false,
      notificationsPermissionAtSync:
          json['notificationsPermissionAtSync'] as bool?,
      syncedAt: json['syncedAt'] == null
          ? null
          : DateTime.parse(json['syncedAt']! as String),
      nextReminderAt: json['nextReminderAt'] == null
          ? null
          : DateTime.parse(json['nextReminderAt']! as String),
      lastError: json['lastError'] as String?,
    );
  }
}
