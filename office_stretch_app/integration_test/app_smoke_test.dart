import 'package:flutter/widgets.dart';
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
        painArea: PainArea.neckShoulders,
        painLevel: PainLevel.medium,
        workHours: WorkHours.fourToSix,
        stretchHabit: StretchHabit.sometimes,
      ),
    );
    await pumpUi();
    debugPrint('smoke: onboarding complete');

    expect(find.byKey(AppKeys.homeScreen), findsOneWidget);
    expect(appState.activeProgram?.id, 'neck-medium');

    await tapVisible(find.text('Exercises'));
    debugPrint('smoke: library open');

    expect(find.byKey(AppKeys.libraryScreen), findsOneWidget);

    await tapVisible(find.byKey(AppKeys.libraryStartProgram('neck-medium')));
    debugPrint('smoke: session open');

    expect(find.byKey(AppKeys.sessionScreen), findsOneWidget);

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

    await tapVisible(find.text('Tips'));
    debugPrint('smoke: tips open');
    expect(find.byKey(AppKeys.tipsScreen), findsOneWidget);

    await tapVisible(find.text('Settings'));
    debugPrint('smoke: settings open');
    expect(find.byKey(AppKeys.settingsScreen), findsOneWidget);
    final settingsScrollable = find.byType(Scrollable).first;

    await tapVisible(
      find.byKey(AppKeys.settingsNotificationsEnabled),
      scrollable: settingsScrollable,
    );
    expect(appState.settings.notificationsEnabled, isFalse);
    debugPrint('smoke: notifications off');

    await tapVisible(
      find.byKey(AppKeys.settingsNotificationsEnabled),
      scrollable: settingsScrollable,
    );
    expect(appState.settings.notificationsEnabled, isTrue);
    debugPrint('smoke: notifications on');

    await tapVisible(
      find.byKey(AppKeys.settingsIntervalMinutes),
      scrollable: settingsScrollable,
    );
    await tapVisible(find.textContaining('90').last);
    expect(appState.settings.intervalMinutes, 90);
    debugPrint('smoke: interval updated');

    await tapVisible(
      find.byKey(AppKeys.settingsRestartOnboarding),
      scrollable: find.byType(Scrollable).first,
    );
    debugPrint('smoke: onboarding reset');

    expect(find.byKey(AppKeys.questionnaireScreen), findsOneWidget);
    expect(appState.hasCompletedOnboarding, isFalse);
    expect(appState.logs, isEmpty);
  });
}
