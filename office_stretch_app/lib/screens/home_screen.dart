import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../app/app_state.dart';
import '../models/app_models.dart';
import '../widgets/office_relief_brand_mark.dart';
import '../widgets/office_relief_missed_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.appState,
    required this.onStartPlan,
    required this.onEditPlan,
  });

  final AppState appState;
  final ValueChanged<ExercisePlan> onStartPlan;
  final VoidCallback onEditPlan;

  @override
  Widget build(BuildContext context) {
    final plan = appState.activePlan;
    final profile = appState.profile;
    final theme = Theme.of(context);

    if (plan == null || profile == null) {
      return const SizedBox.shrink();
    }

    final totalMinutes =
        (plan.exercises.fold<int>(
                  0,
                  (sum, exercise) => sum + exercise.exercise.durationSeconds,
                ) /
                60)
            .ceil();
    final nextReminderText = TimeOfDay.fromDateTime(
      appState.nextReminderAt,
    ).format(context);

    return SafeArea(
      child: ListView(
        key: AppKeys.homeScreen,
        padding: const EdgeInsets.all(20),
        children: [
          const OfficeReliefBrandMark(size: 70, showWordmark: true),
          const SizedBox(height: 18),
          if (appState.hasMissedRemindersToday) ...[
            Card(
              key: AppKeys.homeMissedReminderCard,
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'มีรอบที่พลาดวันนี้',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'วันนี้พลาดการแจ้งเตือน ${appState.missedRemindersToday} รอบ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const OfficeReliefMissedState(size: 88),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE9F7FF),
                    Color(0xFFD8F8FF),
                    Color(0xFFF4FFD4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: onEditPlan,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'แผนหลักของวันนี้',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            key: AppKeys.homeEditMainPlan,
                            onPressed: onEditPlan,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('แก้ไข'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${plan.groups.length} กลุ่ม รวม ${plan.exerciseCount} ท่า',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(plan.subtitle, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatChip(
                            icon: Icons.schedule,
                            label:
                                'เตือนทุก ${appState.settings.intervalMinutes} นาที',
                          ),
                          _StatChip(
                            icon: Icons.timer_outlined,
                            label: '$totalMinutes นาทีต่อรอบ',
                          ),
                          _StatChip(
                            icon: Icons.notifications_active_outlined,
                            label: 'รอบถัดไป $nextReminderText',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              key: AppKeys.homeStartProgram,
                              onPressed: () => onStartPlan(plan),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('เริ่มรอบยืดเส้น'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            key: AppKeys.homeSnoozeReminder,
                            onPressed: () => appState.snoozeReminder(),
                            icon: const Icon(Icons.snooze_outlined),
                            label: const Text('เลื่อน'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สรุปแผนที่เลือก',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...plan.groups.map((group) {
                    final exerciseCount = plan.exercises
                        .where((exercise) => exercise.area == group.area)
                        .length;
                    return _KeyValueRow(
                      label: group.area.label,
                      value: '${group.level.label} • $exerciseCount ท่า',
                    );
                  }),
                  _KeyValueRow(
                    label: 'ใช้คอมต่อวัน',
                    value: profile.workHours.label,
                  ),
                  _KeyValueRow(
                    label: 'นิสัยการยืดเส้น',
                    value: profile.stretchHabit.label,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ท่าที่อยู่ในแผนนี้',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...plan.groups.map((group) {
                    final exercises = plan.exercises
                        .where((entry) => entry.area == group.area)
                        .toList(growable: false);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${group.area.label} • ${group.level.label}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...exercises.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '• ${entry.exercise.name} (${entry.exercise.durationSeconds} วินาที)',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'กิจกรรมล่าสุด',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (appState.logs.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const OfficeReliefMissedState(size: 168),
                          const SizedBox(height: 12),
                          Text(
                            'ยังไม่มีประวัติการทำท่า เริ่มรอบแรกจากปุ่มด้านบนได้เลย',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...appState.logs.take(5).map((log) {
                      final time = TimeOfDay.fromDateTime(
                        log.occurredAt,
                      ).format(context);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(log.exerciseName),
                        subtitle: Text('$time • ${log.status.label}'),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.92),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
