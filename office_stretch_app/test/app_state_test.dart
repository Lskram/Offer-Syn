import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/data/exercise_catalog.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/models/persisted_app_data.dart';
import 'package:office_stretch_app/models/reminder_diagnostics.dart';
import 'package:office_stretch_app/models/reminder_sync_state.dart';
import 'package:office_stretch_app/models/system_notification_sound.dart';
import 'package:office_stretch_app/services/app_persistence.dart';
import 'package:office_stretch_app/services/reminder_scheduler.dart';
import 'package:office_stretch_app/services/reminder_timeline.dart';

class TestReminderScheduler implements ReminderScheduler {
  TestReminderScheduler(
    this.now, {
    this.confirmPendingRequests = true,
    this.notificationsPermissionAtSync = true,
    this.maxEntries = 4,
    String? initialPayload,
  }) : _pendingPayload = initialPayload;

  final DateTime Function() now;
  final bool confirmPendingRequests;
  final bool? notificationsPermissionAtSync;
  final int maxEntries;
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
  Future<ReminderDiagnostics> diagnostics() async {
    return const ReminderDiagnostics.unsupported();
  }

  @override
  Future<void> initialize() async {}

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
  Future<void> requestPermissions() async {}

  @override
  Future<bool> requestExactAlarmPermission() async => false;

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
      maxEntries: maxEntries,
      horizon: const Duration(days: 1),
      now: now(),
    );

    return ReminderSyncState(
      requestedReminderCount: schedule.length,
      pendingRequestCount: confirmPendingRequests ? schedule.length : 0,
      scheduledReminders: confirmPendingRequests
          ? [
              for (var index = 0; index < schedule.length; index += 1)
                ScheduledReminderEntry(
                  notificationId: 1000 + index,
                  scheduledAt: schedule[index],
                ),
            ]
          : const <ScheduledReminderEntry>[],
      usesExactScheduling: false,
      usesFullScreenIntent: false,
      notificationsPermissionAtSync: notificationsPermissionAtSync,
      syncedAt: now(),
      nextReminderAt: schedule.isEmpty ? null : schedule.first,
    );
  }
}

