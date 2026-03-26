import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/home_shell.dart';
import '../screens/questionnaire_screen.dart';
import 'app_state.dart';

class OfficeStretchApp extends StatefulWidget {
  const OfficeStretchApp({super.key, required this.appState});

  final AppState appState;

  @override
  State<OfficeStretchApp> createState() => _OfficeStretchAppState();
}

class _OfficeStretchAppState extends State<OfficeStretchApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.appState.handleAppResumed();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(widget.appState.handleAppBackgrounded());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'OfficeRelief',
          theme: _buildTheme(),
          home: widget.appState.hasCompletedOnboarding
              ? HomeShell(appState: widget.appState)
              : QuestionnaireScreen(appState: widget.appState),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    const seed = Color(0xFF0A67D9);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: const Color(0xFF0A67D9),
      secondary: const Color(0xFF22C7E2),
      tertiary: const Color(0xFFC8F33A),
      surface: const Color(0xFFF7FCFF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF3FBFF),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF062348),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: const Color(0xFF062348),
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF0C223F),
        displayColor: const Color(0xFF0C223F),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE3F4FF),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant;
          return TextStyle(fontWeight: FontWeight.w600, color: color);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0A67D9),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0A67D9),
          side: const BorderSide(color: Color(0xFFB3DAFF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        disabledColor: const Color(0xFFEAF4FC),
        selectedColor: const Color(0xFFDFF3FF),
        secondarySelectedColor: const Color(0xFFDFF3FF),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: BorderSide(color: colorScheme.outlineVariant),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        brightness: Brightness.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF0A67D9), width: 1.6),
        ),
      ),
    );
  }
}
