import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../data/exercise_catalog.dart';
import '../models/app_models.dart';
import '../services/host_activity_bridge.dart';
import 'alarm_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'plan_editor_screen.dart';
import 'pre_session_screen.dart';
import 'session_screen.dart';
import 'settings_screen.dart';
import 'tips_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.appState});

  final AppState appState;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  int _lastHandledLaunchSequence = 0;
  bool _isSessionOpen = false;
  bool _isAlarmOpen = false;
  bool _hasRequestedReminderPermission = false;
  bool _isPermissionReviewDialogOpen = false;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_handleAppStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAppStateChanged();
      if (!_isAlarmOpen &&
          !_isSessionOpen &&
          !widget.appState.hasPendingReminderLaunch) {
        _maybeRequestReminderPermission().whenComplete(
          _maybeShowPermissionReviewDialog,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState == widget.appState) {
      return;
    }

    oldWidget.appState.removeListener(_handleAppStateChanged);
    widget.appState.addListener(_handleAppStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAppStateChanged();
      if (!_isAlarmOpen &&
          !_isSessionOpen &&
          !widget.appState.hasPendingReminderLaunch) {
        _maybeRequestReminderPermission().whenComplete(
          _maybeShowPermissionReviewDialog,
        );
      }
    });
  }

  @override
  void dispose() {
    widget.appState.removeListener(_handleAppStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        appState: widget.appState,
        onStartPlan: _openPlan,
        onEditPlan: _openPlanEditor,
      ),
      ExerciseLibraryScreen(
        appState: widget.appState,
        onStartProgram: _openProgram,
      ),
      TipsScreen(appState: widget.appState),
      HistoryScreen(appState: widget.appState),
      SettingsScreen(appState: widget.appState),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.accessibility_new_outlined),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.tips_and_updates_outlined),
            label: 'Tips',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _handleAppStateChanged() {
    if (!widget.appState.hasCompletedOnboarding) {
      _hasRequestedReminderPermission = false;
    }
    if (!mounted || _isSessionOpen || _isAlarmOpen) {
      return;
    }

    final launchSequence = widget.appState.pendingReminderLaunchSequence;
    if (launchSequence == _lastHandledLaunchSequence) {
      return;
    }

    _lastHandledLaunchSequence = launchSequence;
    final launch = widget.appState.consumePendingReminderLaunch();
    if (launch == null) {
      _maybeRequestReminderPermission().whenComplete(
        _maybeShowPermissionReviewDialog,
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isSessionOpen || _isAlarmOpen) {
        return;
      }
      _openReminderLaunch(launch);
    });
  }

  Future<void> _maybeRequestReminderPermission() async {
    if (!mounted || _hasRequestedReminderPermission) {
      return;
    }

    _hasRequestedReminderPermission = true;
    await widget.appState.maybeRequestNotificationPermissionOnForeground();
  }

  Future<void> _maybeShowPermissionReviewDialog() async {
    if (!mounted ||
        _isSessionOpen ||
        _isAlarmOpen ||
        _isPermissionReviewDialogOpen) {
      return;
    }

    if (!widget.appState.consumePermissionReviewAfterOnboardingReset()) {
      return;
    }

    _isPermissionReviewDialogOpen = true;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final diagnostics = widget.appState.reminderDiagnostics;
        return AlertDialog(
          title: const Text('รีวิวสิทธิ์ของระบบอีกครั้ง'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OfficeRelief ล้างแผน ประวัติ และคิวเตือนของแอปแล้ว แต่ Android ไม่อนุญาตให้แอปรีเซ็ต permission หรือ cache ระดับระบบให้เหมือนติดตั้งใหม่ได้เอง.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'ถ้าต้องการเริ่มทดสอบใหม่ให้ใกล้เคียงที่สุด ควรรีวิวสิทธิ์เหล่านี้อีกครั้ง:',
                ),
                const SizedBox(height: 8),
                const Text('• Notification permission'),
                const Text('• Exact alarm'),
                const Text('• Battery unrestricted'),
                if (widget.appState.settings.alertMode.prefersFullScreenIntent)
                  const Text('• Full-screen intent'),
                if (diagnostics.notificationsEnabled == false) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'ตอนนี้ notification permission ยังไม่พร้อม',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (diagnostics.supportsPermissionPrompt)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await widget.appState.requestNotificationPermission();
                },
                child: const Text('ขอสิทธิ์แจ้งเตือน'),
              ),
            if (diagnostics.supportsNotificationSettings)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await widget.appState.openNotificationSettings();
                },
                child: const Text('Notification'),
              ),
            if (diagnostics.supportsExactAlarmPermissionPrompt)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await widget.appState.requestExactAlarmPermission();
                },
                child: const Text('Exact alarm'),
              ),
            if (diagnostics.supportsBatteryOptimizationSettings)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await widget.appState.openBatteryOptimizationSettings();
                },
                child: const Text('Battery'),
              ),
            if (diagnostics.supportsFullScreenIntentSettings &&
                widget.appState.settings.alertMode.prefersFullScreenIntent)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await widget.appState.openFullScreenIntentSettings();
                },
                child: const Text('Full-screen'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
    _isPermissionReviewDialogOpen = false;
  }

  Future<void> _openReminderLaunch(PendingReminderLaunch launch) async {
    if (launch.opensAlarmScreen) {
      _isAlarmOpen = true;
      final action = await Navigator.of(context).push<AlarmScreenAction>(
        MaterialPageRoute<AlarmScreenAction>(
          builder: (_) => AlarmScreen(launch: launch),
        ),
      );
      _isAlarmOpen = false;
      if (!mounted) {
        return;
      }

      var openedSession = false;
      switch (action) {
        case AlarmScreenAction.start:
          unawaited(stopAlarmAttentionIfPresent());
          openedSession = await _openAlarmPrepAndSession(launch);
          break;
        case AlarmScreenAction.snooze:
          unawaited(stopAlarmAttentionIfPresent());
          widget.appState.snoozePendingReminder(launch);
          await finishAlarmHostIfPresent();
          break;
        case AlarmScreenAction.dismiss:
          unawaited(stopAlarmAttentionIfPresent());
          widget.appState.dismissPendingReminder(launch);
          await finishAlarmHostIfPresent();
          break;
        case null:
          break;
      }

      if (!openedSession) {
        _handleAppStateChanged();
      }
      return;
    }

    _openPlan(launch.plan, reminderAt: launch.reminderAt);
  }

  Future<bool> _openAlarmPrepAndSession(PendingReminderLaunch launch) async {
    final countdownSeconds = widget.appState.settings.preSessionCountdownSeconds;
    if (countdownSeconds > 0) {
      final prepAction = await Navigator.of(context).push<PreSessionScreenAction>(
        MaterialPageRoute<PreSessionScreenAction>(
          builder: (_) => PreSessionScreen(
            plan: launch.plan,
            countdownSeconds: countdownSeconds,
          ),
        ),
      );

      if (!mounted || prepAction != PreSessionScreenAction.startNow) {
        widget.appState.dismissPendingReminder(launch);
        await finishAlarmHostIfPresent();
        return false;
      }
    }

    _openPlan(launch.plan, reminderAt: launch.reminderAt);
    return true;
  }

  void _openPlan(ExercisePlan plan, {DateTime? reminderAt}) {
    if (_isSessionOpen) {
      return;
    }

    _isSessionOpen = true;
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ExerciseSessionScreen(
              appState: widget.appState,
              plan: plan,
              reminderAt: reminderAt,
            ),
          ),
        )
        .whenComplete(() {
          _isSessionOpen = false;
          _handleAppStateChanged();
        });
  }

  void _openProgram(ExerciseProgram program) {
    _openPlan(ExerciseCatalog.buildPlanFromProgram(program));
  }

  void _openPlanEditor() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlanEditorScreen(appState: widget.appState),
      ),
    );
  }
}
