import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/data/exercise_catalog.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/screens/session_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Future<void> pumpSession(
    WidgetTester tester, {
    Size? surfaceSize,
  }) async {
    if (surfaceSize != null) {
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseSessionScreen(
          appState: AppState(),
          plan: buildPlan(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('session screen shows countdown context in portrait', (
    tester,
  ) async {
    await pumpSession(tester, surfaceSize: const Size(1080, 2400));

    expect(find.text('เวลาของท่านี้'), findsOneWidget);
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(find.textContaining('วินาทีจะเปลี่ยนท่า'), findsOneWidget);
    expect(find.text('ทำได้ขณะนั่ง'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('session screen stays stable in landscape', (tester) async {
    await pumpSession(tester, surfaceSize: const Size(2400, 1080));

    expect(find.text('เวลาของท่านี้'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('session screen remains active after rotating to landscape', (
    tester,
  ) async {
    await pumpSession(tester, surfaceSize: const Size(1080, 2400));

    expect(find.text('เวลาของท่านี้'), findsOneWidget);
    expect(find.text('เสร็จสิ้นรอบยืดเส้น'), findsNothing);

    tester.view.physicalSize = const Size(2400, 1080);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('เวลาของท่านี้'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('เสร็จสิ้นรอบยืดเส้น'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
