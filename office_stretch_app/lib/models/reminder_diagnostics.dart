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
      supportsFullScreenIntentSettings = false;

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

  bool get isAndroid => platformLabel == 'android';

  bool get usesExactScheduling => exactAlarmsEnabled != false;

  String get scheduleModeLabel =>
      usesExactScheduling ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle';

  bool get needsAttention =>
      notificationsEnabled == false ||
      (isAndroid && ignoresBatteryOptimizations == false);
}
