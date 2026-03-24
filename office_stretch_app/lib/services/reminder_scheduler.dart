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
import '../models/reminder_sync_state.dart';
import '../models/system_time_change_signal.dart';
import '../models/system_notification_sound.dart';
import 'reminder_timeline.dart';

const _notificationSmallIcon = 'ic_stat_office_relief';

class ReminderNotificationCopy {
  const ReminderNotificationCopy._();

  static const reminderTitle = 'ถึงเวลาพักยืดเส้น';
  static const testTitle = 'ทดสอบการแจ้งเตือน OfficeRelief';

  static String reminderBody({
    required ExercisePlan plan,
    required ReminderSettings settings,
  }) {
    return '${plan.title} • ${plan.exercises.length} ท่า • รอบละ ${settings.intervalMinutes} นาที';
  }

  static String testBody({required ExercisePlan? plan}) {
    if (plan == null) {
      return 'หากเห็นข้อความนี้ แปลว่าระบบแจ้งเตือนของแอปทำงานแล้ว';
    }

    return 'หากเห็นข้อความนี้ แปลว่าระบบแจ้งเตือนพร้อมสำหรับโปรแกรม ${plan.title}';
  }
}

abstract class ReminderScheduler {
  Stream<String?> get notificationResponses;

  String? takePendingNotificationPayload();

  Future<void> initialize();

  Future<ReminderDiagnostics> diagnostics();

  Future<void> clearDeliveredNotifications();

  Future<SystemTimeChangeSignal?> takePendingSystemTimeChange();

  Future<void> requestPermissions();

  Future<bool> requestExactAlarmPermission();

  Future<void> openNotificationSettings();

  Future<void> openBatteryOptimizationSettings();

  Future<void> openFullScreenIntentSettings();

  Future<SystemNotificationSound?> pickSystemNotificationSound({
    String? existingUri,
  });

  Future<void> sendTestNotification({
    required ReminderSettings settings,
    required ExercisePlan? plan,
  });

