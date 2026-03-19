import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:office_stretch_app/app/app.dart';
import 'package:office_stretch_app/app/app_keys.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/data/exercise_catalog.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/models/persisted_app_data.dart';
import 'package:office_stretch_app/models/reminder_diagnostics.dart';
import 'package:office_stretch_app/models/reminder_sync_state.dart';
import 'package:office_stretch_app/models/system_notification_sound.dart';
import 'package:office_stretch_app/services/app_persistence.dart';
import 'package:office_stretch_app/services/reminder_scheduler.dart';

class _AlarmFlowScheduler implements ReminderScheduler {
  _AlarmFlowScheduler({String? initialPayload}) : _pendingPayload = initialPayload;

  String? _pendingPayload;

  @override
  Stream<String?> get notificationResponses => const Stream<String?>.empty();

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
  Future<SystemNotificationSound?> pickSystemNotificationSound({
    String? existingUri,
  }) async {
    return null;
  }

  @override
  Future<void> openBatteryOptimizationSettings() async {}

  @override
  Future<void> openFullScreenIntentSettings() async {}

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<bool> requestExactAlarmPermission() async => false;

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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Future<AppState> buildState({
    required DateTime now,
    required String initialPayload,
  }) async {
    final profile = buildProfile();
    final persistence = InMemoryAppPersistence();
    await persistence.save(
      PersistedAppData(
        profile: profile,
        settings: defaultReminderSettings.copyWith(
          alertMode: AlertMode.exactFullScreen,
        ),
        logs: const <ExerciseLog>[],
        nextReminderAt: DateTime(now.year, now.month, now.day, 9),
      ),
    );

    final state = AppState(
      persistence: persistence,
      reminderScheduler: _AlarmFlowScheduler(initialPayload: initialPayload),
      now: () => now,
    );
    await state.initialize();
    return state;
  }

  testWidgets('alarm screen start opens the exercise session', (
    tester,
  ) async {
    final now = DateTime(2026, 3, 19, 9);
    final plan = ExerciseCatalog.buildPlan(buildProfile());
    final appState = await buildState(
      now: now,
      initialPayload: jsonEncode(
        ReminderLaunchPayload(
          planId: plan.id,
          reminderAt: DateTime(2026, 3, 19, 9),
          alertMode: AlertMode.exactFullScreen,
        ).toJson(),
      ),
    );

    await tester.pumpWidget(OfficeStretchApp(appState: appState));
    await pumpUi(tester);

    expect(find.byKey(AppKeys.alarmScreen), findsOneWidget);
    await tester.tap(find.byKey(AppKeys.alarmStart));
    await pumpUi(tester);
    expect(find.byKey(AppKeys.sessionScreen), findsOneWidget);
  });

  testWidgets('alarm screen snooze writes a reminder log', (
    tester,
  ) async {
    final baseTime = DateTime(2026, 3, 19, 9);
    final plan = ExerciseCatalog.buildPlan(buildProfile());
    final appState = await buildState(
      now: baseTime,
      initialPayload: jsonEncode(
        ReminderLaunchPayload(
          planId: plan.id,
          reminderAt: DateTime(2026, 3, 19, 9),
          alertMode: AlertMode.exactFullScreen,
        ).toJson(),
      ),
    );

    await tester.pumpWidget(OfficeStretchApp(appState: appState));
    await pumpUi(tester);

    expect(find.byKey(AppKeys.alarmScreen), findsOneWidget);
    await tester.tap(find.byKey(AppKeys.alarmSnooze));
    await pumpUi(tester);
    expect(
      appState.logs.any(
        (log) =>
            log.status == ExerciseStatus.snoozed &&
            log.reminderAt == DateTime(2026, 3, 19, 9),
      ),
      isTrue,
    );
  });

  testWidgets('alarm screen dismiss writes a reminder log', (
    tester,
  ) async {
    final baseTime = DateTime(2026, 3, 19, 9);
    final plan = ExerciseCatalog.buildPlan(buildProfile());
    final appState = await buildState(
      now: baseTime,
      initialPayload: jsonEncode(
        ReminderLaunchPayload(
          planId: plan.id,
          reminderAt: DateTime(2026, 3, 19, 10),
          alertMode: AlertMode.exactFullScreen,
        ).toJson(),
      ),
    );

    await tester.pumpWidget(OfficeStretchApp(appState: appState));
    await pumpUi(tester);

    expect(find.byKey(AppKeys.alarmScreen), findsOneWidget);
    await tester.ensureVisible(find.byKey(AppKeys.alarmDismiss));
    await tester.tap(find.byKey(AppKeys.alarmDismiss), warnIfMissed: false);
    await pumpUi(tester);
    expect(
      appState.logs.any(
        (log) =>
            log.status == ExerciseStatus.skipped &&
            log.reminderAt == DateTime(2026, 3, 19, 10),
      ),
      isTrue,
    );
  });
}
