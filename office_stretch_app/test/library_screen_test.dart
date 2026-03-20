import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/app/app_keys.dart';
import 'package:office_stretch_app/app/app_state.dart';
import 'package:office_stretch_app/screens/library_screen.dart';
import 'package:office_stretch_app/services/app_persistence.dart';
import 'package:office_stretch_app/services/reminder_scheduler.dart';

void main() {
  testWidgets('library screen shows exercise previews and keeps start actions', (
    tester,
  ) async {
    final appState = AppState(
      persistence: InMemoryAppPersistence(),
      reminderScheduler: const NoopReminderScheduler(),
    );
    await appState.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExerciseLibraryScreen(
            appState: appState,
            onStartProgram: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.libraryScreen), findsOneWidget);
    expect(find.byKey(AppKeys.libraryExercisePreview('chin-tuck')), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.text('เริ่มโปรแกรมนี้'), findsWidgets);
  });
}
