import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app.dart';
import 'package:office_stretch_app/app/app_state.dart';

void main() {
  testWidgets('shows the questionnaire on first launch', (tester) async {
    await tester.pumpWidget(OfficeStretchApp(appState: AppState()));

    expect(find.text('สร้างโปรแกรมพักยืดของคุณ'), findsOneWidget);
    expect(find.text('บริเวณที่ปวดบ่อยที่สุด'), findsOneWidget);
  });
}
