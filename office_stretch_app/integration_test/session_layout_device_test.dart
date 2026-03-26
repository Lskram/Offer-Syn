import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:office_stretch_app/app/app_keys.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/data/exercise_catalog.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/screens/session_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  ExercisePlan buildPlan() {
    return ExerciseCatalog.buildPlan(
      const UserProfile(
        painSelections: [
          PainSelection(
            area: PainArea.neckShoulders,
            level: PainLevel.high,
            selectedExerciseIds: <String>[],
          ),
        ],
        workHours: WorkHours.fourToSix,
        stretchHabit: StretchHabit.sometimes,
      ),
    );
  }

  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('real device keeps countdown above session actions', (
    tester,
  ) async {
    final appState = AppState();
    await appState.initialize();
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseSessionScreen(appState: appState, plan: buildPlan()),
      ),
    );
    await pumpUi(tester);

    expect(find.byKey(AppKeys.sessionScreen), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byKey(AppKeys.sessionSkip), findsOneWidget);
    expect(find.byKey(AppKeys.sessionSnooze), findsOneWidget);
    expect(find.byKey(AppKeys.sessionComplete), findsOneWidget);

    final countdownBottom = tester
        .getBottomRight(find.byType(LinearProgressIndicator))
        .dy;
    final actionTop = tester.getTopLeft(find.byKey(AppKeys.sessionSkip)).dy;

    expect(countdownBottom, lessThan(actionTop));
  });
}
