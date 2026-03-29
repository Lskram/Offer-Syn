import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_state.dart';
import '../models/app_models.dart';

const _automationChannel = MethodChannel('office_stretch_app/device_automation');
const _settingsChannel = MethodChannel('office_stretch_app/device_settings');

class DeviceAutomationCommand {
  const DeviceAutomationCommand({
    required this.action,
    required this.alertMode,
    required this.intervalMinutes,
    required this.delayMinutes,
    required this.delaySeconds,
    required this.activeStart,
    required this.activeEnd,
  });

  final String action;
  final AlertMode alertMode;
  final int intervalMinutes;
  final int delayMinutes;
  final int delaySeconds;
  final TimeOfDay activeStart;
  final TimeOfDay activeEnd;

  factory DeviceAutomationCommand.fromMap(Map<String, Object?> map) {
    return DeviceAutomationCommand(
      action: map['action']! as String,
      alertMode: map['alertMode'] == null
          ? AlertMode.notification
          : AlertMode.values.byName(map['alertMode']! as String),
      intervalMinutes: map['intervalMinutes'] as int? ?? 1,
      delayMinutes: map['delayMinutes'] as int? ?? 1,
      delaySeconds: map['delaySeconds'] as int? ?? 8,
      activeStart: TimeOfDay(
        hour: map['startHour'] as int? ?? 0,
        minute: map['startMinute'] as int? ?? 0,
      ),
      activeEnd: TimeOfDay(
        hour: map['endHour'] as int? ?? 23,
        minute: map['endMinute'] as int? ?? 59,
      ),
    );
  }
}

Future<DeviceAutomationCommand?> takePendingDeviceAutomationCommand() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return null;
  }

  final raw = await _automationChannel.invokeMapMethod<String, Object?>(
    'takePendingAutomationCommand',
  );
  if (raw == null) {
    return null;
  }

  return DeviceAutomationCommand.fromMap(raw);
}

Future<void> runPendingDeviceAutomation(AppState appState) async {
  final command = await takePendingDeviceAutomationCommand();
  if (command == null) {
    return;
  }

  _emitAutomationLog(
    'AUTOMATION_STEP action=${command.action} mode=${command.alertMode.name}',
  );

  const profile = UserProfile(
    painSelections: [
      PainSelection(
        area: PainArea.neckShoulders,
        level: PainLevel.medium,
        selectedExerciseIds: <String>[],
      ),
    ],
    workHours: WorkHours.fourToSix,
    stretchHabit: StretchHabit.sometimes,
  );

  await _applyAutomationBaseline(
    appState: appState,
    command: command,
    profile: profile,
  );

  switch (command.action) {
    case 'prepareScheduledReminder':
      await _prepareScheduledReminder(appState, command);
      return;
    case 'postImmediateNotification':
      await _postImmediateNotification(appState, command);
      return;
    case 'armImmediateNotification':
      await _armImmediateNotification(appState, command);
      return;
    default:
      _emitAutomationLog('AUTOMATION_SKIPPED unsupported=${command.action}');
      return;
  }
}

void _emitAutomationLog(String message) {
  debugPrint(message);
  developer.log(message, name: 'OfficeReliefAutomation');
}

Future<void> _applyAutomationBaseline({
  required AppState appState,
  required DeviceAutomationCommand command,
  required UserProfile profile,
}) async {
  // Device scripts grant runtime permission from ADB before launch.
  // Avoid requesting permissions again here because that can stall
  // automation before the Flutter UI is fully running on emulators.
  await appState.refreshReminderDiagnostics();
  _emitAutomationLog('AUTOMATION_STEP diagnostics_refreshed');

  appState.savePlan(
    profile: profile,
    intervalMinutes: command.intervalMinutes,
    activeStart: command.activeStart,
    activeEnd: command.activeEnd,
    allowBelowMinimumInterval: true,
  );
  appState.updateNotificationsEnabled(true);
  appState.updateAlertMode(command.alertMode);
  await appState.waitForIdle();
  _emitAutomationLog('AUTOMATION_STEP settings_applied');
}

