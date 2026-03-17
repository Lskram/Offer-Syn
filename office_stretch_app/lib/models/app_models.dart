import 'package:flutter/material.dart';

const defaultReminderSettings = ReminderSettings(
  notificationsEnabled: true,
  soundEnabled: true,
  activeStart: TimeOfDay(hour: 8, minute: 0),
  activeEnd: TimeOfDay(hour: 16, minute: 30),
  intervalMinutes: 60,
);

enum PainArea { neckShoulders, upperBack, lowerBack }

extension PainAreaX on PainArea {
  String get label {
    switch (this) {
      case PainArea.neckShoulders:
        return 'คอ บ่า ไหล่';
      case PainArea.upperBack:
        return 'สะบัก และหลังส่วนบน';
      case PainArea.lowerBack:
        return 'หลังส่วนล่าง และเอว';
    }
  }

  String get description {
    switch (this) {
      case PainArea.neckShoulders:
        return 'เหมาะกับคนที่นั่งคอพุ่ง ไหล่ห่อ หรือปวดตึงจากพิมพ์งานนาน';
      case PainArea.upperBack:
        return 'เหมาะกับอาการหลังงุ้ม ตึงระหว่างสะบัก และเมื่อยหลังจากนั่งนาน';
      case PainArea.lowerBack:
        return 'เหมาะกับอาการเอวตึง ปวดหลังล่าง และนั่งต่อเนื่องหลายชั่วโมง';
    }
  }
}

enum PainLevel { high, medium, low }

extension PainLevelX on PainLevel {
  String get label {
    switch (this) {
      case PainLevel.high:
        return 'ปวดมาก';
      case PainLevel.medium:
        return 'ปวดปานกลาง';
      case PainLevel.low:
        return 'ปวดน้อย หรือเน้นป้องกัน';
    }
  }

  String get frequencyHint {
    switch (this) {
      case PainLevel.high:
        return 'ทุก 30 นาที';
      case PainLevel.medium:
        return 'ทุก 45 นาที';
      case PainLevel.low:
        return 'ทุก 60 นาที';
    }
  }
}

enum WorkHours { oneToThree, fourToSix, sevenToNine, moreThanNine }

extension WorkHoursX on WorkHours {
  String get label {
    switch (this) {
      case WorkHours.oneToThree:
        return '1-3 ชั่วโมง';
      case WorkHours.fourToSix:
        return '4-6 ชั่วโมง';
      case WorkHours.sevenToNine:
        return '7-9 ชั่วโมง';
      case WorkHours.moreThanNine:
        return 'มากกว่า 9 ชั่วโมง';
    }
  }
}

enum StretchHabit { never, sometimes, often }

extension StretchHabitX on StretchHabit {
  String get label {
    switch (this) {
      case StretchHabit.never:
        return 'แทบไม่เคย';
      case StretchHabit.sometimes:
        return 'บางครั้ง';
      case StretchHabit.often:
        return 'ค่อนข้างบ่อย';
    }
  }
}

enum ExerciseStatus { done, skipped, snoozed }

extension ExerciseStatusX on ExerciseStatus {
  String get label {
    switch (this) {
      case ExerciseStatus.done:
        return 'ทำครบ';
      case ExerciseStatus.skipped:
        return 'ข้าม';
      case ExerciseStatus.snoozed:
        return 'เลื่อนเวลา';
    }
  }
}

class UserProfile {
  const UserProfile({
    required this.painArea,
    required this.painLevel,
    required this.workHours,
    required this.stretchHabit,
  });

  final PainArea painArea;
  final PainLevel painLevel;
  final WorkHours workHours;
  final StretchHabit stretchHabit;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'painArea': painArea.name,
      'painLevel': painLevel.name,
      'workHours': workHours.name,
      'stretchHabit': stretchHabit.name,
    };
  }

  factory UserProfile.fromJson(Map<String, Object?> json) {
    return UserProfile(
      painArea: PainArea.values.byName(json['painArea']! as String),
      painLevel: PainLevel.values.byName(json['painLevel']! as String),
      workHours: WorkHours.values.byName(json['workHours']! as String),
      stretchHabit: StretchHabit.values.byName(json['stretchHabit']! as String),
    );
  }
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.reason,
    required this.durationSeconds,
    this.requiresStanding = false,
  });

  final String id;
  final String name;
  final String description;
  final String reason;
  final int durationSeconds;
  final bool requiresStanding;
}

class ExerciseProgram {
  const ExerciseProgram({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.painArea,
    required this.painLevel,
    required this.reminderIntervalMinutes,
    required this.exercises,
  });

  final String id;
  final String title;
  final String subtitle;
  final PainArea painArea;
  final PainLevel painLevel;
  final int reminderIntervalMinutes;
  final List<Exercise> exercises;
}

class ExerciseLog {
  const ExerciseLog({
    required this.exerciseName,
    required this.status,
    required this.occurredAt,
  });

  final String exerciseName;
  final ExerciseStatus status;
  final DateTime occurredAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseName': exerciseName,
      'status': status.name,
      'occurredAt': occurredAt.toIso8601String(),
    };
  }

  factory ExerciseLog.fromJson(Map<String, Object?> json) {
    return ExerciseLog(
      exerciseName: json['exerciseName']! as String,
      status: ExerciseStatus.values.byName(json['status']! as String),
      occurredAt: DateTime.parse(json['occurredAt']! as String),
    );
  }
}

class ReminderSettings {
  const ReminderSettings({
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.activeStart,
    required this.activeEnd,
    required this.intervalMinutes,
  });

  final bool notificationsEnabled;
  final bool soundEnabled;
  final TimeOfDay activeStart;
  final TimeOfDay activeEnd;
  final int intervalMinutes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'activeStartMinutes': _toMinutes(activeStart),
      'activeEndMinutes': _toMinutes(activeEnd),
      'intervalMinutes': intervalMinutes,
    };
  }

  factory ReminderSettings.fromJson(Map<String, Object?> json) {
    return ReminderSettings(
      notificationsEnabled: json['notificationsEnabled']! as bool,
      soundEnabled: json['soundEnabled']! as bool,
      activeStart: _fromMinutes(json['activeStartMinutes']! as int),
      activeEnd: _fromMinutes(json['activeEndMinutes']! as int),
      intervalMinutes: json['intervalMinutes']! as int,
    );
  }

  ReminderSettings copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    TimeOfDay? activeStart,
    TimeOfDay? activeEnd,
    int? intervalMinutes,
  }) {
    return ReminderSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      activeStart: activeStart ?? this.activeStart,
      activeEnd: activeEnd ?? this.activeEnd,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    );
  }

  static int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  static TimeOfDay _fromMinutes(int totalMinutes) {
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }
}

class TipArticle {
  const TipArticle({
    required this.title,
    required this.summary,
    required this.bullets,
  });

  final String title;
  final String summary;
  final List<String> bullets;
}
