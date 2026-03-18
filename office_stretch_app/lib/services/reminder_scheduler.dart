import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_models.dart';
import '../models/reminder_diagnostics.dart';
import '../models/system_notification_sound.dart';
import 'reminder_timeline.dart';

abstract class ReminderScheduler {
  Stream<String?> get notificationResponses;

  String? takePendingNotificationPayload();

  Future<void> initialize();

  Future<ReminderDiagnostics> diagnostics();

  Future<void> requestPermissions();

  Future<bool> requestExactAlarmPermission();

  Future<void> openNotificationSettings();

  Future<void> openBatteryOptimizationSettings();

  Future<SystemNotificationSound?> pickSystemNotificationSound({
    String? existingUri,
  });

  Future<List<DateTime>> sync({
    required ReminderSettings settings,
    required DateTime requestedStartAt,
    required ExerciseProgram? program,
  });
}

class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Stream<String?> get notificationResponses => const Stream<String?>.empty();

  @override
  String? takePendingNotificationPayload() => null;

  @override
  Future<void> initialize() async {}

  @override
  Future<ReminderDiagnostics> diagnostics() async {
    return const ReminderDiagnostics.unsupported();
  }

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<bool> requestExactAlarmPermission() async => false;

  @override
  Future<void> openBatteryOptimizationSettings() async {}

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<SystemNotificationSound?> pickSystemNotificationSound({
    String? existingUri,
  }) async {
    return null;
  }

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
  static const _channelVersion = 'v3';
  static const _managedChannelPrefix = '${_channelId}_${_channelVersion}_';
  static const _notificationBaseId = 1000;
  static const _maxScheduledNotifications = 60;
  static const _defaultAndroidNotificationSoundUri =
      'content://settings/system/notification_sound';
  static const _settingsChannel = MethodChannel(
    'office_stretch_app/device_settings',
  );

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String?> _notificationResponsesController =
      StreamController<String?>.broadcast();

  String? _pendingNotificationPayload;

  @override
  Stream<String?> get notificationResponses =>
      _notificationResponsesController.stream;

  @override
  String? takePendingNotificationPayload() {
    final payload = _pendingNotificationPayload;
    _pendingNotificationPayload = null;
    return payload;
  }

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

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (notificationResponse) {
        _recordNotificationPayload(notificationResponse.payload);
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _recordNotificationPayload(launchDetails?.notificationResponse?.payload);
    }
  }

  @override
  Future<ReminderDiagnostics> diagnostics() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const ReminderDiagnostics.unsupported();
    }

    final androidPlugin = _androidPlugin;
    final notificationsEnabled = await androidPlugin?.areNotificationsEnabled();
    final exactAlarmsEnabled = await _readExactAlarmCapability();

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
      exactAlarmsEnabled: exactAlarmsEnabled,
    );
  }

  @override
  Future<void> requestPermissions() async {
    await _requestPermissionsIfNeeded();
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      return await _androidPlugin?.requestExactAlarmsPermission() ?? false;
    } catch (error) {
      debugPrint('Failed to request exact alarm permission: $error');
      return false;
    }
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
  Future<SystemNotificationSound?> pickSystemNotificationSound({
    String? existingUri,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      final result = await _settingsChannel.invokeMapMethod<String, Object?>(
        'pickNotificationSound',
        <String, Object?>{'existingUri': existingUri},
      );
      if (result == null) {
        return null;
      }

      return SystemNotificationSound(
        uri: result['uri']! as String,
        label: result['label']! as String,
        isDefault: result['isDefault'] as bool? ?? false,
      );
    } catch (error) {
      debugPrint('Failed to pick notification sound: $error');
      return null;
    }
  }

  @override
  Future<List<DateTime>> sync({
    required ReminderSettings settings,
    required DateTime requestedStartAt,
    required ExerciseProgram? program,
  }) async {
    await _cancelManagedNotifications();
    await _cleanupManagedChannels(
      retainChannelId: settings.notificationsEnabled && program != null
          ? _resolveChannelId(settings)
          : null,
    );

    if (!settings.notificationsEnabled ||
        program == null ||
        !ReminderTimeline.hasValidWindow(settings)) {
      return const <DateTime>[];
    }

    await _requestPermissionsIfNeeded();

    final canUseExactAlarms = await _canScheduleExactAlarms();
    final schedule = ReminderTimeline.buildSchedule(
      requestedStartAt: requestedStartAt,
      settings: settings,
      maxEntries: _maxScheduledNotifications,
    );
    final channelId = _resolveChannelId(settings);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: settings.soundEnabled,
        sound: _resolveAndroidSound(settings),
        enableVibration: settings.vibrationEnabled,
        vibrationPattern: settings.vibrationEnabled
            ? Int64List.fromList(const [0, 300, 150, 300])
            : null,
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
        payload: jsonEncode(<String, Object?>{
          'programId': program.id,
          'reminderAt': scheduledAt.toIso8601String(),
        }),
        androidScheduleMode: canUseExactAlarms
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    return schedule;
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

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
    await _androidPlugin?.requestNotificationsPermission();

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

  AndroidNotificationSound? _resolveAndroidSound(ReminderSettings settings) {
    if (!settings.soundEnabled) {
      return null;
    }

    final customUri = settings.notificationSoundUri;
    if (customUri == null || customUri.isEmpty) {
      return const UriAndroidNotificationSound(
        _defaultAndroidNotificationSoundUri,
      );
    }

    return UriAndroidNotificationSound(customUri);
  }

  String _resolveChannelId(ReminderSettings settings) {
    final rawKey = jsonEncode(<String, Object?>{
      'soundEnabled': settings.soundEnabled,
      'vibrationEnabled': settings.vibrationEnabled,
      'notificationSoundUri': settings.notificationSoundUri,
    });

    return '$_managedChannelPrefix${_stableHexHash(rawKey)}';
  }

  String _stableHexHash(String raw) {
    var hash = 2166136261;
    for (final codeUnit in utf8.encode(raw)) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<void> _cleanupManagedChannels({String? retainChannelId}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final androidPlugin = _androidPlugin;
    if (androidPlugin == null) {
      return;
    }

    try {
      final channels = await androidPlugin.getNotificationChannels();
      for (final channel in channels ?? const <AndroidNotificationChannel>[]) {
        if (!channel.id.startsWith(_managedChannelPrefix) ||
            channel.id == retainChannelId) {
          continue;
        }
        await androidPlugin.deleteNotificationChannel(channelId: channel.id);
      }
    } catch (error) {
      debugPrint('Failed to clean up notification channels: $error');
    }
  }

  Future<bool?> _readExactAlarmCapability() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      return await _androidPlugin?.canScheduleExactNotifications();
    } catch (error) {
      debugPrint('Failed to inspect exact alarm capability: $error');
      return null;
    }
  }

  Future<bool> _canScheduleExactAlarms() async {
    return await _readExactAlarmCapability() ?? true;
  }

  void _recordNotificationPayload(String? payload) {
    _pendingNotificationPayload = payload;
    _notificationResponsesController.add(payload);
  }
}
