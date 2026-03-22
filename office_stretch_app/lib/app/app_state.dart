import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/exercise_catalog.dart';
import '../models/app_models.dart';
import '../models/persisted_app_data.dart';
import '../models/reminder_diagnostics.dart';
import '../models/reminder_sync_state.dart';
import '../models/system_notification_sound.dart';
import '../services/app_persistence.dart';
import '../services/reminder_scheduler.dart';
import '../services/reminder_timeline.dart';

typedef NowGetter = DateTime Function();

class AppState extends ChangeNotifier {
  AppState({
    AppPersistence? persistence,
    ReminderScheduler? reminderScheduler,
    NowGetter? now,
  }) : _persistence = persistence ?? InMemoryAppPersistence(),
       _reminderScheduler = reminderScheduler ?? const NoopReminderScheduler(),
       _now = now ?? DateTime.now;

  final AppPersistence _persistence;
  final ReminderScheduler _reminderScheduler;
  final NowGetter _now;

  UserProfile? _profile;
  ExercisePlan? _activePlan;
  ReminderSettings _settings = defaultReminderSettings;
  final List<ExerciseLog> _logs = <ExerciseLog>[];
  DateTime _nextReminderAt = DateTime.now().add(const Duration(minutes: 60));
  ReminderDiagnostics _reminderDiagnostics =
      const ReminderDiagnostics.unsupported();
  ReminderSyncState _reminderSyncState = const ReminderSyncState.empty();
  Future<void> _sideEffects = Future<void>.value();
  StreamSubscription<String?>? _notificationResponseSubscription;
  PendingReminderLaunch? _pendingReminderLaunch;
  int _programLaunchSequence = 0;
  bool _isRepairingReminderQueue = false;

  bool get hasCompletedOnboarding => _profile != null;
  UserProfile? get profile => _profile;
  ExercisePlan? get activePlan => _activePlan;
  ReminderSettings get settings => _settings;
  DateTime get nextReminderAt => _nextReminderAt;
  ReminderDiagnostics get reminderDiagnostics => _reminderDiagnostics;
  ReminderSyncState get reminderSyncState => _reminderSyncState;
  bool get hasValidReminderWindow => ReminderTimeline.hasValidWindow(_settings);
  bool get hasPendingReminderLaunch => _pendingReminderLaunch != null;
  List<ExerciseLog> get logs => List.unmodifiable(_logs.reversed);
  DateTime get currentTime => _now();
  Map<PainArea, List<ExerciseProgram>> get programsByArea =>
      ExerciseCatalog.programsByArea;
  List<TipArticle> get tips => ExerciseCatalog.tips;
  int get pendingReminderLaunchSequence => _programLaunchSequence;

  int get missedRemindersToday {
    final today = _now();
    return _logs
        .where(
          (log) =>
              log.status == ExerciseStatus.missed &&
              _isSameDay(log.occurredAt, today),
        )
        .length;
  }

