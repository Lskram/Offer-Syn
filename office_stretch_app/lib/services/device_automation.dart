import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_state.dart';
import '../models/app_models.dart';

const _automationChannel = MethodChannel('office_stretch_app/device_automation');

class DeviceAutomationCommand {
  const DeviceAutomationCommand({
    required this.action,
    required this.alertMode,
    required this.intervalMinutes,
    required this.delayMinutes,
    required this.activeStart,
    required this.activeEnd,
  });

  final String action;
  final AlertMode alertMode;
  final int intervalMinutes;
  final int delayMinutes;
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

  if (command.action != 'prepareScheduledReminder') {
    _emitAutomationLog('AUTOMATION_SKIPPED unsupported=${command.action}');
    return;
  }

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

  await appState.requestNotificationPermission();
  await appState.waitForIdle();
  _emitAutomationLog('AUTOMATION_STEP permission_requested');

  appState.savePlan(
    profile: profile,
    intervalMinutes: command.intervalMinutes,
    activeStart: command.activeStart,
    activeEnd: command.activeEnd,
  );
  appState.updateNotificationsEnabled(true);
  appState.updateAlertMode(command.alertMode);
  await appState.waitForIdle();
  _emitAutomationLog('AUTOMATION_STEP settings_applied');

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

void _emitAutomationLog(String message) {
  debugPrint(message);
  developer.log(message, name: 'OfficeReliefAutomation');
}
