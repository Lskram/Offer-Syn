import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../app/app_state.dart';
import '../models/app_models.dart';
import '../widgets/office_relief_complete_state.dart';

class ExerciseSessionScreen extends StatefulWidget {
  const ExerciseSessionScreen({
    super.key,
    required this.appState,
    required this.plan,
    this.reminderAt,
  });

  final AppState appState;
  final ExercisePlan plan;
  final DateTime? reminderAt;

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  Timer? _metricsRecoveryTimer;
  int _tickerGeneration = 0;
  int _exerciseRunToken = 0;
  int _exerciseIndex = 0;
  int _remainingSeconds = 0;
  int _completedCount = 0;
  int _skippedCount = 0;
  bool _isTransitioning = false;

  PlannedExercise get _currentEntry => widget.plan.exercises[_exerciseIndex];
  Exercise get _currentExercise => _currentEntry.exercise;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _beginCurrentExercise();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _metricsRecoveryTimer?.cancel();
    _invalidateTicker();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _recoverTickerAfterEnvironmentChange();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _recoverTickerAfterEnvironmentChange();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _invalidateTicker();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _currentEntry;
    final exercise = entry.exercise;
    final theme = Theme.of(context);

    return Scaffold(
      key: AppKeys.sessionScreen,
      appBar: AppBar(title: Text(widget.plan.title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactLayout = constraints.maxHeight < 620;
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final bodyPadding = compactLayout ? 16.0 : 20.0;
            final headerGap = compactLayout ? 6.0 : 8.0;
            final blockGap = compactLayout ? 10.0 : 14.0;
            final actionPadding = compactLayout ? 10.0 : 12.0;

            return Padding(
              padding: EdgeInsets.all(bodyPadding),
              child: isLandscape
                  ? _buildLandscapeLayout(
                      theme: theme,
                      entry: entry,
                      exercise: exercise,
                      compactLayout: compactLayout,
                      headerGap: headerGap,
                      blockGap: blockGap,
                      actionPadding: actionPadding,
                    )
                  : _buildPortraitLayout(
                      theme: theme,
                      entry: entry,
                      exercise: exercise,
                      compactLayout: compactLayout,
                      headerGap: headerGap,
                      blockGap: blockGap,
                      actionPadding: actionPadding,
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout({
    required ThemeData theme,
    required PlannedExercise entry,
    required Exercise exercise,
    required bool compactLayout,
    required double headerGap,
    required double blockGap,
    required double actionPadding,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SessionHeader(
          exerciseIndex: _exerciseIndex,
          totalExercises: widget.plan.exercises.length,
          exercise: exercise,
          theme: theme,
          headerGap: headerGap,
        ),
        SizedBox(height: blockGap),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _ExerciseVisualCard(
                    key: ValueKey<String>(exercise.id),
                    entry: entry,
                    compact: compactLayout,
                  ),
                ),
                SizedBox(height: blockGap),
                _SessionCountdownHero(
                  remainingSeconds: _remainingSeconds,
                  totalSeconds: exercise.durationSeconds,
                  requiresStanding: exercise.requiresStanding,
                  compact: compactLayout,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: compactLayout ? 16 : 20),
        _SessionActionPanel(
          compact: compactLayout,
          blockGap: blockGap,
          actionPadding: actionPadding,
          isTransitioning: _isTransitioning,
          onSkip: () => _advance(ExerciseStatus.skipped),
          onSnooze: () => _advance(ExerciseStatus.snoozed),
          onComplete: () => _advance(ExerciseStatus.done),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout({
    required ThemeData theme,
    required PlannedExercise entry,
    required Exercise exercise,
    required bool compactLayout,
    required double headerGap,
    required double blockGap,
    required double actionPadding,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SessionHeader(
                exerciseIndex: _exerciseIndex,
                totalExercises: widget.plan.exercises.length,
                exercise: exercise,
                theme: theme,
                headerGap: headerGap,
              ),
              SizedBox(height: blockGap),
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _ExerciseVisualCard(
                      key: ValueKey<String>(exercise.id),
                      entry: entry,
                      compact: compactLayout,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: blockGap + 2),
        Expanded(
          flex: 9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _SessionCountdownHero(
                    remainingSeconds: _remainingSeconds,
                    totalSeconds: exercise.durationSeconds,
                    requiresStanding: exercise.requiresStanding,
                    compact: compactLayout,
                  ),
                ),
              ),
              SizedBox(height: blockGap),
              _SessionActionPanel(
                compact: compactLayout,
                blockGap: blockGap,
                actionPadding: actionPadding,
                isTransitioning: _isTransitioning,
                onSkip: () => _advance(ExerciseStatus.skipped),
                onSnooze: () => _advance(ExerciseStatus.snoozed),
                onComplete: () => _advance(ExerciseStatus.done),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _beginCurrentExercise() {
    _invalidateTicker();
    final exerciseRunToken = ++_exerciseRunToken;
    setState(() {
      _remainingSeconds = _currentExercise.durationSeconds;
    });
    _startTicker(exerciseRunToken: exerciseRunToken);
  }

  void _startTicker({required int exerciseRunToken}) {
    _metricsRecoveryTimer?.cancel();
    final tickerGeneration = ++_tickerGeneration;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (tickerGeneration != _tickerGeneration) {
        timer.cancel();
        return;
      }
      if (exerciseRunToken != _exerciseRunToken) {
        timer.cancel();
        return;
      }
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _advance(
          ExerciseStatus.done,
          expectedExerciseRunToken: exerciseRunToken,
        );
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _invalidateTicker() {
    _tickerGeneration += 1;
    _ticker?.cancel();
    _ticker = null;
  }

  void _recoverTickerAfterEnvironmentChange() {
    _metricsRecoveryTimer?.cancel();
    _invalidateTicker();
    if (_isTransitioning || _remainingSeconds <= 0 || !mounted) {
      return;
    }

    final exerciseRunToken = _exerciseRunToken;
    _metricsRecoveryTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted || _isTransitioning || _remainingSeconds <= 0) {
        return;
      }
      if (exerciseRunToken != _exerciseRunToken) {
        return;
      }
      _startTicker(exerciseRunToken: exerciseRunToken);
    });
  }

  Future<void> _advance(
    ExerciseStatus status, {
    int? expectedExerciseRunToken,
  }) async {
    if (_isTransitioning) {
      return;
    }
    if (expectedExerciseRunToken != null &&
        expectedExerciseRunToken != _exerciseRunToken) {
      return;
    }
    _isTransitioning = true;
    _invalidateTicker();

    final exercise = _currentExercise;
    widget.appState.logExercise(
      exercise,
      status,
      reminderAt: widget.reminderAt,
    );

    if (status == ExerciseStatus.done) {
      _completedCount += 1;
    } else if (status == ExerciseStatus.skipped) {
      _skippedCount += 1;
    }

    if (status == ExerciseStatus.snoozed) {
      widget.appState.snoozeReminder();
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final isLastExercise = _exerciseIndex == widget.plan.exercises.length - 1;
    if (isLastExercise) {
      widget.appState.rescheduleAfterSession();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('เสร็จสิ้นรอบยืดเส้น'),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const OfficeReliefCompleteState(size: 120),
                  const SizedBox(height: 16),
                  Text(
                    'ทำครบ $_completedCount ท่า'
                    '${_skippedCount > 0 ? ' และข้าม $_skippedCount ท่า' : ''}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                key: AppKeys.sessionFinishClose,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('กลับหน้า Home'),
              ),
            ],
          );
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() {
      _exerciseIndex += 1;
      _isTransitioning = false;
    });
    _beginCurrentExercise();
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.exerciseIndex,
    required this.totalExercises,
    required this.exercise,
    required this.theme,
    required this.headerGap,
  });

  final int exerciseIndex;
  final int totalExercises;
  final Exercise exercise;
  final ThemeData theme;
  final double headerGap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ท่า ${exerciseIndex + 1} / $totalExercises',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: headerGap),
        Text(
          exercise.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(exercise.description, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _SessionActionPanel extends StatelessWidget {
  const _SessionActionPanel({
    required this.compact,
    required this.blockGap,
    required this.actionPadding,
    required this.isTransitioning,
    required this.onSkip,
    required this.onSnooze,
    required this.onComplete,
  });

  final bool compact;
  final double blockGap;
  final double actionPadding;
  final bool isTransitioning;
  final VoidCallback onSkip;
  final VoidCallback onSnooze;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: AppKeys.sessionSkip,
                onPressed: isTransitioning ? null : onSkip,
                icon: const Icon(Icons.fast_forward_outlined),
                label: Padding(
                  padding: EdgeInsets.symmetric(vertical: actionPadding),
                  child: const Text('ข้ามท่านี้'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                key: AppKeys.sessionSnooze,
                onPressed: isTransitioning ? null : onSnooze,
                icon: const Icon(Icons.snooze_outlined),
                label: Padding(
                  padding: EdgeInsets.symmetric(vertical: actionPadding),
                  child: const Text('เลื่อน 10 นาที'),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: blockGap),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: AppKeys.sessionComplete,
            onPressed: isTransitioning ? null : onComplete,
            icon: const Icon(Icons.check_circle_outline),
            label: Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 12 : 14),
              child: const Text('ทำครบและไปท่าถัดไป'),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionCountdownHero extends StatelessWidget {
  const _SessionCountdownHero({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.requiresStanding,
    required this.compact,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final bool requiresStanding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final minutePart = minutes.toString().padLeft(2, '0');
    final secondPart = seconds.toString().padLeft(2, '0');
    final progress = totalSeconds <= 0
        ? 0.0
        : remainingSeconds / totalSeconds;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: const Color(0xFF1A6E46),
                size: compact ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'เวลาของท่านี้',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF18472D),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$totalSeconds วินาที',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF32634A),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 18),
          Text(
            '$minutePart:$secondPart',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF123621),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'อีก $remainingSeconds วินาทีจะเปลี่ยนท่า',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF32634A),
            ),
          ),
          SizedBox(height: compact ? 12 : 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: compact ? 8 : 10,
              backgroundColor: const Color(0xFFDCE8E0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1A6E46),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            requiresStanding ? 'แนะนำให้ลุกขึ้นทำ' : 'ทำได้ขณะนั่ง',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF32634A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseVisualCard extends StatelessWidget {
  const _ExerciseVisualCard({
    super.key,
    required this.entry,
    required this.compact,
  });

  final PlannedExercise entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = entry.exercise;
    final stanceLabel = exercise.requiresStanding ? 'ควรยืนทำ' : 'ทำขณะนั่งได้';
    final imageHeight = compact ? 84.0 : 108.0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exercise.imageAssetPath != null)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12,
                vertical: compact ? 8 : 10,
              ),
              child: SizedBox(
                height: imageHeight,
                child: Image.asset(
                  exercise.imageAssetPath!,
                  fit: BoxFit.contain,
                  semanticLabel: exercise.name,
                ),
              ),
            ),
          if (exercise.imageAssetPath != null)
            SizedBox(height: compact ? 8 : 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.self_improvement_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'โฟกัสของท่านี้',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exercise.reason,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.accessibility_new_outlined,
                label: entry.area.label,
              ),
              _InfoPill(
                icon: Icons.local_fire_department_outlined,
                label: entry.level.label,
              ),
              _InfoPill(
                icon: exercise.requiresStanding
                    ? Icons.stairs_outlined
                    : Icons.event_seat_outlined,
                label: stanceLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
