import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/models/reminder_diagnostics.dart';
import 'package:office_stretch_app/models/system_notification_sound.dart';
import 'package:office_stretch_app/services/app_persistence.dart';
import 'package:office_stretch_app/services/reminder_scheduler.dart';
import 'package:office_stretch_app/services/reminder_timeline.dart';

class TestReminderScheduler implements ReminderScheduler {
  TestReminderScheduler(this.now);

  final DateTime Function() now;

  @override
  Stream<String?> get notificationResponses => const Stream<String?>.empty();

  @override
  String? takePendingNotificationPayload() => null;

  @override
  Future<ReminderDiagnostics> diagnostics() async {
    return const ReminderDiagnostics.unsupported();
  }

  @override
  Future<void> initialize() async {}

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
  Future<void> requestPermissions() async {}

  @override
  Future<bool> requestExactAlarmPermission() async => false;

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
      now: now(),
    );
  }
}

void main() {
  UserProfile buildProfile() {
    return const UserProfile(
      painArea: PainArea.neckShoulders,
      painLevel: PainLevel.low,
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
        state.activeProgram!.exercises.first,
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
}
