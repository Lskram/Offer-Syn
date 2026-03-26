import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _hostActivityChannel = MethodChannel('office_stretch_app/host_activity');

Future<bool> finishAlarmHostIfPresent() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return false;
  }

  try {
    return await _hostActivityChannel.invokeMethod<bool>('finishIfAlarmHost') ??
        false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

Future<void> stopAlarmAttentionIfPresent() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  try {
    await _hostActivityChannel.invokeMethod<void>('stopAlarmAttention');
  } on MissingPluginException {
    return;
  } on PlatformException {
    return;
  }
}
