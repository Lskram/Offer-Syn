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
    final progress =
        1 - (_remainingSeconds / exercise.durationSeconds.clamp(1, 3600));
    final theme = Theme.of(context);

    return Scaffold(
      key: AppKeys.sessionScreen,
      appBar: AppBar(title: Text(widget.plan.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ท่า ${_exerciseIndex + 1} / ${widget.plan.exercises.length}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(exercise.description, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 10),
              Text(
                '${entry.area.label} | ${entry.level.label}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'เหตุผล: ${exercise.reason}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final dialSize = constraints.maxHeight < 280
                            ? 132.0
                            : constraints.maxHeight < 340
                            ? 152.0
                            : 180.0;

                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: dialSize,
                                  width: dialSize,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: progress.clamp(0, 1),
                                        strokeWidth: 12,
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatSeconds(_remainingSeconds),
                                            style: theme.textTheme.displaySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            exercise.requiresStanding
                                                ? 'แนะนำให้ลุกขึ้นทำ'
                                                : 'ทำได้ขณะนั่ง',
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                LinearProgressIndicator(
                                  value: progress.clamp(0, 1),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'เมื่อครบเวลา ระบบจะเลื่อนไปท่าถัดไปให้อัตโนมัติ',
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: AppKeys.sessionSkip,
                      onPressed: _isTransitioning
                          ? null
                          : () => _advance(ExerciseStatus.skipped),
                      icon: const Icon(Icons.fast_forward_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('ข้ามท่านี้'),
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
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('เลื่อน 10 นาที'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: AppKeys.sessionComplete,
                  onPressed: _isTransitioning
                      ? null
                      : () => _advance(ExerciseStatus.done),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('ทำครบและไปท่าถัดไป'),
                  ),
                ),
              ),
            ],
          ),
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

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutePart = minutes.toString().padLeft(2, '0');
    final secondPart = seconds.toString().padLeft(2, '0');
    return '$minutePart:$secondPart';
  }
}