Future<void> _prepareScheduledReminder(
  AppState appState,
  DeviceAutomationCommand command,
) async {
  appState.snoozeReminder(command.delayMinutes);
  await appState.waitForIdle();
  await appState.refreshReminderDiagnostics();

  final syncState = appState.reminderSyncState;
  final nextReminderAt = syncState.nextReminderAt;

  if (nextReminderAt == null || syncState.pendingRequestCount <= 0) {
    _emitAutomationLog(
      'SCHEDULE_ERROR '
      'mode=${command.alertMode.name} '
      'pending=${syncState.pendingRequestCount} '
      'error=${syncState.lastError ?? 'none'}',
    );
    return;
  }

  _emitAutomationLog(
    'SCHEDULE_READY '
    'mode=${command.alertMode.name} '
    'nextEpochMs=${nextReminderAt.millisecondsSinceEpoch} '
    'nextIso=${nextReminderAt.toIso8601String()} '
    'exact=${syncState.usesExactScheduling} '
    'fullScreen=${syncState.usesFullScreenIntent} '
    'pending=${syncState.pendingRequestCount} '
    'permission=${syncState.notificationsPermissionAtSync ?? 'null'}',
  );
}

Future<void> _postImmediateNotification(
  AppState appState,
  DeviceAutomationCommand command,
) async {
  await appState.sendTestNotificationNow();
  await appState.refreshReminderDiagnostics();
  await _emitImmediateReady(appState, command);
}

Future<void> _armImmediateNotification(
  AppState appState,
  DeviceAutomationCommand command,
) async {
  final fireAt = DateTime.now().add(Duration(seconds: command.delaySeconds));
  final syncState = appState.reminderSyncState;

  _emitAutomationLog(
    'IMMEDIATE_ARMED '
    'mode=${command.alertMode.name} '
    'fireEpochMs=${fireAt.millisecondsSinceEpoch} '
    'fireIso=${fireAt.toIso8601String()} '
    'exact=${syncState.usesExactScheduling} '
    'fullScreen=${syncState.usesFullScreenIntent} '
    'permission=${syncState.notificationsPermissionAtSync ?? 'null'}',
  );

  unawaited(
    Future<void>.delayed(Duration(seconds: command.delaySeconds), () async {
      await appState.sendTestNotificationNow();
      await appState.refreshReminderDiagnostics();
      await _emitImmediateReady(appState, command);
    }),
  );
}

Future<Map<String, Object?>?> _readActiveTestNotification() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return null;
  }

  for (var attempt = 0; attempt < 10; attempt += 1) {
    final raw = await _settingsChannel.invokeListMethod<dynamic>(
      'getActiveNotifications',
    );
    final notifications = (raw ?? const <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map((entry) => entry.cast<String, Object?>())
        .toList(growable: false);
    final match = notifications.where((entry) => entry['id'] == 999);
    if (match.isNotEmpty) {
      return match.first;
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  return null;
}

Future<void> _emitImmediateReady(
  AppState appState,
  DeviceAutomationCommand command,
) async {
  final syncState = appState.reminderSyncState;
  final activeNotification = await _readActiveTestNotification();
  if (activeNotification == null) {
    _emitAutomationLog(
      'IMMEDIATE_ERROR '
      'mode=${command.alertMode.name} '
      'error=no_active_test_notification',
    );
    return;
  }

  _emitAutomationLog(
    'IMMEDIATE_READY '
    'mode=${command.alertMode.name} '
    'exact=${syncState.usesExactScheduling} '
    'fullScreen=${syncState.usesFullScreenIntent} '
    'permission=${syncState.notificationsPermissionAtSync ?? 'null'} '
    'category=${activeNotification['category'] ?? 'null'} '
    'hasFullScreenIntent=${activeNotification['hasFullScreenIntent'] ?? 'null'} '
    'title=${_sanitizeLogValue(activeNotification['title'])}',
  );
}

String _sanitizeLogValue(Object? value) {
  return value?.toString().replaceAll(RegExp(r'\s+'), '_') ?? 'null';
}