  bool get hasMissedRemindersToday => missedRemindersToday > 0;

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
      _activePlan = _profile == null
          ? null
          : ExerciseCatalog.buildPlan(_profile!);
      _settings = persistedData.settings;
      _logs
        ..clear()
        ..addAll(persistedData.logs);
      _nextReminderAt = persistedData.nextReminderAt ?? _defaultNextReminder();
      _reminderSyncState = persistedData.reminderSyncState;
    } else {
      _nextReminderAt = _defaultNextReminder();
    }

    _handleNotificationPayload(
      _reminderScheduler.takePendingNotificationPayload(),
    );
    _notificationResponseSubscription = _reminderScheduler.notificationResponses
        .listen(_handleNotificationPayload);

    _reconcileMissedReminders(now: _now());
    await _refreshReminderDiagnostics(notify: false);
    await _syncAndPersistNow();
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationResponseSubscription?.cancel();
    super.dispose();
  }

  void completeQuestionnaire(UserProfile profile) {
    savePlan(profile: profile);
  }

  void savePlan({
    required UserProfile profile,
    int? intervalMinutes,
    TimeOfDay? activeStart,
    TimeOfDay? activeEnd,
  }) {
    _profile = profile;
    _activePlan = ExerciseCatalog.buildPlan(profile);
    _settings = _settings.copyWith(
      intervalMinutes: intervalMinutes ?? _activePlan!.reminderIntervalMinutes,
      activeStart: activeStart ?? _settings.activeStart,
      activeEnd: activeEnd ?? _settings.activeEnd,
    );
    _nextReminderAt = _defaultNextReminder();
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void restartOnboarding() {
    _profile = null;
    _activePlan = null;
    _logs.clear();
    _settings = defaultReminderSettings;
    _nextReminderAt = _defaultNextReminder();
    _pendingReminderLaunch = null;
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  Future<void> requestNotificationPermission() async {
    await _reminderScheduler.requestPermissions();
    await _refreshReminderDiagnostics();
    _queueSideEffects(syncReminders: true);
  }

  Future<void> maybeRequestNotificationPermissionOnForeground() async {
    if (!_settings.notificationsEnabled ||
        !_reminderDiagnostics.supportsPermissionPrompt ||
        _reminderDiagnostics.notificationsEnabled == true) {
      return;
    }

    await requestNotificationPermission();
  }

  Future<void> requestExactAlarmPermission() async {
    await _reminderScheduler.requestExactAlarmPermission();
    await _refreshReminderDiagnostics();
    _queueSideEffects(syncReminders: true);
  }

  Future<void> openNotificationSettings() async {
    await _reminderScheduler.openNotificationSettings();
  }

  Future<void> openBatteryOptimizationSettings() async {
    await _reminderScheduler.openBatteryOptimizationSettings();
  }

  Future<void> openFullScreenIntentSettings() async {
    await _reminderScheduler.openFullScreenIntentSettings();
  }

  Future<void> sendTestNotificationNow() async {
    await _reminderScheduler.sendTestNotification(
      settings: _settings,
      plan: _activePlan,
    );
    await _refreshReminderDiagnostics();
    notifyListeners();
  }

  Future<void> refreshReminderDiagnostics() async {
    await _refreshReminderDiagnostics();
  }

  Future<void> resyncRemindersNow() async {
    if (_settings.notificationsEnabled &&
        _activePlan != null &&
        hasValidReminderWindow) {
      _nextReminderAt = _recalculateNextReminderFromNow();
      notifyListeners();
    }
    _queueSideEffects(syncReminders: true);
    await _sideEffects;
    notifyListeners();
  }

  void handleAppResumed() {
    _reconcileMissedReminders(now: _now());
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  PendingReminderLaunch? consumePendingReminderLaunch() {
    final launch = _pendingReminderLaunch;
    if (launch == null) {
      return null;
    }

    _pendingReminderLaunch = null;
    return launch;
  }

  void stageReminderLaunchPayload(String payload) {
    _handleNotificationPayload(payload);
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

  void updateAlertMode(AlertMode value) {
    _settings = _settings.copyWith(alertMode: value);
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void updateVibrationEnabled(bool value) {
    _settings = _settings.copyWith(vibrationEnabled: value);
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void updateVibrationLevel(VibrationLevel value) {
    _settings = _settings.copyWith(vibrationLevel: value);
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  Future<void> pickNotificationSound() async {
    final selection = await _reminderScheduler.pickSystemNotificationSound(
      existingUri: _settings.notificationSoundUri,
    );
    if (selection == null) {
      return;
    }

    if (selection.isDefault) {
      useDefaultNotificationSound();
      return;
    }

    _applyNotificationSound(selection);
  }

  void useDefaultNotificationSound() {
    _settings = _settings.copyWith(clearNotificationSound: true);
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void updateInterval(int minutes) {
    _settings = _settings.copyWith(intervalMinutes: minutes);
    _nextReminderAt = _recalculateNextReminderFromNow();
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void updateActiveWindow({TimeOfDay? start, TimeOfDay? end}) {
    _settings = _settings.copyWith(
      activeStart: start ?? _settings.activeStart,
      activeEnd: end ?? _settings.activeEnd,
    );
    _nextReminderAt = _recalculateNextReminderFromNow();
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void logExercise(
    Exercise exercise,
    ExerciseStatus status, {
    DateTime? reminderAt,
  }) {
    _appendLog(
      ExerciseLog(
        exerciseName: exercise.name,
        status: status,
        occurredAt: _now(),
        reminderAt: reminderAt,
      ),
    );
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
      _now().add(Duration(minutes: minutes)),
    );
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void snoozePendingReminder(PendingReminderLaunch launch, [int minutes = 10]) {
    _logReminderAction(
      status: ExerciseStatus.snoozed,
      reminderAt: launch.reminderAt,
      fallbackLabel: launch.plan.title,
    );
    _nextReminderAt = _normalizedReminder(
      _now().add(Duration(minutes: minutes)),
    );
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void dismissPendingReminder(PendingReminderLaunch launch) {
    _logReminderAction(
      status: ExerciseStatus.skipped,
      reminderAt: launch.reminderAt,
      fallbackLabel: launch.plan.title,
    );
    _nextReminderAt = _defaultNextReminder();
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  Future<void> waitForIdle() => _sideEffects;

  @visibleForTesting
  Future<void> settleSideEffects() => waitForIdle();

  PersistedAppData _buildSnapshot() {
    return PersistedAppData(
      profile: _profile,
      settings: _settings,
      logs: List<ExerciseLog>.from(_logs),
      nextReminderAt: _nextReminderAt,
      reminderSyncState: _reminderSyncState,
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
    try {
      var syncState = await _reminderScheduler.sync(
        settings: _settings,
        requestedStartAt: _normalizedReminder(_nextReminderAt),
        plan: _activePlan,
      );

      if (_shouldRepairReminderQueue(syncState)) {
        syncState = await _repairReminderQueue(syncState);
      }

      _reminderSyncState = syncState;
      await _refreshReminderDiagnostics(notify: false);

      final alignedReminder = syncState.nextReminderAt;
      if (alignedReminder != null && _nextReminderAt != alignedReminder) {
        _nextReminderAt = alignedReminder;
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Reminder sync failed: $error');
      await _refreshReminderDiagnostics(notify: false);
      _reminderSyncState = ReminderSyncState(
        requestedReminderCount: 0,
        pendingRequestCount: 0,
        scheduledReminders: const <ScheduledReminderEntry>[],
        usesExactScheduling: _reminderDiagnostics.usesExactScheduling,
        usesFullScreenIntent: false,
        notificationsPermissionAtSync:
            _reminderDiagnostics.notificationsEnabled,
        syncedAt: _now(),
        nextReminderAt: _nextReminderAt,
        lastError: error.toString(),
      );
      notifyListeners();
    }
  }

  bool _shouldRepairReminderQueue(ReminderSyncState syncState) {
    return !_isRepairingReminderQueue &&
        _activePlan != null &&
        _settings.notificationsEnabled &&
        hasValidReminderWindow &&
        syncState.notificationsPermissionAtSync != false &&
        syncState.needsRepair;
  }

  Future<ReminderSyncState> _repairReminderQueue(
    ReminderSyncState failedSyncState,
  ) async {
    if (_activePlan == null) {
      return failedSyncState;
    }

    _isRepairingReminderQueue = true;
    try {
      final repairedStartAt = _recalculateNextReminderFromNow();
      final repairedState = await _reminderScheduler.sync(
        settings: _settings,
        requestedStartAt: _normalizedReminder(repairedStartAt),
        plan: _activePlan,
      );

      if (!repairedState.needsRepair) {
        _nextReminderAt = repairedState.nextReminderAt ?? repairedStartAt;
        return repairedState.copyWith(clearLastError: true);
      }

      return repairedState.copyWith(
        lastError:
            '${failedSyncState.lastError ?? 'Reminder queue needs repair.'} Repair retry did not restore the queue.',
      );
    } catch (error) {
      return failedSyncState.copyWith(
        lastError:
            '${failedSyncState.lastError ?? 'Reminder queue needs repair.'} Repair retry failed: $error',
      );
    } finally {
      _isRepairingReminderQueue = false;
    }
  }

  DateTime _defaultNextReminder() {
    return _recalculateNextReminderFromNow();
  }

  DateTime _normalizedReminder(DateTime requestedReminder) {
    if (!hasValidReminderWindow) {
      return requestedReminder;
    }

    if (requestedReminder.isBefore(_now())) {
      return _recalculateNextReminderFromNow();
    }

    final schedule = ReminderTimeline.buildSchedule(
      requestedStartAt: requestedReminder,
      settings: _settings,
      maxEntries: 1,
      horizon: const Duration(days: 2),
      now: _now(),
    );
    return schedule.isEmpty ? requestedReminder : schedule.first;
  }

  DateTime _recalculateNextReminderFromNow() {
    if (!hasValidReminderWindow) {
      return _now();
    }

    return ReminderTimeline.nextAlignedSlotAtOrAfter(
      _now(),
      _settings,
      now: _now(),
    );
  }

  void _applyNotificationSound(SystemNotificationSound selection) {
    _settings = _settings.copyWith(
      notificationSoundUri: selection.uri,
      notificationSoundLabel: selection.label,
    );
    notifyListeners();
    _queueSideEffects(syncReminders: true);
  }

  void _appendLog(ExerciseLog log) {
    _logs.add(log);
    if (_logs.length > 40) {
      _logs.removeRange(0, _logs.length - 40);
    }
  }

  void _handleNotificationPayload(String? payload) {
    final launchPayload = _parseReminderLaunchPayload(payload);
    if (_activePlan == null || launchPayload?.planId != _activePlan!.id) {
      return;
    }

    _pendingReminderLaunch = PendingReminderLaunch(
      plan: _activePlan!,
      alertMode: launchPayload?.alertMode ?? _settings.alertMode,
      reminderAt: launchPayload?.reminderAt,
      isTest: launchPayload?.isTest ?? false,
    );
    _programLaunchSequence += 1;
    notifyListeners();
  }

  ReminderLaunchPayload? _parseReminderLaunchPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return ReminderLaunchPayload.fromJson(decoded);
      }
    } catch (_) {
      // Fallback to the legacy payload format where the program id was stored directly.
    }

    return ReminderLaunchPayload(planId: payload);
  }

  void _reconcileMissedReminders({required DateTime now}) {
    if (_activePlan == null ||
        !_settings.notificationsEnabled ||
        !hasValidReminderWindow ||
        !_reminderSyncState.canTrustMissedInference) {
      return;
    }

    final scheduledReminders = _reminderSyncState.scheduledReminders.toList(
      growable: false,
    )..sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));

    for (var index = 0; index < scheduledReminders.length; index += 1) {
      final dueReminder = scheduledReminders[index].scheduledAt;
      if (!dueReminder.isBefore(now)) {
        break;
      }

      final nextDueReminder = index + 1 < scheduledReminders.length
          ? scheduledReminders[index + 1].scheduledAt
          : ReminderTimeline.nextAlignedSlotAtOrAfter(
              dueReminder.add(Duration(minutes: _settings.intervalMinutes)),
              _settings,
              now: DateTime.fromMillisecondsSinceEpoch(0),
            );

      if (nextDueReminder.isAfter(now)) {
        break;
      }

      if (!_hasCompletedBetween(dueReminder, nextDueReminder) &&
          !_hasHandledReminder(dueReminder)) {
        _appendLog(
          ExerciseLog(
            exerciseName:
                'พลาดการแจ้งเตือนรอบ ${_formatReminderTime(dueReminder)}',
            status: ExerciseStatus.missed,
            occurredAt: dueReminder,
            reminderAt: dueReminder,
          ),
        );
      }
    }
  }

  bool _hasCompletedBetween(DateTime startInclusive, DateTime endExclusive) {
    return _logs.any(
      (log) =>
          log.status == ExerciseStatus.done &&
          !log.occurredAt.isBefore(startInclusive) &&
          log.occurredAt.isBefore(endExclusive),
    );
  }

  bool _hasHandledReminder(DateTime reminderAt) {
    return _logs.any(
      (log) => log.reminderAt?.isAtSameMomentAs(reminderAt) == true,
    );
  }

  void _logReminderAction({
    required ExerciseStatus status,
    required DateTime? reminderAt,
    required String fallbackLabel,
  }) {
    final actionLabel = switch (status) {
      ExerciseStatus.snoozed => 'เลื่อนแจ้งเตือนรอบ',
      ExerciseStatus.skipped => 'ปิดแจ้งเตือนรอบ',
      ExerciseStatus.done => 'ทำตามแจ้งเตือนรอบ',
      ExerciseStatus.missed => 'พลาดแจ้งเตือนรอบ',
    };
    final timeLabel = reminderAt == null
        ? fallbackLabel
        : _formatReminderTime(reminderAt);

    _appendLog(
      ExerciseLog(
        exerciseName: '$actionLabel $timeLabel',
        status: status,
        occurredAt: _now(),
        reminderAt: reminderAt,
      ),
    );
  }

  String _formatReminderTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
