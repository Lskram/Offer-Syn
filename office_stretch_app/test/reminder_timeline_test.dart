import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/services/reminder_timeline.dart';

void main() {
  test('moves reminders to the next day when outside the active window', () {
    const settings = ReminderSettings(
      notificationsEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      vibrationLevel: VibrationLevel.medium,
      activeStart: TimeOfDay(hour: 8, minute: 0),
      activeEnd: TimeOfDay(hour: 16, minute: 30),
      intervalMinutes: 60,
    );

    final now = DateTime(2026, 3, 18, 12);
    final requestedStartAt = DateTime(now.year, now.month, now.day, 18);

    final schedule = ReminderTimeline.buildSchedule(
      requestedStartAt: requestedStartAt,
      settings: settings,
      maxEntries: 2,
      horizon: const Duration(days: 2),
      now: now,
    );

    final expectedFirst = DateTime(now.year, now.month, now.day + 1, 8);
    final expectedSecond = DateTime(now.year, now.month, now.day + 1, 9);

    expect(schedule, hasLength(2));
    expect(schedule.first, expectedFirst);
    expect(schedule.last, expectedSecond);
  });

  test('keeps reminders inside the same workday when still in range', () {
    const settings = ReminderSettings(
      notificationsEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      vibrationLevel: VibrationLevel.medium,
      activeStart: TimeOfDay(hour: 8, minute: 0),
      activeEnd: TimeOfDay(hour: 16, minute: 30),
      intervalMinutes: 45,
    );

    final now = DateTime(2026, 3, 18, 9);
    final requestedStartAt = DateTime(now.year, now.month, now.day, 10);

    final schedule = ReminderTimeline.buildSchedule(
      requestedStartAt: requestedStartAt,
      settings: settings,
      maxEntries: 3,
      horizon: const Duration(days: 2),
      now: now,
    );

    final expectedFirst = DateTime(now.year, now.month, now.day, 10);
    final expectedSecond = DateTime(now.year, now.month, now.day, 10, 45);
    final expectedThird = DateTime(now.year, now.month, now.day, 11, 30);

    expect(schedule, hasLength(3));
    expect(schedule[0], expectedFirst);
    expect(schedule[1], expectedSecond);
    expect(schedule[2], expectedThird);
  });

  test('anchors the next slot to the user work start time', () {
    const settings = ReminderSettings(
      notificationsEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      vibrationLevel: VibrationLevel.medium,
      activeStart: TimeOfDay(hour: 18, minute: 0),
      activeEnd: TimeOfDay(hour: 23, minute: 59),
      intervalMinutes: 45,
    );

    final now = DateTime(2026, 3, 18, 20, 10);

    final nextReminder = ReminderTimeline.nextAlignedSlotAtOrAfter(
      now,
      settings,
      now: now,
    );

    expect(nextReminder, DateTime(2026, 3, 18, 20, 15));
  });

  test('supports overnight work windows that cross midnight', () {
    const settings = ReminderSettings(
      notificationsEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      vibrationLevel: VibrationLevel.medium,
      activeStart: TimeOfDay(hour: 18, minute: 0),
      activeEnd: TimeOfDay(hour: 2, minute: 0),
      intervalMinutes: 60,
    );

    final now = DateTime(2026, 3, 19, 0, 30);

    final nextReminder = ReminderTimeline.nextAlignedSlotAtOrAfter(
      now,
      settings,
      now: now,
    );

    expect(nextReminder, DateTime(2026, 3, 19, 1));
  });

  test('treats identical start and end times as invalid', () {
    const settings = ReminderSettings(
      notificationsEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      vibrationLevel: VibrationLevel.medium,
      activeStart: TimeOfDay(hour: 8, minute: 0),
      activeEnd: TimeOfDay(hour: 8, minute: 0),
      intervalMinutes: 60,
    );

    final schedule = ReminderTimeline.buildSchedule(
      requestedStartAt: DateTime(2026, 3, 18, 9),
      settings: settings,
      maxEntries: 1,
      now: DateTime(2026, 3, 18, 9),
    );

    expect(ReminderTimeline.hasValidWindow(settings), isFalse);
    expect(schedule, isEmpty);
  });
}
