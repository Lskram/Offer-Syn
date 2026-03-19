import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app_keys.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/screens/history_screen.dart';
import 'package:office_stretch_app/services/app_persistence.dart';
import 'package:office_stretch_app/services/reminder_scheduler.dart';
import 'package:office_stretch_app/widgets/office_relief_mascot.dart';

void main() {
  testWidgets('history screen shows empty state when there are no logs', (
    tester,
  ) async {
    final appState = AppState(
      persistence: InMemoryAppPersistence(),
      reminderScheduler: const NoopReminderScheduler(),
      now: () => DateTime(2026, 3, 19, 9),
    );
    await appState.initialize();

    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(appState: appState)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.historyScreen), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.byType(OfficeReliefMascot), findsOneWidget);
  });

  testWidgets('history screen renders grouped logs and summary content', (
    tester,
  ) async {
    var now = DateTime(2026, 3, 19, 9, 0);
    final appState = AppState(
      persistence: InMemoryAppPersistence(),
      reminderScheduler: const NoopReminderScheduler(),
      now: () => now,
    );
    await appState.initialize();
    appState.completeQuestionnaire(
      const UserProfile(
        painSelections: [
          PainSelection(
            area: PainArea.neckShoulders,
            level: PainLevel.medium,
            selectedExerciseIds: <String>[],
          ),
        ],
        workHours: WorkHours.fourToSix,
        stretchHabit: StretchHabit.sometimes,
      ),
    );
    await appState.settleSideEffects();

    final exercise = appState.activePlan!.exercises.first.exercise;
    appState.logExercise(exercise, ExerciseStatus.done);
    await appState.settleSideEffects();

    now = DateTime(2026, 3, 19, 10, 0);
    appState.snoozePendingReminder(
      PendingReminderLaunch(
        plan: appState.activePlan!,
        alertMode: AlertMode.exactFullScreen,
        reminderAt: DateTime(2026, 3, 19, 10, 0),
      ),
    );
    await appState.settleSideEffects();

    now = DateTime(2026, 3, 18, 15, 30);
    appState.logExercise(exercise, ExerciseStatus.skipped);
    await appState.settleSideEffects();

    now = DateTime(2026, 3, 19, 12, 0);
    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(appState: appState)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.historyScreen), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('18/03/2026'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
    expect(find.text(exercise.name), findsWidgets);
  });
}
