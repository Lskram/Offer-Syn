import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app_keys.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/screens/home_screen.dart';
import 'package:office_stretch_app/screens/settings_screen.dart';
import 'package:office_stretch_app/services/app_persistence.dart';
import 'package:office_stretch_app/services/reminder_scheduler.dart';

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
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppKeys.settingsPermissionInfo('notifications')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('สิทธิ์'), findsAtLeastNWidgets(1));
  });
}
