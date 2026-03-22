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
    required this.usesFullScreenIntent,
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
      usesFullScreenIntent = false,
      notificationsPermissionAtSync = null,
      syncedAt = null,
      nextReminderAt = null,
      lastError = null;

  final int requestedReminderCount;
  final int pendingRequestCount;
  final List<ScheduledReminderEntry> scheduledReminders;
  final bool usesExactScheduling;
  final bool usesFullScreenIntent;
  final bool? notificationsPermissionAtSync;
  final DateTime? syncedAt;
  final DateTime? nextReminderAt;
  final String? lastError;

  bool get canTrustMissedInference =>
      lastError == null &&
      queueHealthy &&
      notificationsPermissionAtSync == true &&
      pendingRequestCount > 0 &&
      scheduledReminders.isNotEmpty;

  bool get expectsScheduledReminders => requestedReminderCount > 0;

  bool get queueHealthy =>
      !expectsScheduledReminders ||
      (pendingRequestCount > 0 &&
          scheduledReminders.isNotEmpty &&
          nextReminderAt != null);

  bool get needsRepair =>
      expectsScheduledReminders &&
      notificationsPermissionAtSync != false &&
      !queueHealthy;

  String get scheduleModeLabel {
    if (usesFullScreenIntent) {
      return 'exact + full-screen';
    }
    return usesExactScheduling ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle';
  }

  ReminderSyncState copyWith({
    int? requestedReminderCount,
    int? pendingRequestCount,
    List<ScheduledReminderEntry>? scheduledReminders,
    bool? usesExactScheduling,
    bool? usesFullScreenIntent,
    bool? notificationsPermissionAtSync,
    DateTime? syncedAt,
    bool clearSyncedAt = false,
    DateTime? nextReminderAt,
    bool clearNextReminderAt = false,
    String? lastError,
    bool clearLastError = false,
  }) {
    return ReminderSyncState(
      requestedReminderCount:
          requestedReminderCount ?? this.requestedReminderCount,
      pendingRequestCount: pendingRequestCount ?? this.pendingRequestCount,
      scheduledReminders: scheduledReminders ?? this.scheduledReminders,
      usesExactScheduling: usesExactScheduling ?? this.usesExactScheduling,
      usesFullScreenIntent: usesFullScreenIntent ?? this.usesFullScreenIntent,
      notificationsPermissionAtSync:
          notificationsPermissionAtSync ?? this.notificationsPermissionAtSync,
      syncedAt: clearSyncedAt ? null : syncedAt ?? this.syncedAt,
      nextReminderAt: clearNextReminderAt
          ? null
          : nextReminderAt ?? this.nextReminderAt,
      lastError: clearLastError ? null : lastError ?? this.lastError,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'requestedReminderCount': requestedReminderCount,
      'pendingRequestCount': pendingRequestCount,
      'scheduledReminders': scheduledReminders
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'usesExactScheduling': usesExactScheduling,
      'usesFullScreenIntent': usesFullScreenIntent,
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
      usesFullScreenIntent: json['usesFullScreenIntent'] as bool? ?? false,
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
