class ReminderDiagnostics {
  const ReminderDiagnostics({
    required this.platformLabel,
    required this.notificationsEnabled,
    required this.ignoresBatteryOptimizations,
    required this.supportsPermissionPrompt,
    required this.supportsNotificationSettings,
    required this.supportsBatteryOptimizationSettings,
  });

  const ReminderDiagnostics.unsupported()
    : platformLabel = 'unsupported',
      notificationsEnabled = null,
      ignoresBatteryOptimizations = null,
      supportsPermissionPrompt = false,
      supportsNotificationSettings = false,
      supportsBatteryOptimizationSettings = false;

  const ReminderDiagnostics.android({
    required bool? notificationsEnabled,
    required bool? ignoresBatteryOptimizations,
    bool supportsPermissionPrompt = true,
    bool supportsNotificationSettings = true,
    bool supportsBatteryOptimizationSettings = true,
  }) : this(
         platformLabel: 'android',
         notificationsEnabled: notificationsEnabled,
         ignoresBatteryOptimizations: ignoresBatteryOptimizations,
         supportsPermissionPrompt: supportsPermissionPrompt,
         supportsNotificationSettings: supportsNotificationSettings,
         supportsBatteryOptimizationSettings:
             supportsBatteryOptimizationSettings,
       );

  final String platformLabel;
  final bool? notificationsEnabled;
  final bool? ignoresBatteryOptimizations;
  final bool supportsPermissionPrompt;
  final bool supportsNotificationSettings;
  final bool supportsBatteryOptimizationSettings;

  bool get isAndroid => platformLabel == 'android';

  bool get needsAttention =>
      notificationsEnabled == false ||
      (isAndroid && ignoresBatteryOptimizations == false);
}
