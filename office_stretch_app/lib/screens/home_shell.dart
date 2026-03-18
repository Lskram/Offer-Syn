import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../models/app_models.dart';
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
  bool _hasRequestedReminderPermission = false;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_handleAppStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRequestReminderPermission();
      _handleAppStateChanged();
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
      _maybeRequestReminderPermission();
      _handleAppStateChanged();
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
      HomeScreen(appState: widget.appState, onStartProgram: _openProgram),
      ExerciseLibraryScreen(
        appState: widget.appState,
        onStartProgram: _openProgram,
      ),
      TipsScreen(appState: widget.appState),
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
            icon: Icon(Icons.tune_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _handleAppStateChanged() {
    if (!mounted || _isSessionOpen) {
      return;
    }

    final launchSequence = widget.appState.pendingProgramLaunchSequence;
    if (launchSequence == _lastHandledLaunchSequence) {
      return;
    }

    _lastHandledLaunchSequence = launchSequence;
    final program = widget.appState.consumePendingProgramLaunch();
    if (program == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isSessionOpen) {
        return;
      }
      _openProgram(program);
    });
  }

  Future<void> _maybeRequestReminderPermission() async {
    if (!mounted || _hasRequestedReminderPermission) {
      return;
    }

    _hasRequestedReminderPermission = true;
    await widget.appState.maybeRequestNotificationPermissionOnForeground();
  }

  void _openProgram(ExerciseProgram program) {
    if (_isSessionOpen) {
      return;
    }

    _isSessionOpen = true;
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ExerciseSessionScreen(
              appState: widget.appState,
              program: program,
            ),
          ),
        )
        .whenComplete(() {
          _isSessionOpen = false;
        });
  }
}
