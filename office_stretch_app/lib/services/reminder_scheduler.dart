import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_models.dart';
import '../models/reminder_diagnostics.dart';
import 'reminder_timeline.dart';

abstract class ReminderScheduler {
  Future<void> initialize();

  Future<ReminderDiagnostics> diagnostics();

  Future<void> requestPermissions();

  Future<void> openNotificationSettings();

  Future<void> openBatteryOptimizationSettings();

  Future<List<DateTime>> sync({
    required ReminderSettings settings,
    required DateTime requestedStartAt,
    required ExerciseProgram? program,
  });
}

class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<void> initialize() async {}

  @override
  Future<ReminderDiagnostics> diagnostics() async {
    return const ReminderDiagnostics.unsupported();
  }

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> openBatteryOptimizationSettings() async {}

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<List<DateTime>> sync({
    required ReminderSettings settings,
    required DateTime requestedStartAt,
    required ExerciseProgram? program,
  }) async {
    if (!settings.notificationsEnabled || program == null) {
      return const <DateTime>[];
    }

    return ReminderTimeline.buildSchedule(
      requestedStartAt: requestedStartAt,
      settings: settings,
      maxEntries: 1,
      horizon: const Duration(days: 1),
    );
  }
}

class LocalNotificationReminderScheduler implements ReminderScheduler {
  LocalNotificationReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'stretch_reminders';
  static const _channelName = 'Stretch reminders';
  static const _channelDescription = 'Reminders to pause and stretch';
  static const _notificationBaseId = 1000;
  static const _maxScheduledNotifications = 60;
  static const _settingsChannel = MethodChannel(
    'office_stretch_app/device_settings',
  );

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linux = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );
    const windows = WindowsInitializationSettings(
      appName: 'Office Stretch',
      appUserModelId: 'com.codex.office_stretch_app',
      guid: 'e0178c83-b38b-4d2b-aa5a-6ddc6bb1d24e',
    );

    const settings = InitializationSettings(
      android: android,
      iOS: ios,
      macOS: ios,
      linux: linux,
      windows: windows,
    );

    await _plugin.initialize(settings: settings);
  }

  @override
  Future<ReminderDiagnostics> diagnostics() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const ReminderDiagnostics.unsupported();
    }

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notificationsEnabled = await androidPlugin?.areNotificationsEnabled();

    bool? ignoresBatteryOptimizations;
    try {
      ignoresBatteryOptimizations = await _settingsChannel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
    } catch (error) {
      debugPrint('Failed to read battery optimization state: $error');
    }

    return ReminderDiagnostics.android(
      notificationsEnabled: notificationsEnabled,
      ignoresBatteryOptimizations: ignoresBatteryOptimizations,
    );
  }

  @override
  Future<void> requestPermissions() async {
    await _requestPermissionsIfNeeded();
  }

  @override
  Future<void> openNotificationSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _settingsChannel.invokeMethod<void>('openAppNotificationSettings');
    } catch (error) {
      debugPrint('Failed to open notification settings: $error');
    }
  }

  @override
  Future<void> openBatteryOptimizationSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _settingsChannel.invokeMethod<void>(
        'openBatteryOptimizationSettings',
      );
    } catch (error) {
      debugPrint('Failed to open battery optimization settings: $error');
    }
  }

  @override
  Future<List<DateTime>> sync({
    required ReminderSettings settings,
    required DateTime requestedStartAt,
    required ExerciseProgram? program,
  }) async {
    await _cancelManagedNotifications();

    if (!settings.notificationsEnabled ||
        program == null ||
        !ReminderTimeline.hasValidWindow(settings)) {
      return const <DateTime>[];
    }

    await _requestPermissionsIfNeeded();

    final schedule = ReminderTimeline.buildSchedule(
      requestedStartAt: requestedStartAt,
      settings: settings,
      maxEntries: _maxScheduledNotifications,
    );

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: settings.soundEnabled,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: settings.soundEnabled,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: settings.soundEnabled,
      ),
    );

    for (var index = 0; index < schedule.length; index += 1) {
      final scheduledAt = schedule[index];
      await _plugin.zonedSchedule(
        id: _notificationBaseId + index,
        title: 'ถึงเวลาพักยืดเส้น',
        body:
            '${program.title} • ${program.exercises.length} ท่า • รอบละ ${settings.intervalMinutes} นาที',
        scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
        notificationDetails: details,
        payload: program.id,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    return schedule;
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb) {
      return;
    }

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (error) {
      debugPrint('Falling back to UTC timezone: $error');
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> _requestPermissionsIfNeeded() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: true);
  }

  Future<void> _cancelManagedNotifications() async {
    for (var index = 0; index < _maxScheduledNotifications; index += 1) {
      await _plugin.cancel(id: _notificationBaseId + index);
    }
  }
}
