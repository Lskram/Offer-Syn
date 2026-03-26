import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_state.dart';
import 'services/app_persistence.dart';
import 'services/app_launch_bridge.dart';
import 'services/device_automation.dart';
import 'services/reminder_scheduler.dart';
import 'services/system_event_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState(
    persistence: SharedPreferencesAppPersistence(),
    reminderScheduler: _createReminderScheduler(),
  );
  await appState.initialize();
  await initializeAppLaunchBridge(appState);
  await initializeSystemEventBridge(appState);
  await runPendingDeviceAutomation(appState);

  runApp(OfficeStretchApp(appState: appState));
}

ReminderScheduler _createReminderScheduler() {
  if (kIsWeb) {
    return const NoopReminderScheduler();
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return LocalNotificationReminderScheduler();
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return const NoopReminderScheduler();
  }
}
