import 'package:flutter/material.dart';

import '../models/app_models.dart';

class ReminderTimeline {
  static List<DateTime> buildSchedule({
    required DateTime requestedStartAt,
    required ReminderSettings settings,
    int maxEntries = 48,
    Duration horizon = const Duration(days: 7),
    DateTime? now,
  }) {
    if (!hasValidWindow(settings)) {
      return const <DateTime>[];
    }

    final effectiveNow = now ?? DateTime.now();
    final schedule = <DateTime>[];
    final cutoff = effectiveNow.add(horizon);
    var candidate = alignToWindow(
      requestedStartAt,
      settings,
      now: effectiveNow,
    );

    while (!candidate.isAfter(cutoff) && schedule.length < maxEntries) {
      schedule.add(candidate);
      candidate = alignToWindow(
        candidate.add(Duration(minutes: settings.intervalMinutes)),
        settings,
        now: effectiveNow,
      );
    }

    return schedule;
  }

  static DateTime alignToWindow(
    DateTime requestedStartAt,
    ReminderSettings settings, {
    DateTime? now,
  }) {
    if (!hasValidWindow(settings)) {
      return requestedStartAt;
    }

    final effectiveNow = now ?? DateTime.now();
    var candidate = requestedStartAt.isBefore(effectiveNow)
        ? effectiveNow
        : requestedStartAt;

    while (true) {
      final windowStart = _activeOrNextShiftStart(candidate, settings);
      final windowEnd = _shiftEnd(windowStart, settings);

      if (candidate.isBefore(windowStart)) {
        candidate = windowStart;
        continue;
      }

      if (candidate.isAfter(windowEnd)) {
        candidate = windowStart.add(const Duration(days: 1));
        continue;
      }

      return candidate;
    }
  }

  static DateTime nextAlignedSlotAtOrAfter(
    DateTime reference,
    ReminderSettings settings, {
    DateTime? now,
  }) {
    if (!hasValidWindow(settings)) {
      return reference;
    }

    final effectiveNow = now ?? DateTime.now();
    var candidate = reference.isBefore(effectiveNow) ? effectiveNow : reference;
    var shiftStart = _activeOrNextShiftStart(candidate, settings);

    while (true) {
      final shiftEnd = _shiftEnd(shiftStart, settings);
      final slot = _nextSlotInShift(
        reference: candidate,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
        intervalMinutes: settings.intervalMinutes,
      );

      if (slot != null) {
        return slot;
      }

      shiftStart = shiftStart.add(const Duration(days: 1));
      candidate = shiftStart;
    }
  }

  static bool hasValidWindow(ReminderSettings settings) {
    return _windowDurationMinutes(settings) > 0;
  }

  static DateTime _activeOrNextShiftStart(
    DateTime reference,
    ReminderSettings settings,
  ) {
    final todayStart = DateTime(
      reference.year,
      reference.month,
      reference.day,
      settings.activeStart.hour,
      settings.activeStart.minute,
    );

    final latestStart = reference.isBefore(todayStart)
        ? todayStart.subtract(const Duration(days: 1))
        : todayStart;
    final latestEnd = _shiftEnd(latestStart, settings);

    if (!reference.isAfter(latestEnd)) {
      return latestStart;
    }

    return latestStart.add(const Duration(days: 1));
  }

  static DateTime _shiftEnd(DateTime shiftStart, ReminderSettings settings) {
    return shiftStart.add(Duration(minutes: _windowDurationMinutes(settings)));
  }

  static DateTime? _nextSlotInShift({
    required DateTime reference,
    required DateTime shiftStart,
    required DateTime shiftEnd,
    required int intervalMinutes,
  }) {
    final effectiveReference = reference.isBefore(shiftStart)
        ? shiftStart
        : reference;
    final interval = Duration(minutes: intervalMinutes);
    final elapsedMicroseconds = effectiveReference
        .difference(shiftStart)
        .inMicroseconds;
    final intervalMicroseconds = interval.inMicroseconds;
    var steps = elapsedMicroseconds ~/ intervalMicroseconds;
    var slot = shiftStart.add(Duration(minutes: steps * intervalMinutes));

    if (slot.isBefore(effectiveReference)) {
      steps += 1;
      slot = shiftStart.add(Duration(minutes: steps * intervalMinutes));
    }

    if (slot.isAfter(shiftEnd)) {
      return null;
    }

    return slot;
  }

  static int _windowDurationMinutes(ReminderSettings settings) {
    final startMinutes = _toMinutes(settings.activeStart);
    final endMinutes = _toMinutes(settings.activeEnd);
    final rawDuration = endMinutes - startMinutes;

    if (rawDuration > 0) {
      return rawDuration;
    }

    if (rawDuration < 0) {
      return (24 * 60) + rawDuration;
    }

    return 0;
  }

  static int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;
}
