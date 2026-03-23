import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/data/exercise_catalog.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/screens/session_screen.dart';

void main() {
  testWidgets('session screen matches the reference timer card', (
    tester,
  ) async {
    final plan = ExerciseCatalog.buildPlan(
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

    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseSessionScreen(
          appState: AppState(),
          plan: plan,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('เวลาของท่านี้'), findsOneWidget);
    expect(find.textContaining('วินาที'), findsOneWidget);
    expect(find.text('ทำได้ขณะนั่ง'), findsOneWidget);
    expect(find.text('นาฬิกาทรายของท่านี้'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
