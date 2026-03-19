import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../app/app_state.dart';
import '../models/app_models.dart';
import '../widgets/office_relief_brand_mark.dart';
import '../widgets/office_relief_mascot.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = appState.logs;
    final groupedLogs = _groupLogsByDay(logs);
    final today = DateUtils.dateOnly(appState.currentTime);
    final todayLogs = logs
        .where((log) => DateUtils.isSameDay(log.occurredAt, today))
        .toList(growable: false);

    return SafeArea(
      child: ListView(
        key: AppKeys.historyScreen,
        padding: const EdgeInsets.all(20),
        children: [
          const OfficeReliefBrandMark(size: 74, showWordmark: true),
          const SizedBox(height: 18),
          Text(
            'History',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ดูประวัติการทำท่า การเลื่อน การข้าม และรอบที่พลาดย้อนหลังได้จากหน้านี้',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          if (logs.isEmpty)
            _EmptyHistoryCard(theme: theme)
          else ...[
            _HistorySummaryCard(
              theme: theme,
              totalLogs: logs.length,
              completedCount: _countStatus(logs, ExerciseStatus.done),
              missedCount: _countStatus(logs, ExerciseStatus.missed),
              snoozedCount: _countStatus(logs, ExerciseStatus.snoozed),
              skippedCount: _countStatus(logs, ExerciseStatus.skipped),
              todayLogs: todayLogs,
            ),
            const SizedBox(height: 18),
            ...groupedLogs.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _HistoryDayCard(
                  date: entry.key,
                  logs: entry.value,
                  isToday: DateUtils.isSameDay(entry.key, today),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<DateTime, List<ExerciseLog>> _groupLogsByDay(List<ExerciseLog> logs) {
    final grouped = <DateTime, List<ExerciseLog>>{};
    for (final log in logs) {
      final day = DateUtils.dateOnly(log.occurredAt);
      grouped.putIfAbsent(day, () => <ExerciseLog>[]).add(log);
    }
    return grouped;
  }

  int _countStatus(List<ExerciseLog> logs, ExerciseStatus status) {
    return logs.where((log) => log.status == status).length;
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const OfficeReliefMascot(size: 148),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีประวัติการทำท่า',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'เริ่มรอบแรกจากหน้า Home หรือปล่อยให้ระบบเตือน แล้วประวัติจะถูกบันทึกไว้ที่นี่',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({
    required this.theme,
    required this.totalLogs,
    required this.completedCount,
    required this.missedCount,
    required this.snoozedCount,
    required this.skippedCount,
    required this.todayLogs,
  });

  final ThemeData theme;
  final int totalLogs;
  final int completedCount;
  final int missedCount;
  final int snoozedCount;
  final int skippedCount;
  final List<ExerciseLog> todayLogs;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สรุปการใช้งาน',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'วันนี้มี ${todayLogs.length} รายการ และมีประวัติสะสมทั้งหมด $totalLogs รายการ',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryPill(
                  label: 'ทำครบ',
                  value: completedCount,
                  color: const Color(0xFF1F8A4D),
                ),
                _SummaryPill(
                  label: 'พลาด',
                  value: missedCount,
                  color: const Color(0xFFC96A00),
                ),
                _SummaryPill(
                  label: 'เลื่อน',
                  value: snoozedCount,
                  color: const Color(0xFF0A67D9),
                ),
                _SummaryPill(
                  label: 'ข้าม',
                  value: skippedCount,
                  color: const Color(0xFF7C5D00),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryDayCard extends StatelessWidget {
  const _HistoryDayCard({
    required this.date,
    required this.logs,
    required this.isToday,
  });

  final DateTime date;
  final List<ExerciseLog> logs;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isToday ? 'วันนี้' : _formatDate(date),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text('${logs.length} รายการ', style: theme.textTheme.bodySmall),
            const SizedBox(height: 14),
            ...logs.map((log) => _HistoryLogTile(log: log)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }
}

class _HistoryLogTile extends StatelessWidget {
  const _HistoryLogTile({required this.log});

  final ExerciseLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = _formatTime(log.occurredAt);
    final reminderLabel = log.reminderAt == null
        ? null
        : 'รอบเตือน ${_formatTime(log.reminderAt!)}';
    final visual = _statusVisual(log.status, theme);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: visual.background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: visual.foreground.withValues(alpha: 0.15),
            foregroundColor: visual.foreground,
            child: Icon(visual.icon),
          ),
          title: Text(
            log.exerciseName,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            reminderLabel == null
                ? '$timeLabel • ${log.status.label}'
                : '$timeLabel • ${log.status.label} • $reminderLabel',
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  _HistoryVisual _statusVisual(ExerciseStatus status, ThemeData theme) {
    return switch (status) {
      ExerciseStatus.done => _HistoryVisual(
        icon: Icons.check_circle_outline,
        foreground: const Color(0xFF1F8A4D),
        background: const Color(0xFFE8F7EE),
      ),
      ExerciseStatus.missed => _HistoryVisual(
        icon: Icons.error_outline,
        foreground: const Color(0xFFC96A00),
        background: const Color(0xFFFFF1DF),
      ),
      ExerciseStatus.snoozed => _HistoryVisual(
        icon: Icons.snooze_outlined,
        foreground: const Color(0xFF0A67D9),
        background: const Color(0xFFE8F1FF),
      ),
      ExerciseStatus.skipped => _HistoryVisual(
        icon: Icons.fast_forward_outlined,
        foreground: const Color(0xFF7C5D00),
        background: const Color(0xFFFFF7DA),
      ),
    };
  }
}

class _HistoryVisual {
  const _HistoryVisual({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
}
