import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app.dart';
import 'package:office_stretch_app/app/app_keys.dart';
import 'package:office_stretch_app/app/app_state.dart';

void main() {
  testWidgets('shows the questionnaire on first launch', (tester) async {
    await tester.pumpWidget(OfficeStretchApp(appState: AppState()));

    expect(find.byKey(AppKeys.questionnaireScreen), findsOneWidget);
    expect(find.text('สร้างแผนยืดเส้นเฉพาะของคุณ'), findsOneWidget);
    expect(find.text('บริเวณที่ปวดบ่อยที่สุด'), findsOneWidget);
  });
}
