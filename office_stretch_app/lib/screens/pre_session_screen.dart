import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../models/app_models.dart';
import '../widgets/office_relief_brand_mark.dart';

enum PreSessionScreenAction { startNow, cancel }

class PreSessionScreen extends StatefulWidget {
  const PreSessionScreen({
    super.key,
    required this.plan,
    required this.countdownSeconds,
  });

  final ExercisePlan plan;
  final int countdownSeconds;

  @override
  State<PreSessionScreen> createState() => _PreSessionScreenState();
}

class _PreSessionScreenState extends State<PreSessionScreen> {
  Timer? _ticker;
  late int _remainingSeconds;
  bool _isFinishing = false;

  PlannedExercise get _firstEntry => widget.plan.exercises.first;
  Exercise get _firstExercise => _firstEntry.exercise;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;
    if (_remainingSeconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finish(PreSessionScreenAction.startNow);
      });
      return;
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        _finish(PreSessionScreenAction.startNow);
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = _firstExercise;
    final countdownText = _remainingSeconds.toString().padLeft(2, '0');

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (_, result) {
        if (!_isFinishing) {
          _finish(PreSessionScreenAction.cancel);
        }
      },
      child: Scaffold(
        key: AppKeys.preSessionScreen,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Color(0xFF062348),
                Color(0xFF0A67D9),
                Color(0xFF22C7E2),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Align(
                            alignment: Alignment.topLeft,
                            child: OfficeReliefBrandMark(
                              size: 62,
                              showWordmark: false,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    'เตรียมตัวเริ่มท่าแรก',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.plan.title,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.92),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    exercise.name,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    exercise.reason,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    height: 156,
                                    width: 156,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.24),
                                        width: 2,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          countdownText,
                                          style: theme.textTheme.displayLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'วินาทีก่อนเริ่ม',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.92,
                                                ),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    exercise.requiresStanding
                                        ? 'แนะนำให้ลุกขึ้นและจัดท่าให้พร้อมก่อนเริ่ม'
                                        : 'อ่านท่าก่อนเริ่มได้ และกดเริ่มทันทีเมื่อพร้อม',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            key: AppKeys.preSessionStartNow,
                            onPressed: () => _finish(PreSessionScreenAction.startNow),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text('เริ่มเลย'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            key: AppKeys.preSessionCancel,
                            onPressed: () => _finish(PreSessionScreenAction.cancel),
                            child: Text(
                              'ยกเลิก',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _finish(PreSessionScreenAction action) {
    if (_isFinishing || !mounted) {
      return;
    }

    _isFinishing = true;
    _ticker?.cancel();
    Navigator.of(context).pop(action);
  }
}
