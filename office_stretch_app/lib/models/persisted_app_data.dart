import 'dart:convert';

import 'app_models.dart';
import 'reminder_sync_state.dart';

class PersistedAppData {
  const PersistedAppData({
    required this.settings,
    required this.logs,
    this.profile,
    this.nextReminderAt,
    this.reminderSyncState = const ReminderSyncState.empty(),
  });

  final UserProfile? profile;
  final ReminderSettings settings;
  final List<ExerciseLog> logs;
  final DateTime? nextReminderAt;
  final ReminderSyncState reminderSyncState;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'profile': profile?.toJson(),
      'settings': settings.toJson(),
      'logs': logs.map((log) => log.toJson()).toList(growable: false),
      'nextReminderAt': nextReminderAt?.toIso8601String(),
      'reminderSyncState': reminderSyncState.toJson(),
    };
  }

  String encode() => jsonEncode(toJson());

  factory PersistedAppData.fromJson(Map<String, Object?> json) {
    final profileJson = json['profile'];
    final logsJson = (json['logs'] as List<Object?>? ?? const <Object?>[])
        .cast<Map<Object?, Object?>>();

    return PersistedAppData(
      profile: profileJson == null
          ? null
          : UserProfile.fromJson(
              (profileJson as Map<Object?, Object?>).cast<String, Object?>(),
            ),
      settings: ReminderSettings.fromJson(
        (json['settings']! as Map<Object?, Object?>).cast<String, Object?>(),
      ),
      logs: logsJson
          .map(
            (logJson) => ExerciseLog.fromJson(logJson.cast<String, Object?>()),
          )
          .toList(growable: false),
      nextReminderAt: json['nextReminderAt'] == null
          ? null
          : DateTime.parse(json['nextReminderAt']! as String),
      reminderSyncState: json['reminderSyncState'] == null
          ? const ReminderSyncState.empty()
          : ReminderSyncState.fromJson(
              (json['reminderSyncState']! as Map<Object?, Object?>)
                  .cast<String, Object?>(),
            ),
    );
  }

  factory PersistedAppData.decode(String raw) {
    return PersistedAppData.fromJson(
      (jsonDecode(raw) as Map<Object?, Object?>).cast<String, Object?>(),
    );
  }
}