void main() {
  UserProfile buildProfile() {
    return const UserProfile(
      painSelections: [
        PainSelection(
          area: PainArea.neckShoulders,
          level: PainLevel.low,
          selectedExerciseIds: <String>[],
        ),
      ],
      workHours: WorkHours.fourToSix,
      stretchHabit: StretchHabit.sometimes,
    );
  }

  test('logs each missed reminder slot after later reminders pass', () async {
    var now = DateTime(2026, 3, 18, 8, 5);
    final state = AppState(
      persistence: InMemoryAppPersistence(),
      reminderScheduler: TestReminderScheduler(() => now),
      now: () => now,
    );

    await state.initialize();
    state.completeQuestionnaire(buildProfile());
    await state.settleSideEffects();

    expect(state.nextReminderAt, DateTime(2026, 3, 18, 9));

    now = DateTime(2026, 3, 18, 11, 5);
    state.handleAppResumed();
    await state.settleSideEffects();

    final missedLogs = state.logs
        .where((log) => log.status == ExerciseStatus.missed)
        .toList(growable: false);

    expect(missedLogs, hasLength(2));
    expect(missedLogs[0].reminderAt, DateTime(2026, 3, 18, 10));
    expect(missedLogs[1].reminderAt, DateTime(2026, 3, 18, 9));
    expect(state.missedRemindersToday, 2);
    expect(state.nextReminderAt, DateTime(2026, 3, 18, 12));
  });

  test(
    'does not mark a reminder missed when an exercise was completed in time',
    () async {
      var now = DateTime(2026, 3, 18, 8, 5);
      final state = AppState(
        persistence: InMemoryAppPersistence(),
        reminderScheduler: TestReminderScheduler(() => now),
        now: () => now,
      );

      await state.initialize();
      state.completeQuestionnaire(buildProfile());
      await state.settleSideEffects();

      now = DateTime(2026, 3, 18, 9, 10);
      state.logExercise(
        state.activePlan!.exercises.first.exercise,
        ExerciseStatus.done,
      );
      await state.settleSideEffects();

      now = DateTime(2026, 3, 18, 10, 5);
      state.handleAppResumed();
      await state.settleSideEffects();

      final missedLogs = state.logs
          .where((log) => log.status == ExerciseStatus.missed)
          .toList(growable: false);

      expect(missedLogs, isEmpty);
      expect(state.nextReminderAt, DateTime(2026, 3, 18, 11));
    },
  );

  test(
    'does not mark reminders missed when scheduler cannot confirm pending requests',
    () async {
      var now = DateTime(2026, 3, 18, 8, 5);
      final state = AppState(
        persistence: InMemoryAppPersistence(),
        reminderScheduler: TestReminderScheduler(
          () => now,
          confirmPendingRequests: false,
        ),
        now: () => now,
      );

      await state.initialize();
      state.completeQuestionnaire(buildProfile());
      await state.settleSideEffects();

      now = DateTime(2026, 3, 18, 11, 5);
      state.handleAppResumed();
      await state.settleSideEffects();

      final missedLogs = state.logs
          .where((log) => log.status == ExerciseStatus.missed)
          .toList(growable: false);

      expect(missedLogs, isEmpty);
      expect(state.reminderSyncState.canTrustMissedInference, isFalse);
    },
  );

  test('savePlan updates the active plan and reminder schedule together', () async {
    final now = DateTime(2026, 3, 18, 8, 5);
    final state = AppState(
      persistence: InMemoryAppPersistence(),
      reminderScheduler: TestReminderScheduler(() => now),
      now: () => now,
    );

    await state.initialize();
    state.savePlan(
      profile: const UserProfile(
        painSelections: [
          PainSelection(
            area: PainArea.neckShoulders,
            level: PainLevel.high,
            selectedExerciseIds: <String>[],
          ),
          PainSelection(
            area: PainArea.upperBack,
            level: PainLevel.low,
            selectedExerciseIds: <String>[],
          ),
        ],
        workHours: WorkHours.moreThanNine,
        stretchHabit: StretchHabit.never,
      ),
      intervalMinutes: 30,
      activeStart: const TimeOfDay(hour: 18, minute: 0),
      activeEnd: const TimeOfDay(hour: 23, minute: 59),
    );
    await state.settleSideEffects();

    expect(state.activePlan?.groups, hasLength(2));
    expect(state.activePlan?.exerciseCount, 3);
    expect(state.settings.intervalMinutes, 30);
    expect(state.settings.activeStart, const TimeOfDay(hour: 18, minute: 0));
    expect(state.settings.activeEnd, const TimeOfDay(hour: 23, minute: 59));
    expect(state.nextReminderAt, DateTime(2026, 3, 18, 18));
  });

  test('updateAlertMode persists the selected reminder delivery mode', () async {
    final now = DateTime(2026, 3, 18, 8, 5);
    final state = AppState(
      persistence: InMemoryAppPersistence(),
      reminderScheduler: TestReminderScheduler(() => now),
      now: () => now,
    );

    await state.initialize();
    state.updateAlertMode(AlertMode.exactFullScreen);
    await state.settleSideEffects();

    expect(state.settings.alertMode, AlertMode.exactFullScreen);
  });

  test('initial reminder payload becomes a pending alarm launch', () async {
    final now = DateTime(2026, 3, 18, 8, 5);
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
        nextReminderAt: DateTime(2026, 3, 18, 9),
      ),
    );

    final state = AppState(
      persistence: persistence,
      reminderScheduler: TestReminderScheduler(
        () => now,
        initialPayload: jsonEncode(
          ReminderLaunchPayload(
            planId: plan.id,
            reminderAt: DateTime(2026, 3, 18, 9),
            alertMode: AlertMode.exactFullScreen,
          ).toJson(),
        ),
      ),
      now: () => now,
    );

    await state.initialize();

    final launch = state.consumePendingReminderLaunch();
    expect(launch, isNotNull);
    expect(launch!.plan.id, plan.id);
    expect(launch.alertMode, AlertMode.exactFullScreen);
    expect(launch.opensAlarmScreen, isTrue);
    expect(launch.reminderAt, DateTime(2026, 3, 18, 9));
  });

  test('dismissed reminders are not later marked missed for the same slot', () async {
    var now = DateTime(2026, 3, 18, 8, 5);
    final state = AppState(
      persistence: InMemoryAppPersistence(),
      reminderScheduler: TestReminderScheduler(() => now),
      now: () => now,
    );

    await state.initialize();
    state.completeQuestionnaire(buildProfile());
    await state.settleSideEffects();

    now = DateTime(2026, 3, 18, 9, 5);
    state.dismissPendingReminder(
      PendingReminderLaunch(
        plan: state.activePlan!,
        alertMode: AlertMode.exactFullScreen,
        reminderAt: DateTime(2026, 3, 18, 9),
      ),
    );
    await state.settleSideEffects();

    now = DateTime(2026, 3, 18, 11, 5);
    state.handleAppResumed();
    await state.settleSideEffects();

    expect(
      state.logs.any(
        (log) =>
            log.status == ExerciseStatus.skipped &&
            log.reminderAt == DateTime(2026, 3, 18, 9),
      ),
      isTrue,
    );
    expect(
      state.logs.any(
        (log) =>
            log.status == ExerciseStatus.missed &&
            log.reminderAt == DateTime(2026, 3, 18, 9),
      ),
      isFalse,
    );
  });
}
