import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app.dart';
import 'package:office_stretch_app/app/app_keys.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/models/app_models.dart';

void main() {
  testWidgets('shows the questionnaire on first launch', (tester) async {
    await tester.pumpWidget(OfficeStretchApp(appState: AppState()));

    expect(find.byKey(AppKeys.questionnaireScreen), findsOneWidget);
    expect(
      find.byKey(AppKeys.painAreaOption(PainArea.neckShoulders)),
      findsOneWidget,
    );
  });
}
