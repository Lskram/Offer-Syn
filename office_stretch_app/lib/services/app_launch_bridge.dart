import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../app/app_state.dart';

const _appLaunchChannel = MethodChannel('office_stretch_app/app_launch');

class AppLaunchCommand {
  const AppLaunchCommand({
    required this.action,
    required this.payload,
  });

  final String action;
  final String? payload;

  bool get isAlarmLaunch => action == 'presentAlarmLaunch' && payload != null;

  factory AppLaunchCommand.fromMap(Map<String, Object?> map) {
    return AppLaunchCommand(
      action: map['action']! as String,
      payload: map['payload'] as String?,
    );
  }
}

Future<void> initializeAppLaunchBridge(AppState appState) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  _appLaunchChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'didReceiveLaunchCommand':
        final raw = Map<String, Object?>.from(call.arguments as Map);
        _handleCommand(appState, AppLaunchCommand.fromMap(raw));
        return null;
      default:
        throw MissingPluginException('Unsupported app launch call: ${call.method}');
    }
  });

  final pending = await _appLaunchChannel.invokeMapMethod<String, Object?>(
    'takePendingLaunchCommand',
  );
  if (pending != null) {
    _handleCommand(appState, AppLaunchCommand.fromMap(pending));
  }

  await _appLaunchChannel.invokeMethod<void>('markLaunchBridgeReady');
}

void _handleCommand(AppState appState, AppLaunchCommand command) {
  if (!command.isAlarmLaunch) {
    return;
  }

  appState.stageReminderLaunchPayload(command.payload!);
}
