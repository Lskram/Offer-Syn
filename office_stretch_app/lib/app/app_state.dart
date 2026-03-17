import 'dart:async';

import 'package:flutter/material.dart';

import '../data/exercise_catalog.dart';
import '../models/app_models.dart';
import '../models/persisted_app_data.dart';
import '../models/reminder_diagnostics.dart';
import '../services/app_persistence.dart';
import '../services/reminder_scheduler.dart';
import '../services/reminder_timeline.dart';

class AppState extends ChangeNotifier {
  AppState({AppPersistence? persistence, ReminderScheduler? reminderScheduler})
    : _persistence = persistence ?? InMemoryAppPersistence(),
      _reminderScheduler = reminderScheduler ?? const NoopReminderScheduler();

  final AppPersistence _persistence;
  final ReminderScheduler _reminderScheduler;

  UserProfile? _profile;
  ExerciseProgram? _activeProgram;
  ReminderSettings _settings = defaultReminderSettings;
  final List<ExerciseLog> _logs = <ExerciseLog>[];
  DateTime _nextReminderAt = DateTime.now().add(const Duration(minutes: 60));
  ReminderDiagnostics _reminderDiagnostics =
      const ReminderDiagnostics.unsupported();
  Future<void> _sideEffects = Future<void>.value();

  bool get hasCompletedOnboarding => _profile != null;
  UserProfile? get profile => _profile;
  ExerciseProgram? get activeProgram => _activeProgram;
  ReminderSettings get settings => _settings;
  DateTime get nextReminderAt => _nextReminderAt;
  ReminderDiagnostics get reminderDiagnostics => _reminderDiagnostics;
  bool get hasValidReminderWindow => ReminderTimeline.hasValidWindow(_settings);
  List<ExerciseLog> get logs => List.unmodifiable(_logs.reversed);
  Map<PainArea, List<ExerciseProgram>> get programsByArea =>
      ExerciseCatalog.programsByArea;
  List<TipArticle> get tips => ExerciseCatalog.tips;

  Future<void> initialize() async {
    await _reminderScheduler.initialize();

    PersistedAppData? persistedData;
    try {
      persistedData = await _persistence.load();
    } catch (error) {
      debugPrint('Failed to load persisted app state: $error');
      await _persistence.clear();
    }

    if (persistedData != null) {
      _profile = persistedData.profile;
      _activeProgram = _profile == null
          ? null
          : ExerciseCatalog.recommend(_profile!);
      _settings = persistedData.settings;
      _logs
        ..clear()
        ..addAll(persistedData.logs);
      _nextReminderAt = persistedData.nextReminderAt ?? _defaultNextReminder();
    } else {
      _nextReminderAt = _defaultNextReminder();
    }

    await _refreshReminderDiagnostics(notify: false);
    await _syncAndPersistNow();
    notifyListeners();
  }

  void completeQuestionnaire(UserProfile profile) {
    _profile = profile;
    _activeProgram = ExerciseCatalog.recommend(profile);
    _settings = _settings.copyWith(
      intervalMinutes: _activeProgram!.reminderIntervalMinutes,
    );
    _nextReminderAt = _defaultNextReminder();
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void restartOnboarding() {
    _profile = null;
    _activeProgram = null;
    _logs.clear();
    _settings = defaultReminderSettings;
    _nextReminderAt = _defaultNextReminder();
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  Future<void> requestNotificationPermission() async {
    await _reminderScheduler.requestPermissions();
    await _refreshReminderDiagnostics();
    _queueSideEffects(syncReminders: true);
  }

  Future<void> openNotificationSettings() async {
    await _reminderScheduler.openNotificationSettings();
  }

  Future<void> openBatteryOptimizationSettings() async {
    await _reminderScheduler.openBatteryOptimizationSettings();
  }

  Future<void> refreshReminderDiagnostics() async {
    await _refreshReminderDiagnostics();
  }

  void updateNotificationsEnabled(bool value) {
    _settings = _settings.copyWith(notificationsEnabled: value);
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void updateSoundEnabled(bool value) {
    _settings = _settings.copyWith(soundEnabled: value);
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void updateInterval(int minutes) {
    _settings = _settings.copyWith(intervalMinutes: minutes);
    _nextReminderAt = _normalizedReminder(
      DateTime.now().add(Duration(minutes: minutes)),
    );
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void updateActiveWindow({TimeOfDay? start, TimeOfDay? end}) {
    _settings = _settings.copyWith(
      activeStart: start ?? _settings.activeStart,
      activeEnd: end ?? _settings.activeEnd,
    );
    _nextReminderAt = _normalizedReminder(_nextReminderAt);
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void logExercise(Exercise exercise, ExerciseStatus status) {
    _logs.add(
      ExerciseLog(
        exerciseName: exercise.name,
        status: status,
        occurredAt: DateTime.now(),
      ),
    );
    if (_logs.length > 40) {
      _logs.removeRange(0, _logs.length - 40);
    }
    notifyListeners();
    _queueSideEffects(syncReminders: false);
  }

  void rescheduleAfterSession() {
    _nextReminderAt = _defaultNextReminder();
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void snoozeReminder([int minutes = 10]) {
    _nextReminderAt = _normalizedReminder(
      DateTime.now().add(Duration(minutes: minutes)),
    );
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  PersistedAppData _buildSnapshot() {
    return PersistedAppData(
      profile: _profile,
      settings: _settings,
      logs: List<ExerciseLog>.from(_logs),
      nextReminderAt: _nextReminderAt,
    );
  }

  void _queueSideEffects({required bool syncReminders}) {
    _sideEffects = _sideEffects
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('AppState side effect failed: $error');
        })
        .then((_) async {
          if (syncReminders) {
            await _syncReminders();
          }
          await _persistence.save(_buildSnapshot());
        });
  }

  Future<void> _syncAndPersistNow() async {
    await _syncReminders();
    await _persistence.save(_buildSnapshot());
  }

  Future<void> _refreshReminderDiagnostics({bool notify = true}) async {
    _reminderDiagnostics = await _reminderScheduler.diagnostics();
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _syncReminders() async {
    final schedule = await _reminderScheduler.sync(
      settings: _settings,
      requestedStartAt: _normalizedReminder(_nextReminderAt),
      program: _activeProgram,
    );
    await _refreshReminderDiagnostics(notify: false);

    if (schedule.isNotEmpty) {
      final alignedReminder = schedule.first;
      if (_nextReminderAt != alignedReminder) {
        _nextReminderAt = alignedReminder;
        notifyListeners();
      }
    }
  }

  DateTime _defaultNextReminder() {
    return _normalizedReminder(
      DateTime.now().add(Duration(minutes: _settings.intervalMinutes)),
    );
  }

  DateTime _normalizedReminder(DateTime requestedReminder) {
    if (!hasValidReminderWindow) {
      return requestedReminder;
    }

    final schedule = ReminderTimeline.buildSchedule(
      requestedStartAt: requestedReminder,
      settings: _settings,
      maxEntries: 1,
      horizon: const Duration(days: 2),
    );
    return schedule.isEmpty ? requestedReminder : schedule.first;
  }
}
