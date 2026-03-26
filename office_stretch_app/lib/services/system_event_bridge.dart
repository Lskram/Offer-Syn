import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../app/app_state.dart';
import '../models/system_time_change_signal.dart';

const _systemEventsChannel = MethodChannel('office_stretch_app/system_events');

Future<void> initializeSystemEventBridge(AppState appState) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  _systemEventsChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'didReceiveSystemEvent':
        final raw = Map<String, Object?>.from(call.arguments as Map);
        _handleSystemEvent(appState, raw);
        await _acknowledgePendingSystemEvent();
        return null;
      default:
        throw MissingPluginException(
          'Unsupported system event call: ${call.method}',
        );
    }
  });

  final pending = await _systemEventsChannel.invokeMapMethod<String, Object?>(
    'takePendingSystemEvent',
  );
  if (pending != null) {
    _handleSystemEvent(appState, pending);
    await _acknowledgePendingSystemEvent();
  }

  await _systemEventsChannel.invokeMethod<void>('markSystemEventBridgeReady');
}

void _handleSystemEvent(AppState appState, Map<String, Object?> raw) {
  appState.handleSystemTimeChangeSignal(SystemTimeChangeSignal.fromJson(raw));
}

Future<void> _acknowledgePendingSystemEvent() async {
  try {
    await _systemEventsChannel.invokeMethod<void>(
      'acknowledgePendingSystemEvent',
    );
  } catch (_) {
    // Best-effort cleanup so duplicate resume handling does not block the app.
  }
}
