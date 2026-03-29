import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app_keys.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/models/reminder_diagnostics.dart';
import 'package:office_stretch_app/models/reminder_sync_state.dart';
import 'package:office_stretch_app/models/system_notification_sound.dart';
import 'package:office_stretch_app/models/system_time_change_signal.dart';
import 'package:office_stretch_app/screens/home_screen.dart';
import 'package:office_stretch_app/screens/settings_screen.dart';
import 'package:office_stretch_app/services/app_persistence.dart';
import 'package:office_stretch_app/services/reminder_scheduler.dart';

class SettingsDiagnosticsScheduler implements ReminderScheduler {
  const SettingsDiagnosticsScheduler(this.diagnosticsValue);

  final ReminderDiagnostics diagnosticsValue;

  @override
  Stream<String?> get notificationResponses => const Stream<String?>.empty();

  @override
  String? takePendingNotificationPayload() => null;

  @override
  Future<void> initialize() async {}

  @override
  Future<ReminderDiagnostics> diagnostics() async => diagnosticsValue;

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
  }) async => null;

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
    if (!settings.notificationsEnabled || plan == null) {
      return const ReminderSyncState.empty();
    }

    return ReminderSyncState(
      requestedReminderCount: 1,
      pendingRequestCount: 1,
      scheduledReminders: [
        ScheduledReminderEntry(
          notificationId: 1000,
          scheduledAt: requestedStartAt,
        ),
      ],
      usesExactScheduling: settings.alertMode.prefersExactScheduling,
      usesFullScreenIntent: settings.alertMode.prefersFullScreenIntent,
      notificationsPermissionAtSync: diagnosticsValue.notificationsEnabled,
      syncedAt: requestedStartAt,
      nextReminderAt: requestedStartAt,
    );
  }
}

void main() {
  testWidgets('home plan card exposes edit action', (tester) async {
    final appState = AppState(
      persistence: InMemoryAppPersistence(),
      reminderScheduler: const NoopReminderScheduler(),
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

    var editTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            appState: appState,
            onStartPlan: (_) {},
            onEditPlan: () => editTapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppKeys.homeEditMainPlan));
    await tester.pumpAndSettle();

    expect(editTapped, isTrue);
  });

  testWidgets('settings permission note opens a dialog', (tester) async {
    final appState = AppState(
      persistence: InMemoryAppPersistence(),
      reminderScheduler: const NoopReminderScheduler(),
    );
    await appState.initialize();

    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(appState: appState)),
    );
    await tester.pump();

    await tester.tap(find.byKey(AppKeys.settingsPermissionInfo('notifications')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextButton), findsAtLeastNWidgets(1));
  });

  testWidgets('settings shows readiness summary and troubleshooting guidance', (
    tester,
  ) async {
    final appState = AppState(
      persistence: InMemoryAppPersistence(),
      reminderScheduler: SettingsDiagnosticsScheduler(
        ReminderDiagnostics.android(
          notificationsEnabled: true,
          ignoresBatteryOptimizations: false,
          exactAlarmsEnabled: false,
          fullScreenIntentEnabled: false,
          lastObservedReminderDelivery: ReminderDeliveryDrift(
            notificationId: 1000,
            scheduledAt: DateTime(2026, 3, 29, 20, 0, 0),
            postedAt: DateTime(2026, 3, 29, 20, 0, 22),
          ),
        ),
      ),
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

    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(appState: appState)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.settingsReadinessSummary), findsOneWidget);
    expect(find.text('Needs setup'), findsOneWidget);
    expect(find.byKey(AppKeys.settingsTroubleshooting), findsOneWidget);
    expect(find.text('Troubleshooting'), findsOneWidget);
    expect(find.textContaining('exact alarm'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Battery'), findsAtLeastNWidgets(1));
  });
}
