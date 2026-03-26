import 'package:flutter/material.dart';

const defaultReminderSettings = ReminderSettings(
  notificationsEnabled: true,
  alertMode: AlertMode.exact,
  soundEnabled: true,
  vibrationEnabled: true,
  vibrationLevel: VibrationLevel.medium,
  activeStart: TimeOfDay(hour: 8, minute: 0),
  activeEnd: TimeOfDay(hour: 16, minute: 30),
  intervalMinutes: 60,
);

enum AlertMode { notification, exact, exactFullScreen }

extension AlertModeX on AlertMode {
  String get label {
    switch (this) {
      case AlertMode.notification:
        return 'Normal notification';
      case AlertMode.exact:
        return 'Exact alarm';
      case AlertMode.exactFullScreen:
        return 'Exact + full-screen';
    }
  }

  String get description {
    switch (this) {
      case AlertMode.notification:
        return 'Standard reminder notification with no exact alarm request.';
      case AlertMode.exact:
        return 'Uses exact alarm when the device allows it, otherwise falls back.';
      case AlertMode.exactFullScreen:
        return 'Uses exact alarm and requests full-screen delivery when allowed.';
    }
  }

  bool get prefersExactScheduling => this != AlertMode.notification;

  bool get prefersFullScreenIntent => this == AlertMode.exactFullScreen;
}

enum PainArea { neckShoulders, upperBack, lowerBack }

extension PainAreaX on PainArea {
  String get label {
    switch (this) {
      case PainArea.neckShoulders:
        return 'คอ บ่า ไหล่';
      case PainArea.upperBack:
        return 'สะบัก และหลังบน';
      case PainArea.lowerBack:
        return 'หลังล่าง และเอว';
    }
  }

  String get description {
    switch (this) {
      case PainArea.neckShoulders:
        return 'เหมาะกับคนที่นั่งคอพุ่ง ไหล่ห่อ หรือปวดตึงจากการทำงานหน้าคอมนาน';
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
        return 'เริ่มเตือนทุก 30 นาที';
      case PainLevel.medium:
        return 'เริ่มเตือนทุก 45 นาที';
      case PainLevel.low:
        return 'เริ่มเตือนทุก 60 นาที';
    }
  }

