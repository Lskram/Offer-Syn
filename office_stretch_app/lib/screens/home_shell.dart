import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../data/exercise_catalog.dart';
import '../models/app_models.dart';
import 'alarm_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
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

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_handleAppStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAppStateChanged();
      if (!_isAlarmOpen && !_isSessionOpen) {
        _maybeRequestReminderPermission();
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
      if (!_isAlarmOpen && !_isSessionOpen) {
        _maybeRequestReminderPermission();
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
      HomeScreen(appState: widget.appState, onStartPlan: _openPlan),
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
          _openPlan(launch.plan, reminderAt: launch.reminderAt);
          openedSession = true;
          break;
        case AlarmScreenAction.snooze:
          widget.appState.snoozePendingReminder(launch);
          break;
        case AlarmScreenAction.dismiss:
          widget.appState.dismissPendingReminder(launch);
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
}
