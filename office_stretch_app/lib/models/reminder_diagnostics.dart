class ReminderDeliveryDrift {
  const ReminderDeliveryDrift({
    required this.notificationId,
    required this.postedAt,
    this.scheduledAt,
    this.channelId,
    this.category,
    this.usesFullScreenIntent = false,
  });

  static const noticeableDelayThreshold = Duration(seconds: 10);
  static const severeDelayThreshold = Duration(minutes: 1);

  final int notificationId;
  final DateTime postedAt;
  final DateTime? scheduledAt;
  final String? channelId;
  final String? category;
  final bool usesFullScreenIntent;

  Duration? get delay =>
      scheduledAt == null ? null : postedAt.difference(scheduledAt!);

  bool get hasDelaySample => delay != null;

  bool get isNoticeablyDelayed =>
      delay != null && delay! > noticeableDelayThreshold;

  bool get isSeverelyDelayed => delay != null && delay! > severeDelayThreshold;

  String get delayLabel {
    final drift = delay;
    if (drift == null) {
      return 'No sample';
    }

    final driftSeconds = drift.inSeconds;
    if (driftSeconds.abs() < 1) {
      return 'On time';
    }

    final direction = driftSeconds > 0 ? 'late' : 'early';
    final absoluteSeconds = driftSeconds.abs();
    if (absoluteSeconds >= 60) {
      final minutes = absoluteSeconds ~/ 60;
      final seconds = absoluteSeconds % 60;
      if (seconds == 0) {
        return '$direction ${minutes}m';
      }
      return '$direction ${minutes}m ${seconds}s';
    }
    return '$direction ${absoluteSeconds}s';
  }
}

class ReminderDiagnostics {
  const ReminderDiagnostics({
    required this.platformLabel,
    required this.notificationsEnabled,
    required this.ignoresBatteryOptimizations,
    required this.exactAlarmsEnabled,
    required this.fullScreenIntentEnabled,
    required this.supportsPermissionPrompt,
    required this.supportsNotificationSettings,
    required this.supportsBatteryOptimizationSettings,
    required this.supportsExactAlarmPermissionPrompt,
    required this.supportsFullScreenIntentSettings,
    this.lastObservedReminderDelivery,
  });

  const ReminderDiagnostics.unsupported()
    : platformLabel = 'unsupported',
      notificationsEnabled = null,
      ignoresBatteryOptimizations = null,
      exactAlarmsEnabled = null,
      fullScreenIntentEnabled = null,
      supportsPermissionPrompt = false,
      supportsNotificationSettings = false,
      supportsBatteryOptimizationSettings = false,
      supportsExactAlarmPermissionPrompt = false,
      supportsFullScreenIntentSettings = false,
      lastObservedReminderDelivery = null;

  const ReminderDiagnostics.android({
    required bool? notificationsEnabled,
    required bool? ignoresBatteryOptimizations,
    required bool? exactAlarmsEnabled,
    required bool? fullScreenIntentEnabled,
    bool supportsPermissionPrompt = true,
    bool supportsNotificationSettings = true,
    bool supportsBatteryOptimizationSettings = true,
    bool supportsExactAlarmPermissionPrompt = true,
    bool supportsFullScreenIntentSettings = true,
    ReminderDeliveryDrift? lastObservedReminderDelivery,
  }) : this(
         platformLabel: 'android',
         notificationsEnabled: notificationsEnabled,
         ignoresBatteryOptimizations: ignoresBatteryOptimizations,
         exactAlarmsEnabled: exactAlarmsEnabled,
         fullScreenIntentEnabled: fullScreenIntentEnabled,
         supportsPermissionPrompt: supportsPermissionPrompt,
         supportsNotificationSettings: supportsNotificationSettings,
         supportsBatteryOptimizationSettings:
             supportsBatteryOptimizationSettings,
         supportsExactAlarmPermissionPrompt: supportsExactAlarmPermissionPrompt,
         supportsFullScreenIntentSettings: supportsFullScreenIntentSettings,
         lastObservedReminderDelivery: lastObservedReminderDelivery,
       );

  final String platformLabel;
  final bool? notificationsEnabled;
  final bool? ignoresBatteryOptimizations;
  final bool? exactAlarmsEnabled;
  final bool? fullScreenIntentEnabled;
  final bool supportsPermissionPrompt;
  final bool supportsNotificationSettings;
  final bool supportsBatteryOptimizationSettings;
  final bool supportsExactAlarmPermissionPrompt;
  final bool supportsFullScreenIntentSettings;
  final ReminderDeliveryDrift? lastObservedReminderDelivery;

  bool get isAndroid => platformLabel == 'android';

  bool get usesExactScheduling => exactAlarmsEnabled != false;

  String get scheduleModeLabel =>
      usesExactScheduling ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle';

  bool get hasDeliverySample => lastObservedReminderDelivery != null;

  bool get needsDeliveryAttention =>
      lastObservedReminderDelivery?.isNoticeablyDelayed ?? false;

  bool get needsAttention =>
      notificationsEnabled == false ||
      (isAndroid && ignoresBatteryOptimizations == false) ||
      needsDeliveryAttention;

  ReminderDiagnostics copyWith({
    String? platformLabel,
    bool? notificationsEnabled,
    bool? ignoresBatteryOptimizations,
    bool? exactAlarmsEnabled,
    bool? fullScreenIntentEnabled,
    bool? supportsPermissionPrompt,
    bool? supportsNotificationSettings,
    bool? supportsBatteryOptimizationSettings,
    bool? supportsExactAlarmPermissionPrompt,
    bool? supportsFullScreenIntentSettings,
    ReminderDeliveryDrift? lastObservedReminderDelivery,
    bool clearLastObservedReminderDelivery = false,
  }) {
    return ReminderDiagnostics(
      platformLabel: platformLabel ?? this.platformLabel,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      ignoresBatteryOptimizations:
          ignoresBatteryOptimizations ?? this.ignoresBatteryOptimizations,
      exactAlarmsEnabled: exactAlarmsEnabled ?? this.exactAlarmsEnabled,
      fullScreenIntentEnabled:
          fullScreenIntentEnabled ?? this.fullScreenIntentEnabled,
      supportsPermissionPrompt:
          supportsPermissionPrompt ?? this.supportsPermissionPrompt,
      supportsNotificationSettings:
          supportsNotificationSettings ?? this.supportsNotificationSettings,
      supportsBatteryOptimizationSettings:
          supportsBatteryOptimizationSettings ??
          this.supportsBatteryOptimizationSettings,
      supportsExactAlarmPermissionPrompt:
          supportsExactAlarmPermissionPrompt ??
          this.supportsExactAlarmPermissionPrompt,
      supportsFullScreenIntentSettings:
          supportsFullScreenIntentSettings ??
          this.supportsFullScreenIntentSettings,
      lastObservedReminderDelivery: clearLastObservedReminderDelivery
          ? null
          : lastObservedReminderDelivery ?? this.lastObservedReminderDelivery,
    );
  }
}
