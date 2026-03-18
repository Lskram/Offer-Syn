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
    required this.onStartProgram,
  });

  final AppState appState;
  final ValueChanged<ExerciseProgram> onStartProgram;

  @override
  Widget build(BuildContext context) {
    final program = appState.activeProgram;
    final profile = appState.profile;
    final theme = Theme.of(context);

    if (program == null || profile == null) {
      return const SizedBox.shrink();
    }

    final totalMinutes =
        (program.exercises.fold<int>(
                  0,
                  (sum, exercise) => sum + exercise.durationSeconds,
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
          if (appState.reminderDiagnostics.needsAttention) ...[
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder needs attention',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appState.reminderDiagnostics.notificationsEnabled == false
                          ? 'ตอนนี้เครื่องยังไม่อนุญาต notification หรือถูกปิดไว้ การเตือนจะยังไม่ขึ้นจนกว่าจะเปิดใหม่'
                          : 'เครื่องนี้ยังอยู่ภายใต้ battery optimization การเตือนตอนจอดำอาจมาช้ากว่าที่ตั้งไว้',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
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
                            'วันนี้พลาดการแจ้งเตือน ${appState.missedRemindersToday} รอบ ระบบบันทึกไว้ในประวัติรายวันแล้ว',
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
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'แผนวันนี้ของคุณ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  program.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(program.subtitle, style: theme.textTheme.bodyLarge),
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
                      icon: appState.settings.notificationsEnabled
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      label: appState.settings.notificationsEnabled
                          ? 'รอบถัดไป $nextReminderText'
                          : 'ปิดการแจ้งเตือนอยู่',
                    ),
                    _StatChip(
                      icon: switch (appState.settings.vibrationLevel) {
                        VibrationLevel.light => Icons.vibration_outlined,
                        VibrationLevel.medium => Icons.vibration_rounded,
                        VibrationLevel.strong => Icons.priority_high_rounded,
                      },
                      label:
                          'สั่น${appState.settings.vibrationEnabled ? appState.settings.vibrationLevel.label : "ปิด"}',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: AppKeys.homeStartProgram,
                        onPressed: () => onStartProgram(program),
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
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สรุปจากแบบสอบถาม',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _KeyValueRow(
                    label: 'บริเวณหลัก',
                    value: profile.painArea.label,
                  ),
                  _KeyValueRow(
                    label: 'ระดับอาการ',
                    value: profile.painLevel.label,
                  ),
                  _KeyValueRow(
                    label: 'ใช้คอมต่อวัน',
                    value: profile.workHours.label,
                  ),
                  _KeyValueRow(
                    label: 'นิสัยยืดเส้น',
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
                    'แผนท่าวันนี้',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...program.exercises.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final exercise = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            child: Text('$index'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(exercise.description),
                                const SizedBox(height: 4),
                                Text(
                                  'เวลา ${exercise.durationSeconds} วินาที'
                                  '${exercise.requiresStanding ? ' และแนะนำให้ลุกขึ้นทำ' : ''}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
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
                        leading: Icon(switch (log.status) {
                          ExerciseStatus.done => Icons.check_circle_outline,
                          ExerciseStatus.skipped => Icons.fast_forward_outlined,
                          ExerciseStatus.snoozed => Icons.snooze_outlined,
                          ExerciseStatus.missed =>
                            Icons.notification_important_outlined,
                        }),
                        title: Text(log.exerciseName),
                        subtitle: Text('$time - ${log.status.label}'),
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
              child: Text(
                'คำเตือนด้านสุขภาพ: โปรแกรมนี้ใช้เพื่อดูแลตนเองเบื้องต้น หากมีอาการปวดรุนแรง ชา ร้าว หรือเวียนหัว ควรหยุดทันทีและขอคำแนะนำจากผู้เชี่ยวชาญ',
                style: theme.textTheme.bodyMedium,
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
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
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
