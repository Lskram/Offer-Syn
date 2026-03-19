// ignore_for_file: avoid_print

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:office_stretch_app/app/app.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/models/reminder_diagnostics.dart';
import 'package:office_stretch_app/services/app_persistence.dart';
import 'package:office_stretch_app/services/reminder_scheduler.dart';

const _settingsChannel = MethodChannel('office_stretch_app/device_settings');
const _testNotificationId = 999;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'posts real-device notifications for every alert mode',
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
            'notification permission attempt ${attempt + 1}: '
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

      Future<Map<String, Object?>> readLatestTestNotification() async {
        for (var attempt = 0; attempt < 10; attempt += 1) {
          final raw = await _settingsChannel.invokeListMethod<dynamic>(
            'getActiveNotifications',
          );
          final notifications = (raw ?? const <dynamic>[])
              .cast<Map<dynamic, dynamic>>()
              .map((entry) => entry.cast<String, Object?>())
              .toList(growable: false);
          final testNotification = notifications.where(
            (entry) => entry['id'] == _testNotificationId,
          );
          if (testNotification.isNotEmpty) {
            return testNotification.first;
          }
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }

        fail('No active test notification was found on the device.');
      }

      Future<void> verifyMode({
        required AlertMode mode,
        required bool expectExact,
        required bool expectFullScreenIntent,
        required String expectedCategory,
      }) async {
        appState.updateNotificationsEnabled(true);
        appState.updateAlertMode(mode);
        await appState.settleSideEffects();
        await appState.refreshReminderDiagnostics();
        print(
          'verifying ${mode.name}: '
          'exact=${appState.reminderSyncState.usesExactScheduling}, '
          'fullScreen=${appState.reminderSyncState.usesFullScreenIntent}',
        );

        expect(
          appState.reminderSyncState.usesExactScheduling,
          expectExact,
          reason: 'Unexpected exact scheduling state for ${mode.name}.',
        );
        expect(
          appState.reminderSyncState.usesFullScreenIntent,
          expectFullScreenIntent,
          reason: 'Unexpected full-screen scheduling state for ${mode.name}.',
        );

        await appState.sendTestNotificationNow();
        await tester.pump(const Duration(seconds: 1));

        final posted = await readLatestTestNotification();
        print('posted notification for ${mode.name}: $posted');
        expect(posted['hasFullScreenIntent'], expectFullScreenIntent);
        expect(posted['category'], expectedCategory);
        expect(posted['title'], contains('OfficeRelief'));
      }

      final canUseExact = diagnostics.exactAlarmsEnabled != false;
      final canUseFullScreen =
          canUseExact && diagnostics.fullScreenIntentEnabled == true;

      await verifyMode(
        mode: AlertMode.notification,
        expectExact: false,
        expectFullScreenIntent: false,
        expectedCategory: 'reminder',
      );

      await verifyMode(
        mode: AlertMode.exact,
        expectExact: canUseExact,
        expectFullScreenIntent: false,
        expectedCategory: 'reminder',
      );

      await verifyMode(
        mode: AlertMode.exactFullScreen,
        expectExact: canUseExact,
        expectFullScreenIntent: canUseFullScreen,
        expectedCategory: canUseFullScreen ? 'alarm' : 'reminder',
      );
    },
  );
}
