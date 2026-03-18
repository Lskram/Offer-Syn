import 'package:flutter/material.dart';

import '../models/app_models.dart';

abstract final class AppKeys {
  static const questionnaireScreen = ValueKey<String>('screen.questionnaire');
  static const questionnaireSubmit = ValueKey<String>('questionnaire.submit');

  static ValueKey<String> painAreaOption(PainArea value) {
    return ValueKey<String>('questionnaire.painArea.${value.name}');
  }

  static ValueKey<String> painLevelOption(PainLevel value) {
    return ValueKey<String>('questionnaire.painLevel.${value.name}');
  }

  static ValueKey<String> workHoursOption(WorkHours value) {
    return ValueKey<String>('questionnaire.workHours.${value.name}');
  }

  static ValueKey<String> stretchHabitOption(StretchHabit value) {
    return ValueKey<String>('questionnaire.stretchHabit.${value.name}');
  }

  static const homeScreen = ValueKey<String>('screen.home');
  static const homeStartProgram = ValueKey<String>('home.startProgram');
  static const homeSnoozeReminder = ValueKey<String>('home.snoozeReminder');
  static const homeMissedReminderCard = ValueKey<String>(
    'home.missedReminderCard',
  );

  static const libraryScreen = ValueKey<String>('screen.library');

  static ValueKey<String> libraryStartProgram(String programId) {
    return ValueKey<String>('library.startProgram.$programId');
  }

  static const tipsScreen = ValueKey<String>('screen.tips');

  static const settingsScreen = ValueKey<String>('screen.settings');
  static const settingsNotificationsEnabled = ValueKey<String>(
    'settings.notificationsEnabled',
  );
  static const settingsSoundEnabled = ValueKey<String>('settings.soundEnabled');
  static const settingsVibrationEnabled = ValueKey<String>(
    'settings.vibrationEnabled',
  );
  static const settingsVibrationLevel = ValueKey<String>(
    'settings.vibrationLevel',
  );
  static const settingsPickSound = ValueKey<String>('settings.pickSound');
  static const settingsResetSound = ValueKey<String>('settings.resetSound');
  static const settingsTestNotification = ValueKey<String>(
    'settings.testNotification',
  );
  static const settingsResyncReminders = ValueKey<String>(
    'settings.resyncReminders',
  );
  static const settingsRequestExactAlarm = ValueKey<String>(
    'settings.requestExactAlarm',
  );
  static const settingsIntervalMinutes = ValueKey<String>(
    'settings.intervalMinutes',
  );

  static ValueKey<String> settingsIntervalOption(int minutes) {
    return ValueKey<String>('settings.intervalOption.$minutes');
  }

  static const settingsRestartOnboarding = ValueKey<String>(
    'settings.restartOnboarding',
  );

  static const sessionScreen = ValueKey<String>('screen.session');
  static const sessionSkip = ValueKey<String>('session.skip');
  static const sessionSnooze = ValueKey<String>('session.snooze');
  static const sessionComplete = ValueKey<String>('session.complete');
  static const sessionFinishClose = ValueKey<String>('session.finish.close');
}
