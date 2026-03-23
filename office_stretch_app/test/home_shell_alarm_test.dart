import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app_keys.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/data/exercise_catalog.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/models/persisted_app_data.dart';
import 'package:office_stretch_app/models/reminder_diagnostics.dart';
import 'package:office_stretch_app/models/reminder_sync_state.dart';
import 'package:office_stretch_app/models/system_time_change_signal.dart';
import 'package:office_stretch_app/models/system_notification_sound.dart';
import 'package:office_stretch_app/screens/home_shell.dart';
import 'package:office_stretch_app/services/app_persistence.dart';
import 'package:office_stretch_app/services/reminder_scheduler.dart';

class LaunchTestReminderScheduler implements ReminderScheduler {
  LaunchTestReminderScheduler({String? initialPayload})
    : _pendingPayload = initialPayload;

  final StreamController<String?> _responses =
      StreamController<String?>.broadcast();
  String? _pendingPayload;

  @override
  Stream<String?> get notificationResponses => _responses.stream;

  void emit(ReminderLaunchPayload payload) {
    _responses.add(jsonEncode(payload.toJson()));
  }

  @override
  String? takePendingNotificationPayload() {
    final payload = _pendingPayload;
    _pendingPayload = null;
    return payload;
  }

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
  Future<void> openNotificationSettings() async {}

  @override
  Future<void> openBatteryOptimizationSettings() async {}

  @override
  Future<void> openFullScreenIntentSettings() async {}

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
    return ReminderSyncState(
      requestedReminderCount: plan == null ? 0 : 1,
      pendingRequestCount: plan == null ? 0 : 1,
      scheduledReminders: plan == null
          ? const <ScheduledReminderEntry>[]
          : <ScheduledReminderEntry>[
              ScheduledReminderEntry(
                notificationId: 1000,
                scheduledAt: requestedStartAt,
              ),
            ],
      usesExactScheduling: settings.alertMode.prefersExactScheduling,
      usesFullScreenIntent: settings.alertMode.prefersFullScreenIntent,
      notificationsPermissionAtSync: true,
      syncedAt: requestedStartAt,
      nextReminderAt: plan == null ? null : requestedStartAt,
    );
  }
}

void main() {
  UserProfile buildProfile() {
    return const UserProfile(
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
  }

  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  testWidgets('full-screen reminder payload opens alarm screen then session', (
    tester,
  ) async {
    final profile = buildProfile();
    final plan = ExerciseCatalog.buildPlan(profile);
    final persistence = InMemoryAppPersistence();
    await persistence.save(
      PersistedAppData(
        profile: profile,
        settings: defaultReminderSettings.copyWith(
          alertMode: AlertMode.exactFullScreen,
        ),
        logs: const <ExerciseLog>[],
        nextReminderAt: DateTime(2026, 3, 19, 9),
      ),
    );
    final scheduler = LaunchTestReminderScheduler(
      initialPayload: jsonEncode(
        ReminderLaunchPayload(
          planId: plan.id,
          reminderAt: DateTime(2026, 3, 19, 9),
          alertMode: AlertMode.exactFullScreen,
        ).toJson(),
      ),
    );
    final appState = AppState(
      persistence: persistence,
      reminderScheduler: scheduler,
      now: () => DateTime(2026, 3, 19, 9),
    );
    await appState.initialize();

    await tester.pumpWidget(
      MaterialApp(home: HomeShell(appState: appState)),
    );
    await pumpUi(tester);

    expect(find.byKey(AppKeys.alarmScreen), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.alarmStart));
    await pumpUi(tester);

    expect(find.byKey(AppKeys.sessionScreen), findsOneWidget);
  });

  testWidgets('snoozing from alarm screen logs the reminder outcome', (
    tester,
  ) async {
    final profile = buildProfile();
    final plan = ExerciseCatalog.buildPlan(profile);
    final persistence = InMemoryAppPersistence();
    await persistence.save(
      PersistedAppData(
        profile: profile,
        settings: defaultReminderSettings.copyWith(
          alertMode: AlertMode.exactFullScreen,
        ),
        logs: const <ExerciseLog>[],
        nextReminderAt: DateTime(2026, 3, 19, 9),
      ),
    );
    final scheduler = LaunchTestReminderScheduler(
      initialPayload: jsonEncode(
        ReminderLaunchPayload(
          planId: plan.id,
          reminderAt: DateTime(2026, 3, 19, 9),
          alertMode: AlertMode.exactFullScreen,
        ).toJson(),
      ),
    );
    final now = DateTime(2026, 3, 19, 9);
    final appState = AppState(
      persistence: persistence,
      reminderScheduler: scheduler,
      now: () => now,
    );
    await appState.initialize();

    await tester.pumpWidget(
      MaterialApp(home: HomeShell(appState: appState)),
    );
    await pumpUi(tester);

    await tester.tap(find.byKey(AppKeys.alarmSnooze));
    await pumpUi(tester);

    expect(find.byKey(AppKeys.alarmScreen), findsNothing);
    expect(find.byKey(AppKeys.sessionScreen), findsNothing);
    expect(
      appState.logs.any(
        (log) =>
            log.status == ExerciseStatus.snoozed &&
            log.reminderAt == DateTime(2026, 3, 19, 9),
      ),
      isTrue,
    );
  });
}
