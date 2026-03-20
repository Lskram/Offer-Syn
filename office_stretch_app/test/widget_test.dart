import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app.dart';
import 'package:office_stretch_app/app/app_keys.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/models/app_models.dart';

void main() {
  testWidgets('shows the questionnaire on first launch', (tester) async {
    await tester.pumpWidget(OfficeStretchApp(appState: AppState()));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.questionnaireScreen), findsOneWidget);
    expect(
      find.byKey(AppKeys.painAreaOption(PainArea.neckShoulders)),
      findsOneWidget,
    );
    await tester.dragUntilVisible(
      find.byKey(AppKeys.scheduleActiveStart),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(AppKeys.scheduleActiveStart), findsOneWidget);
    expect(find.byKey(AppKeys.scheduleActiveEnd), findsOneWidget);
  });
}
