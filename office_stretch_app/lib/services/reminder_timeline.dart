import 'package:flutter/material.dart';

import '../models/app_models.dart';

class ReminderTimeline {
  static List<DateTime> buildSchedule({
    required DateTime requestedStartAt,
    required ReminderSettings settings,
    int maxEntries = 48,
    Duration horizon = const Duration(days: 7),
  }) {
    if (!hasValidWindow(settings)) {
      return const <DateTime>[];
    }

    final schedule = <DateTime>[];
    final cutoff = DateTime.now().add(horizon);
    var candidate = alignToWindow(requestedStartAt, settings);

    while (!candidate.isAfter(cutoff) && schedule.length < maxEntries) {
      schedule.add(candidate);
      candidate = alignToWindow(
        candidate.add(Duration(minutes: settings.intervalMinutes)),
        settings,
      );
    }

    return schedule;
  }

  static DateTime alignToWindow(
    DateTime requestedStartAt,
    ReminderSettings settings,
  ) {
    if (!hasValidWindow(settings)) {
      return requestedStartAt;
    }

    var candidate = requestedStartAt.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(minutes: 1))
        : requestedStartAt;

    while (true) {
      final dayStart = DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
        settings.activeStart.hour,
        settings.activeStart.minute,
      );
      final dayEnd = DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
        settings.activeEnd.hour,
        settings.activeEnd.minute,
      );

      if (candidate.isBefore(dayStart)) {
        candidate = dayStart;
        continue;
      }

      if (candidate.isAfter(dayEnd)) {
        candidate = DateTime(
          candidate.year,
          candidate.month,
          candidate.day + 1,
          settings.activeStart.hour,
          settings.activeStart.minute,
        );
        continue;
      }

      return candidate;
    }
  }

  static bool hasValidWindow(ReminderSettings settings) {
    return _toMinutes(settings.activeEnd) > _toMinutes(settings.activeStart);
  }

  static int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;
}
