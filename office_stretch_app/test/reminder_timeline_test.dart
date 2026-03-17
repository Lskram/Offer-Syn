import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/services/reminder_timeline.dart';

void main() {
  test('moves reminders to the next day when outside the active window', () {
    const settings = ReminderSettings(
      notificationsEnabled: true,
      soundEnabled: true,
      activeStart: TimeOfDay(hour: 8, minute: 0),
      activeEnd: TimeOfDay(hour: 16, minute: 30),
      intervalMinutes: 60,
    );

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final requestedStartAt = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      18,
    );

    final schedule = ReminderTimeline.buildSchedule(
      requestedStartAt: requestedStartAt,
      settings: settings,
      maxEntries: 2,
      horizon: const Duration(days: 2),
    );

    final expectedFirst = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day + 1,
      8,
    );
    final expectedSecond = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day + 1,
      9,
    );

    expect(schedule, hasLength(2));
    expect(schedule.first, expectedFirst);
    expect(schedule.last, expectedSecond);
  });

  test('keeps reminders inside the same workday when still in range', () {
    const settings = ReminderSettings(
      notificationsEnabled: true,
      soundEnabled: true,
      activeStart: TimeOfDay(hour: 8, minute: 0),
      activeEnd: TimeOfDay(hour: 16, minute: 30),
      intervalMinutes: 45,
    );

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final requestedStartAt = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      10,
    );

    final schedule = ReminderTimeline.buildSchedule(
      requestedStartAt: requestedStartAt,
      settings: settings,
      maxEntries: 3,
      horizon: const Duration(days: 2),
    );

    final expectedFirst = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      10,
    );
    final expectedSecond = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      10,
      45,
    );
    final expectedThird = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      11,
      30,
    );

    expect(schedule, hasLength(3));
    expect(schedule[0], expectedFirst);
    expect(schedule[1], expectedSecond);
    expect(schedule[2], expectedThird);
  });
}
