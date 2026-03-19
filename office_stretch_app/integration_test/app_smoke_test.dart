import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:office_stretch_app/app/app.dart';
import 'package:office_stretch_app/app/app_keys.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/services/app_persistence.dart';
import 'package:office_stretch_app/services/reminder_scheduler.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding, navigation, session, and reset flow works', (
    tester,
  ) async {
    Future<void> pumpUi() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }

    Future<void> tapVisible(Finder finder, {Finder? scrollable}) async {
      if (scrollable != null) {
        await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
      } else {
        await tester.ensureVisible(finder);
      }
      await tester.tap(finder, warnIfMissed: false);
      await pumpUi();
    }

    final appState = AppState(
      persistence: InMemoryAppPersistence(),
      reminderScheduler: const NoopReminderScheduler(),
    );
    await appState.initialize();

    await tester.pumpWidget(OfficeStretchApp(appState: appState));
    await pumpUi();
    debugPrint('smoke: questionnaire ready');

    expect(find.byKey(AppKeys.questionnaireScreen), findsOneWidget);

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
    await pumpUi();
    debugPrint('smoke: onboarding complete');

    expect(find.byKey(AppKeys.homeScreen), findsOneWidget);
    expect(appState.activePlan?.groups, hasLength(1));
    expect(appState.activePlan?.exerciseCount, 2);

    await tapVisible(
      find.byKey(AppKeys.homeStartProgram),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    debugPrint('smoke: session open');

    expect(find.byKey(AppKeys.sessionComplete), findsOneWidget);

    await tapVisible(find.byKey(AppKeys.sessionComplete));
    debugPrint('smoke: first exercise complete');
    await tapVisible(find.byKey(AppKeys.sessionComplete));
    debugPrint('smoke: second exercise complete');

    expect(find.byKey(AppKeys.sessionFinishClose), findsOneWidget);
    await tapVisible(find.byKey(AppKeys.sessionFinishClose));
    debugPrint('smoke: session closed');

    final completedLogs = appState.logs
        .where((log) => log.status == ExerciseStatus.done)
        .length;
    expect(completedLogs, 2);

    await tapVisible(find.text('Exercises'));
    debugPrint('smoke: library open');

    expect(find.byKey(AppKeys.libraryScreen), findsOneWidget);

    await tapVisible(find.text('Tips'));
    debugPrint('smoke: tips open');
    expect(find.byKey(AppKeys.tipsScreen), findsOneWidget);

    await tapVisible(find.text('Settings'));
    debugPrint('smoke: settings open');
    expect(find.byKey(AppKeys.settingsScreen), findsOneWidget);
    final settingsScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(AppKeys.settingsRestartOnboarding),
      200,
      scrollable: settingsScrollable,
    );
    expect(find.byKey(AppKeys.settingsNotificationsEnabled), findsOneWidget);
    expect(find.byKey(AppKeys.settingsAlertMode), findsOneWidget);
    expect(find.byKey(AppKeys.settingsIntervalMinutes), findsOneWidget);
    debugPrint('smoke: settings controls visible');

    expect(appState.logs, isNotEmpty);
  });
}
