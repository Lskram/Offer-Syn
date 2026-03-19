import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/models/app_models.dart';

void main() {
  test('defaults vibration settings when loading older persisted data', () {
    final settings = ReminderSettings.fromJson(<String, Object?>{
      'notificationsEnabled': true,
      'soundEnabled': true,
      'activeStartMinutes': 480,
      'activeEndMinutes': 990,
      'intervalMinutes': 60,
    });

    expect(settings.vibrationEnabled, isTrue);
    expect(settings.vibrationLevel, VibrationLevel.medium);
    expect(settings.alertMode, AlertMode.exact);
    expect(settings.notificationSoundUri, isNull);
    expect(settings.notificationSoundLabel, isNull);
  });

  test('clearNotificationSound removes custom sound metadata', () {
    const settings = ReminderSettings(
      notificationsEnabled: true,
      alertMode: AlertMode.exact,
      soundEnabled: true,
      vibrationEnabled: true,
      vibrationLevel: VibrationLevel.strong,
      activeStart: TimeOfDay(hour: 8, minute: 0),
      activeEnd: TimeOfDay(hour: 16, minute: 30),
      intervalMinutes: 60,
      notificationSoundUri: 'content://settings/system/notification_sound',
      notificationSoundLabel: 'Office Bell',
    );

    final updated = settings.copyWith(clearNotificationSound: true);

    expect(updated.notificationSoundUri, isNull);
    expect(updated.notificationSoundLabel, isNull);
    expect(updated.vibrationEnabled, isTrue);
    expect(updated.vibrationLevel, VibrationLevel.strong);
  });
}