  Future<ReminderSyncState> sync({
    required ReminderSettings settings,
    required DateTime requestedStartAt,
    required ExercisePlan? plan,
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
  Future<void> clearDeliveredNotifications() async {}

  @override
  Future<SystemTimeChangeSignal?> takePendingSystemTimeChange() async => null;

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<bool> requestExactAlarmPermission() async => false;

  @override
  Future<void> openBatteryOptimizationSettings() async {}

  @override
  Future<void> openFullScreenIntentSettings() async {}

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<SystemNotificationSound?> pickSystemNotificationSound({
    String? existingUri,
  }) async {
    return null;
  }

  @override
  Future<void> sendTestNotification({
    required ReminderSettings settings,
    required ExercisePlan? plan,
  }) async {}

  @override
  Future<ReminderSyncState> sync({
    required ReminderSettings settings,
    required DateTime requestedStartAt,
    required ExercisePlan? plan,
  }) async {
    if (!settings.notificationsEnabled || plan == null) {
      return const ReminderSyncState.empty();
    }

    final schedule = ReminderTimeline.buildSchedule(
      requestedStartAt: requestedStartAt,
      settings: settings,
      maxEntries: 1,
      horizon: const Duration(days: 1),
    );

    return ReminderSyncState(
      requestedReminderCount: schedule.length,
      pendingRequestCount: schedule.length,
      scheduledReminders: [
        for (var index = 0; index < schedule.length; index += 1)
          ScheduledReminderEntry(
            notificationId: 1000 + index,
            scheduledAt: schedule[index],
          ),
      ],
      usesExactScheduling: false,
      usesFullScreenIntent: false,
      notificationsPermissionAtSync: true,
      syncedAt: DateTime.now(),
      nextReminderAt: schedule.isEmpty ? null : schedule.first,
    );
  }
}

class LocalNotificationReminderScheduler implements ReminderScheduler {
  LocalNotificationReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'stretch_reminders';
  static const _channelName = 'OfficeRelief reminders';
  static const _channelDescription = 'Reminders to pause, stretch, and reset';
  static const _channelVersion = 'v5';
  static const _managedChannelPrefix = '${_channelId}_${_channelVersion}_';
  static const _notificationBaseId = 1000;
  static const _testNotificationId = 999;
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
      appName: 'OfficeRelief',
      appUserModelId: 'com.lskram.officerelief',
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

    bool? fullScreenIntentEnabled;
    try {
      fullScreenIntentEnabled = await _settingsChannel.invokeMethod<bool>(
        'canUseFullScreenIntent',
      );
    } catch (error) {
      debugPrint('Failed to read full-screen intent state: $error');
    }

    return ReminderDiagnostics.android(
      notificationsEnabled: notificationsEnabled,
      ignoresBatteryOptimizations: ignoresBatteryOptimizations,
      exactAlarmsEnabled: exactAlarmsEnabled,
      fullScreenIntentEnabled: fullScreenIntentEnabled,
      );
  }

  @override
  Future<void> clearDeliveredNotifications() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _settingsChannel.invokeMethod<void>('clearActiveNotifications');
        return;
      } catch (error) {
        debugPrint('Failed to clear active notifications natively: $error');
      }
    }

    final activeIds = await _readManagedActiveNotificationIds();
    for (final notificationId in activeIds) {
      await _plugin.cancel(id: notificationId);
    }
  }

  @override
  Future<SystemTimeChangeSignal?> takePendingSystemTimeChange() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      final rawSignal = await _settingsChannel.invokeMapMethod<String, Object?>(
        'takePendingTimeChangeSignal',
      );
      if (rawSignal == null) {
        return null;
      }

      return SystemTimeChangeSignal.fromJson(rawSignal);
    } catch (error) {
      debugPrint('Failed to read pending time change signal: $error');
      return null;
    }
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
  Future<void> openFullScreenIntentSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _settingsChannel.invokeMethod<void>('openFullScreenIntentSettings');
    } catch (error) {
      debugPrint('Failed to open full-screen intent settings: $error');
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
  Future<ReminderSyncState> sync({
    required ReminderSettings settings,
    required DateTime requestedStartAt,
    required ExercisePlan? plan,
  }) async {
    final syncedAt = DateTime.now();
    final notificationsPermissionAtSync = await _readNotificationsEnabled();
    final retainChannelId = settings.notificationsEnabled && plan != null
        ? _resolveChannelId(settings)
        : null;

    if (!settings.notificationsEnabled ||
        plan == null ||
        !ReminderTimeline.hasValidWindow(settings)) {
      await _cancelManagedNotifications();
      await _cleanupManagedChannels(retainChannelId: retainChannelId);
      return ReminderSyncState(
        requestedReminderCount: 0,
        pendingRequestCount: 0,
        scheduledReminders: const <ScheduledReminderEntry>[],
        usesExactScheduling: false,
        usesFullScreenIntent: false,
        notificationsPermissionAtSync: notificationsPermissionAtSync,
        syncedAt: syncedAt,
      );
    }

    final program = plan;

    final canUseExactAlarms = await _canScheduleExactAlarms();
    final canUseFullScreenIntent = await _canUseFullScreenIntent();
    final usesExactScheduling =
        settings.alertMode.prefersExactScheduling && canUseExactAlarms;
    final usesFullScreenIntent =
        usesExactScheduling &&
        settings.alertMode.prefersFullScreenIntent &&
        canUseFullScreenIntent;
    final safeRequestedStartAt = requestedStartAt.isAfter(syncedAt)
        ? requestedStartAt
        : syncedAt.add(const Duration(seconds: 1));
    final schedule = ReminderTimeline.buildSchedule(
      requestedStartAt: safeRequestedStartAt,
      settings: settings,
      maxEntries: _maxScheduledNotifications,
    );
    if (schedule.isEmpty) {
      return ReminderSyncState(
        requestedReminderCount: 0,
        pendingRequestCount: 0,
        scheduledReminders: const <ScheduledReminderEntry>[],
        usesExactScheduling: usesExactScheduling,
        usesFullScreenIntent: usesFullScreenIntent,
        notificationsPermissionAtSync: notificationsPermissionAtSync,
        syncedAt: syncedAt,
        lastError: 'No reminder slots were generated for the current settings.',
      );
    }
    final channelId = _resolveChannelId(settings);
    final details = _buildNotificationDetails(
      settings: settings,
      channelId: channelId,
      usesFullScreenIntent: usesFullScreenIntent,
    );
    await _plugin.cancel(id: _testNotificationId);

    try {
      for (var index = 0; index < schedule.length; index += 1) {
        final scheduledAt = schedule[index];
        await _plugin.zonedSchedule(
          id: _notificationBaseId + index,
          title: ReminderNotificationCopy.reminderTitle,
          body: ReminderNotificationCopy.reminderBody(
            plan: program,
            settings: settings,
          ),
          scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
          notificationDetails: details,
          payload: jsonEncode(
            ReminderLaunchPayload(
              planId: plan.id,
              reminderAt: scheduledAt,
              alertMode: settings.alertMode,
            ).toJson(),
          ),
          androidScheduleMode: usesExactScheduling
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      await _cancelManagedNotifications(startIndex: schedule.length);
      await _cleanupManagedChannels(retainChannelId: channelId);
    } catch (error) {
      if (_isInvalidNotificationIconError(error)) {
        debugPrint(
          'Reminder schedule hit invalid Android icon resource. Retrying without an explicit small icon: $error',
        );
        try {
          await _cancelManagedNotifications();
          final fallbackDetails = _buildNotificationDetails(
            settings: settings,
            channelId: channelId,
            usesFullScreenIntent: usesFullScreenIntent,
            icon: null,
          );
          for (var index = 0; index < schedule.length; index += 1) {
            final scheduledAt = schedule[index];
            await _plugin.zonedSchedule(
              id: _notificationBaseId + index,
              title: ReminderNotificationCopy.reminderTitle,
              body: ReminderNotificationCopy.reminderBody(
                plan: program,
                settings: settings,
              ),
              scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
              notificationDetails: fallbackDetails,
              payload: jsonEncode(
                ReminderLaunchPayload(
                  planId: plan.id,
                  reminderAt: scheduledAt,
                  alertMode: settings.alertMode,
                ).toJson(),
              ),
              androidScheduleMode: usesExactScheduling
                  ? AndroidScheduleMode.exactAllowWhileIdle
                  : AndroidScheduleMode.inexactAllowWhileIdle,
            );
          }

          await _cancelManagedNotifications(startIndex: schedule.length);
          await _cleanupManagedChannels(retainChannelId: channelId);
        } catch (fallbackError) {
          final pendingRequests = await _readManagedPendingRequests();
          return _buildSyncState(
            schedule: schedule,
            pendingRequests: pendingRequests,
            usesExactScheduling: usesExactScheduling,
            usesFullScreenIntent: usesFullScreenIntent,
            notificationsPermissionAtSync: notificationsPermissionAtSync,
            syncedAt: syncedAt,
            lastError:
                'Failed to schedule reminders after invalid icon fallback: $fallbackError',
          );
        }
      } else {
        final pendingRequests = await _readManagedPendingRequests();
        return _buildSyncState(
          schedule: schedule,
          pendingRequests: pendingRequests,
          usesExactScheduling: usesExactScheduling,
          usesFullScreenIntent: usesFullScreenIntent,
          notificationsPermissionAtSync: notificationsPermissionAtSync,
          syncedAt: syncedAt,
          lastError: 'Failed to schedule reminders: $error',
        );
      }
    }

    final pendingRequests = await _readManagedPendingRequests();
    final syncState = _buildSyncState(
      schedule: schedule,
      pendingRequests: pendingRequests,
      usesExactScheduling: usesExactScheduling,
      usesFullScreenIntent: usesFullScreenIntent,
      notificationsPermissionAtSync: notificationsPermissionAtSync,
      syncedAt: syncedAt,
    );

    if (syncState.needsRepair) {
      return syncState.copyWith(
        lastError:
            'Reminder queue is empty after scheduling. A repair sync is required.',
      );
    }

    return syncState;
  }

  @override
  Future<void> sendTestNotification({
    required ReminderSettings settings,
    required ExercisePlan? plan,
  }) async {
    await _requestPermissionsIfNeeded();
    final program = plan;

    final channelId = _resolveChannelId(settings);
    final usesFullScreenIntent =
        settings.alertMode.prefersFullScreenIntent &&
        settings.alertMode.prefersExactScheduling &&
        await _canUseFullScreenIntent() &&
        await _canScheduleExactAlarms();
    final details = _buildNotificationDetails(
      settings: settings,
      channelId: channelId,
      usesFullScreenIntent: usesFullScreenIntent,
    );

    try {
      await _plugin.show(
        id: _testNotificationId,
        title: ReminderNotificationCopy.testTitle,
        body: ReminderNotificationCopy.testBody(plan: program),
        notificationDetails: details,
        payload: jsonEncode(
          ReminderLaunchPayload(
            planId: program?.id,
            alertMode: settings.alertMode,
            isTest: true,
          ).toJson(),
        ),
      );
    } catch (error) {
      if (!_isInvalidNotificationIconError(error)) {
        rethrow;
      }

      debugPrint(
        'Immediate notification hit invalid Android icon resource. Retrying without an explicit small icon: $error',
      );
      final fallbackDetails = _buildNotificationDetails(
        settings: settings,
        channelId: channelId,
        usesFullScreenIntent: usesFullScreenIntent,
        icon: null,
      );
      await _plugin.show(
        id: _testNotificationId,
        title: ReminderNotificationCopy.testTitle,
        body: ReminderNotificationCopy.testBody(plan: program),
        notificationDetails: fallbackDetails,
        payload: jsonEncode(
          ReminderLaunchPayload(
            planId: program?.id,
            alertMode: settings.alertMode,
            isTest: true,
          ).toJson(),
        ),
      );
    }
  }

  bool _isInvalidNotificationIconError(Object error) {
    if (error is PlatformException && error.code == 'invalid_icon') {
      return true;
    }

    final message = error.toString();
    return message.contains('invalid_icon') ||
        message.contains(_notificationSmallIcon);
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

  Future<void> _cancelManagedNotifications({int startIndex = 0}) async {
    if (startIndex == 0) {
      await _plugin.cancel(id: _testNotificationId);
    }

    for (var index = startIndex; index < _maxScheduledNotifications; index += 1) {
      await _plugin.cancel(id: _notificationBaseId + index);
    }
  }

  ReminderSyncState _buildSyncState({
    required List<DateTime> schedule,
    required List<PendingNotificationRequest> pendingRequests,
    required bool usesExactScheduling,
    required bool usesFullScreenIntent,
    required bool? notificationsPermissionAtSync,
    required DateTime syncedAt,
    String? lastError,
  }) {
    final pendingIds = pendingRequests.map((request) => request.id).toSet();

    return ReminderSyncState(
      requestedReminderCount: schedule.length,
      pendingRequestCount: pendingRequests.length,
      scheduledReminders: [
        for (var index = 0; index < schedule.length; index += 1)
          if (pendingIds.contains(_notificationBaseId + index))
            ScheduledReminderEntry(
              notificationId: _notificationBaseId + index,
              scheduledAt: schedule[index],
            ),
      ],
      usesExactScheduling: usesExactScheduling,
      usesFullScreenIntent: usesFullScreenIntent,
      notificationsPermissionAtSync: notificationsPermissionAtSync,
      syncedAt: syncedAt,
      nextReminderAt: schedule.isEmpty ? null : schedule.first,
      lastError: lastError,
    );
  }

  Future<List<PendingNotificationRequest>> _readManagedPendingRequests() async {
    for (var attempt = 0; attempt < 3; attempt += 1) {
      final pendingRequests = await _plugin.pendingNotificationRequests();
      final managedRequests = pendingRequests
          .where(
            (request) =>
                request.id >= _notificationBaseId &&
                request.id < (_notificationBaseId + _maxScheduledNotifications),
          )
          .toList(growable: false);

      if (managedRequests.isNotEmpty || attempt == 2) {
        return managedRequests;
      }

      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    return const <PendingNotificationRequest>[];
  }

  Future<List<int>> _readManagedActiveNotificationIds() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const <int>[];
    }

    try {
      final rawNotifications = await _settingsChannel.invokeMethod<List<Object?>>(
        'getActiveNotifications',
      );
      if (rawNotifications == null) {
        return const <int>[];
      }

      final managedIds = <int>{};
      for (final entry in rawNotifications) {
        if (entry is! Map) {
          continue;
        }

        final notificationId = entry['id'];
        if (notificationId is! int) {
          continue;
        }

        final channelId = entry['channelId'] as String?;
        final isManagedReminderId =
            notificationId == _testNotificationId ||
            (notificationId >= _notificationBaseId &&
                notificationId < (_notificationBaseId + _maxScheduledNotifications));
        final isManagedReminderChannel =
            channelId != null && channelId.startsWith(_managedChannelPrefix);

        if (isManagedReminderId || isManagedReminderChannel) {
          managedIds.add(notificationId);
        }
      }

      return managedIds.toList(growable: false);
    } catch (error) {
      debugPrint('Failed to read active reminder notifications: $error');
      return const <int>[];
    }
  }

  NotificationDetails _buildNotificationDetails({
    required ReminderSettings settings,
    required String channelId,
    required bool usesFullScreenIntent,
    String? icon = _notificationSmallIcon,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: icon,
        importance: Importance.max,
        priority: Priority.max,
        ticker: 'OfficeRelief reminder',
        playSound: settings.soundEnabled,
        sound: _resolveAndroidSound(settings),
        enableVibration: settings.vibrationEnabled,
        vibrationPattern: settings.vibrationEnabled
            ? _resolveVibrationPattern(settings.vibrationLevel)
            : null,
        visibility: NotificationVisibility.public,
        category: settings.alertMode.prefersExactScheduling
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        autoCancel: false,
        channelShowBadge: false,
        fullScreenIntent: usesFullScreenIntent,
        audioAttributesUsage: settings.alertMode.prefersExactScheduling
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
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
      'alertMode': settings.alertMode.name,
      'soundEnabled': settings.soundEnabled,
      'vibrationEnabled': settings.vibrationEnabled,
      'vibrationLevel': settings.vibrationLevel.name,
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

  Future<bool?> _readFullScreenIntentCapability() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      return await _settingsChannel.invokeMethod<bool>('canUseFullScreenIntent');
    } catch (error) {
      debugPrint('Failed to inspect full-screen intent capability: $error');
      return null;
    }
  }

  Future<bool> _canUseFullScreenIntent() async {
    return await _readFullScreenIntentCapability() ?? true;
  }

  Future<bool?> _readNotificationsEnabled() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      return await _androidPlugin?.areNotificationsEnabled();
    } catch (error) {
      debugPrint('Failed to inspect notification permission state: $error');
      return null;
    }
  }

  Int64List _resolveVibrationPattern(VibrationLevel level) {
    switch (level) {
      case VibrationLevel.light:
        return Int64List.fromList(const [0, 140, 90, 140]);
      case VibrationLevel.medium:
        return Int64List.fromList(const [0, 260, 120, 260, 120, 260]);
      case VibrationLevel.strong:
        return Int64List.fromList(const [0, 420, 160, 420, 160, 420]);
    }
  }

  void _recordNotificationPayload(String? payload) {
    _pendingNotificationPayload = payload;
    _notificationResponsesController.add(payload);
  }
}
