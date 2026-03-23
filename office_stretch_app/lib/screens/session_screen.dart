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

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  Timer? _ticker;
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
    _beginCurrentExercise();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
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
            final compactLayout = constraints.maxHeight < 580;
            final bodyPadding = compactLayout ? 16.0 : 20.0;
            final headerGap = compactLayout ? 6.0 : 8.0;
            final blockGap = compactLayout ? 10.0 : 12.0;
            final actionPadding = compactLayout ? 10.0 : 12.0;

            return Padding(
              padding: EdgeInsets.all(bodyPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ท่า ${_exerciseIndex + 1} / ${widget.plan.exercises.length}',
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
                  SizedBox(height: blockGap),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _ExerciseVisualCard(
                      key: ValueKey<String>(exercise.id),
                      entry: entry,
                      compact: compactLayout,
                    ),
                  ),
                  SizedBox(height: blockGap),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(compactLayout ? 20 : 24),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _SessionCountdownHero(
                                      remainingSeconds: _remainingSeconds,
                                      totalSeconds: exercise.durationSeconds,
                                      requiresStanding:
                                          exercise.requiresStanding,
                                      compact: compactLayout,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compactLayout ? 16 : 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: AppKeys.sessionSkip,
                          onPressed: _isTransitioning
                              ? null
                              : () => _advance(ExerciseStatus.skipped),
                          icon: const Icon(Icons.fast_forward_outlined),
                          label: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: actionPadding,
                            ),
                            child: const Text('ข้ามท่านี้'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: AppKeys.sessionSnooze,
                          onPressed: _isTransitioning
                              ? null
                              : () => _advance(ExerciseStatus.snoozed),
                          icon: const Icon(Icons.snooze_outlined),
                          label: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: actionPadding,
                            ),
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
                      onPressed: _isTransitioning
                          ? null
                          : () => _advance(ExerciseStatus.done),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: compactLayout ? 12 : 14,
                        ),
                        child: const Text('ทำครบและไปท่าถัดไป'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _beginCurrentExercise() {
    _ticker?.cancel();
    setState(() {
      _remainingSeconds = _currentExercise.durationSeconds;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _advance(ExerciseStatus.done);
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  Future<void> _advance(ExerciseStatus status) async {
    if (_isTransitioning) {
      return;
    }
    _isTransitioning = true;
    _ticker?.cancel();

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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OfficeReliefCompleteState(size: 148),
                const SizedBox(height: 16),
                Text(
                  'ทำครบ $_completedCount ท่า'
                  '${_skippedCount > 0 ? ' และข้าม $_skippedCount ท่า' : ''}',
                  textAlign: TextAlign.center,
                ),
              ],
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                color: const Color(0xFF1A6E46),
                size: compact ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'เวลาของท่านี้',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF18472D),
                ),
              ),
              const Spacer(),
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
            requiresStanding ? 'แนะนำให้ลุกขึ้นทำ' : 'ทำได้ขณะนั่ง',
            textAlign: TextAlign.center,
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
          if (exercise.imageAssetPath != null) SizedBox(height: compact ? 8 : 10),
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