  int get reminderIntervalMinutes {
    switch (this) {
      case PainLevel.high:
        return 30;
      case PainLevel.medium:
        return 45;
      case PainLevel.low:
        return 60;
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

enum VibrationLevel { light, medium, strong }

extension VibrationLevelX on VibrationLevel {
  String get label {
    switch (this) {
      case VibrationLevel.light:
        return 'เบา';
      case VibrationLevel.medium:
        return 'กลาง';
      case VibrationLevel.strong:
        return 'แรง';
    }
  }

  String get description {
    switch (this) {
      case VibrationLevel.light:
        return 'สั่นสั้น 1-2 จังหวะ เหมาะกับการแจ้งเตือนทั่วไป';
      case VibrationLevel.medium:
        return 'สั่นชัดขึ้น เหมาะกับการใช้งานประจำวัน';
      case VibrationLevel.strong:
        return 'สั่นยาวและถี่ขึ้น เหมาะกับคนที่พลาดการเตือนง่าย';
    }
  }
}

enum ExerciseStatus { done, skipped, snoozed, missed }

extension ExerciseStatusX on ExerciseStatus {
  String get label {
    switch (this) {
      case ExerciseStatus.done:
        return 'ทำครบ';
      case ExerciseStatus.skipped:
        return 'ข้าม';
      case ExerciseStatus.snoozed:
        return 'เลื่อนเวลา';
      case ExerciseStatus.missed:
        return 'พลาดการแจ้งเตือน';
    }
  }
}

class PainSelection {
  const PainSelection({
    required this.area,
    required this.level,
    required this.selectedExerciseIds,
  });

  final PainArea area;
  final PainLevel level;
  final List<String> selectedExerciseIds;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'area': area.name,
      'level': level.name,
      'selectedExerciseIds': selectedExerciseIds,
    };
  }

  factory PainSelection.fromJson(Map<String, Object?> json) {
    return PainSelection(
      area: PainArea.values.byName(json['area']! as String),
      level: PainLevel.values.byName(json['level']! as String),
      selectedExerciseIds:
          (json['selectedExerciseIds'] as List<Object?>? ?? const <Object?>[])
              .cast<String>(),
    );
  }

  PainSelection copyWith({
    PainArea? area,
    PainLevel? level,
    List<String>? selectedExerciseIds,
  }) {
    return PainSelection(
      area: area ?? this.area,
      level: level ?? this.level,
      selectedExerciseIds: selectedExerciseIds ?? this.selectedExerciseIds,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.painSelections,
    required this.workHours,
    required this.stretchHabit,
  });

  final List<PainSelection> painSelections;
  final WorkHours workHours;
  final StretchHabit stretchHabit;

  bool get hasSelections => painSelections.isNotEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'painSelections': painSelections
          .map((selection) => selection.toJson())
          .toList(growable: false),
      'workHours': workHours.name,
      'stretchHabit': stretchHabit.name,
    };
  }

  factory UserProfile.fromJson(Map<String, Object?> json) {
    final selectionsJson = json['painSelections'];
    if (selectionsJson is List<Object?>) {
      return UserProfile(
        painSelections: selectionsJson
            .cast<Map<Object?, Object?>>()
            .map(
              (selectionJson) =>
                  PainSelection.fromJson(selectionJson.cast<String, Object?>()),
            )
            .toList(growable: false),
        workHours: WorkHours.values.byName(json['workHours']! as String),
        stretchHabit: StretchHabit.values.byName(
          json['stretchHabit']! as String,
        ),
      );
    }

    return UserProfile(
      painSelections: [
        PainSelection(
          area: PainArea.values.byName(json['painArea']! as String),
          level: PainLevel.values.byName(json['painLevel']! as String),
          selectedExerciseIds: const <String>[],
        ),
      ],
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
    this.imageAssetPath,
  });

  final String id;
  final String name;
  final String description;
  final String reason;
  final int durationSeconds;
  final bool requiresStanding;
  final String? imageAssetPath;
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

class PlannedExercise {
  const PlannedExercise({
    required this.area,
    required this.level,
    required this.exercise,
  });

  final PainArea area;
  final PainLevel level;
  final Exercise exercise;
}

class ExercisePlan {
  const ExercisePlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.groups,
    required this.exercises,
    required this.reminderIntervalMinutes,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<PainSelection> groups;
  final List<PlannedExercise> exercises;
  final int reminderIntervalMinutes;

  int get exerciseCount => exercises.length;
}

class ReminderLaunchPayload {
  const ReminderLaunchPayload({
    this.planId,
    this.reminderAt,
    this.alertMode,
    this.isTest = false,
    this.soundEnabled,
    this.notificationSoundUri,
    this.vibrationEnabled,
    this.vibrationLevel,
  });

  final String? planId;
  final DateTime? reminderAt;
  final AlertMode? alertMode;
  final bool isTest;
  final bool? soundEnabled;
  final String? notificationSoundUri;
  final bool? vibrationEnabled;
  final VibrationLevel? vibrationLevel;

  factory ReminderLaunchPayload.fromJson(Map<String, Object?> json) {
    return ReminderLaunchPayload(
      planId: json['planId'] as String? ?? json['programId'] as String?,
      reminderAt: json['reminderAt'] == null
          ? null
          : DateTime.parse(json['reminderAt']! as String),
      alertMode: json['alertMode'] == null
          ? null
          : AlertMode.values.byName(json['alertMode']! as String),
      isTest: json['test'] as bool? ?? false,
      soundEnabled: json['soundEnabled'] as bool?,
      notificationSoundUri: json['notificationSoundUri'] as String?,
      vibrationEnabled: json['vibrationEnabled'] as bool?,
      vibrationLevel: json['vibrationLevel'] == null
          ? null
          : VibrationLevel.values.byName(json['vibrationLevel']! as String),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'planId': planId,
      'reminderAt': reminderAt?.toIso8601String(),
      'alertMode': alertMode?.name,
      'test': isTest,
      'soundEnabled': soundEnabled,
      'notificationSoundUri': notificationSoundUri,
      'vibrationEnabled': vibrationEnabled,
      'vibrationLevel': vibrationLevel?.name,
    };
  }
}

