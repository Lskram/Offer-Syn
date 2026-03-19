import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../models/app_models.dart';
import '../widgets/office_relief_brand_mark.dart';
import '../widgets/office_relief_mascot.dart';

enum AlarmScreenAction { start, snooze, dismiss }

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({
    super.key,
    required this.launch,
  });

  final PendingReminderLaunch launch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reminderLabel = _formatReminderLabel(context, launch.reminderAt);

    return PopScope<void>(
      canPop: false,
      child: Scaffold(
        key: AppKeys.alarmScreen,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.topLeft,
                            child: OfficeReliefBrandMark(
                              size: 62,
                              showWordmark: false,
                            ),
                          ),
                          const Spacer(),
                          const Center(
                            child: OfficeReliefMascot(size: 192),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            launch.isTest
                                ? 'Alarm test'
                                : 'ถึงเวลาพักและยืดเส้น',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            launch.plan.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$reminderLabel • ${launch.plan.exerciseCount} ท่า',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            launch.plan.subtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.84),
                            ),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            key: AppKeys.alarmStart,
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(AlarmScreenAction.start),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text('เริ่มทำท่าเลย'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: AppKeys.alarmSnooze,
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(AlarmScreenAction.snooze),
                            icon: const Icon(Icons.snooze_outlined),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('เลื่อน 10 นาที'),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            key: AppKeys.alarmDismiss,
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(AlarmScreenAction.dismiss),
                            child: Text(
                              'ปิดรอบนี้',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
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

  String _formatReminderLabel(BuildContext context, DateTime? reminderAt) {
    if (reminderAt == null) {
      return 'รอบเตือนล่าสุด';
    }

    final time = TimeOfDay.fromDateTime(reminderAt).format(context);
    return 'รอบเวลา $time';
  }
}
