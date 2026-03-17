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
    Future<void> tapVisible(Finder finder, {Finder? scrollable}) async {
      if (scrollable != null) {
        await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
      } else {
        await tester.ensureVisible(finder);
      }
      await tester.tap(finder, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    final appState = AppState(
      persistence: InMemoryAppPersistence(),
      reminderScheduler: const NoopReminderScheduler(),
    );
    await appState.initialize();

    await tester.pumpWidget(OfficeStretchApp(appState: appState));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.questionnaireScreen), findsOneWidget);

    appState.completeQuestionnaire(
      const UserProfile(
        painArea: PainArea.neckShoulders,
        painLevel: PainLevel.medium,
        workHours: WorkHours.fourToSix,
        stretchHabit: StretchHabit.sometimes,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.homeScreen), findsOneWidget);
    expect(appState.activeProgram?.id, 'neck-medium');

    await tapVisible(find.text('Exercises'));

    expect(find.byKey(AppKeys.libraryScreen), findsOneWidget);

    await tapVisible(find.byKey(AppKeys.libraryStartProgram('neck-medium')));

    expect(find.byKey(AppKeys.sessionScreen), findsOneWidget);

    await tapVisible(find.byKey(AppKeys.sessionComplete));
    await tapVisible(find.byKey(AppKeys.sessionComplete));

    expect(find.byKey(AppKeys.sessionFinishClose), findsOneWidget);
    await tapVisible(find.byKey(AppKeys.sessionFinishClose));

    final completedLogs = appState.logs
        .where((log) => log.status == ExerciseStatus.done)
        .length;
    expect(completedLogs, 2);

    await tapVisible(find.text('Tips'));
    expect(find.byKey(AppKeys.tipsScreen), findsOneWidget);

    await tapVisible(find.text('Settings'));
    expect(find.byKey(AppKeys.settingsScreen), findsOneWidget);

    await tapVisible(find.byKey(AppKeys.settingsNotificationsEnabled));
    expect(appState.settings.notificationsEnabled, isFalse);

    await tapVisible(find.byKey(AppKeys.settingsNotificationsEnabled));
    expect(appState.settings.notificationsEnabled, isTrue);

    await tapVisible(find.byKey(AppKeys.settingsIntervalMinutes));
    await tapVisible(find.textContaining('90').last);
    expect(appState.settings.intervalMinutes, 90);

    await tapVisible(
      find.byKey(AppKeys.settingsRestartOnboarding),
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byKey(AppKeys.questionnaireScreen), findsOneWidget);
    expect(appState.hasCompletedOnboarding, isFalse);
    expect(appState.logs, isEmpty);
  });
}