class PendingReminderLaunch {
  const PendingReminderLaunch({
    required this.plan,
    required this.alertMode,
    this.reminderAt,
    this.isTest = false,
  });

  final ExercisePlan plan;
  final AlertMode alertMode;
  final DateTime? reminderAt;
  final bool isTest;

  bool get opensAlarmScreen => alertMode.prefersFullScreenIntent;
}

class ExerciseLog {
  const ExerciseLog({
    required this.exerciseName,
    required this.status,
    required this.occurredAt,
    this.reminderAt,
  });

  final String exerciseName;
  final ExerciseStatus status;
  final DateTime occurredAt;
  final DateTime? reminderAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseName': exerciseName,
      'status': status.name,
      'occurredAt': occurredAt.toIso8601String(),
      'reminderAt': reminderAt?.toIso8601String(),
    };
  }

  factory ExerciseLog.fromJson(Map<String, Object?> json) {
    return ExerciseLog(
      exerciseName: json['exerciseName']! as String,
      status: ExerciseStatus.values.byName(json['status']! as String),
      occurredAt: DateTime.parse(json['occurredAt']! as String),
      reminderAt: json['reminderAt'] == null
          ? null
          : DateTime.parse(json['reminderAt']! as String),
    );
  }
}

class ReminderSettings {
  const ReminderSettings({
    required this.notificationsEnabled,
    required this.alertMode,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.vibrationLevel,
    required this.activeStart,
    required this.activeEnd,
    required this.intervalMinutes,
    this.notificationSoundUri,
    this.notificationSoundLabel,
  });

  final bool notificationsEnabled;
  final AlertMode alertMode;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final VibrationLevel vibrationLevel;
  final TimeOfDay activeStart;
  final TimeOfDay activeEnd;
  final int intervalMinutes;
  final String? notificationSoundUri;
  final String? notificationSoundLabel;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'notificationsEnabled': notificationsEnabled,
      'alertMode': alertMode.name,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'vibrationLevel': vibrationLevel.name,
      'activeStartMinutes': _toMinutes(activeStart),
      'activeEndMinutes': _toMinutes(activeEnd),
      'intervalMinutes': intervalMinutes,
      'notificationSoundUri': notificationSoundUri,
      'notificationSoundLabel': notificationSoundLabel,
    };
  }

  factory ReminderSettings.fromJson(Map<String, Object?> json) {
    return ReminderSettings(
      notificationsEnabled: json['notificationsEnabled']! as bool,
      alertMode: json['alertMode'] == null
          ? AlertMode.exact
          : AlertMode.values.byName(json['alertMode']! as String),
      soundEnabled: json['soundEnabled']! as bool,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      vibrationLevel: json['vibrationLevel'] == null
          ? VibrationLevel.medium
          : VibrationLevel.values.byName(json['vibrationLevel']! as String),
      activeStart: _fromMinutes(json['activeStartMinutes']! as int),
      activeEnd: _fromMinutes(json['activeEndMinutes']! as int),
      intervalMinutes: json['intervalMinutes']! as int,
      notificationSoundUri: json['notificationSoundUri'] as String?,
      notificationSoundLabel: json['notificationSoundLabel'] as String?,
    );
  }

  ReminderSettings copyWith({
    bool? notificationsEnabled,
    AlertMode? alertMode,
    bool? soundEnabled,
    bool? vibrationEnabled,
    VibrationLevel? vibrationLevel,
    TimeOfDay? activeStart,
    TimeOfDay? activeEnd,
    int? intervalMinutes,
    String? notificationSoundUri,
    String? notificationSoundLabel,
    bool clearNotificationSound = false,
  }) {
    return ReminderSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      alertMode: alertMode ?? this.alertMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      vibrationLevel: vibrationLevel ?? this.vibrationLevel,
      activeStart: activeStart ?? this.activeStart,
      activeEnd: activeEnd ?? this.activeEnd,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      notificationSoundUri: clearNotificationSound
          ? null
          : notificationSoundUri ?? this.notificationSoundUri,
      notificationSoundLabel: clearNotificationSound
          ? null
          : notificationSoundLabel ?? this.notificationSoundLabel,
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
