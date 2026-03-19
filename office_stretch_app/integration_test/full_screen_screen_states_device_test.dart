// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:office_stretch_app/app/app.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/models/reminder_diagnostics.dart';
import 'package:office_stretch_app/services/app_persistence.dart';
import 'package:office_stretch_app/services/reminder_scheduler.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'full-screen alert can be exercised for screen-on and screen-off states',
    semanticsEnabled: false,
    (tester) async {
      final appState = AppState(
        persistence: InMemoryAppPersistence(),
        reminderScheduler: LocalNotificationReminderScheduler(),
      );
      await appState.initialize();

      await tester.pumpWidget(OfficeStretchApp(appState: appState));
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      Future<ReminderDiagnostics> waitForNotificationPermission() async {
        ReminderDiagnostics diagnostics = appState.reminderDiagnostics;
        for (var attempt = 0; attempt < 20; attempt += 1) {
          await appState.refreshReminderDiagnostics();
          diagnostics = appState.reminderDiagnostics;
          print(
            'full-screen permission attempt ${attempt + 1}: '
            '${diagnostics.notificationsEnabled}',
          );
          if (diagnostics.notificationsEnabled != false) {
            return diagnostics;
          }
          await tester.pump(const Duration(seconds: 1));
        }

        fail('Notification permission must be enabled on the real device.');
      }

      final diagnostics = await waitForNotificationPermission();
      appState.updateNotificationsEnabled(true);
      appState.updateAlertMode(AlertMode.exactFullScreen);
      await appState.settleSideEffects();
      await appState.refreshReminderDiagnostics();

      final canUseExact = diagnostics.exactAlarmsEnabled != false;
      final canUseFullScreen =
          canUseExact && appState.reminderDiagnostics.fullScreenIntentEnabled == true;

      expect(
        appState.reminderSyncState.usesExactScheduling,
        canUseExact,
        reason: 'Unexpected exact scheduling state for full-screen mode.',
      );
      expect(
        appState.reminderSyncState.usesFullScreenIntent,
        canUseFullScreen,
        reason: 'Unexpected full-screen capability state for full-screen mode.',
      );

      print('READY_SCREEN_ON_HOME');
      await tester.pump(const Duration(seconds: 8));
      await appState.sendTestNotificationNow();
      await tester.pump(const Duration(seconds: 2));
      print('FIRED_SCREEN_ON_HOME');
      await tester.pump(const Duration(seconds: 5));

      print('READY_SCREEN_OFF');
      await tester.pump(const Duration(seconds: 8));
      await appState.sendTestNotificationNow();
      await tester.pump(const Duration(seconds: 2));
      print('FIRED_SCREEN_OFF');
      await tester.pump(const Duration(seconds: 5));
    },
  );
}
