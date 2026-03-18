import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../app/app_state.dart';
import '../models/reminder_diagnostics.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final settings = appState.settings;
    final theme = Theme.of(context);
    final diagnostics = appState.reminderDiagnostics;
    final hasCustomSound =
        settings.notificationSoundUri != null &&
        settings.notificationSoundUri!.isNotEmpty;
    final soundLabel = hasCustomSound
        ? settings.notificationSoundLabel ?? 'เสียงระบบที่เลือก'
        : 'เสียงเริ่มต้นของระบบ';
    final canEditAlertStyle = settings.notificationsEnabled;

    return SafeArea(
      child: ListView(
        key: AppKeys.settingsScreen,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _ReminderReadinessCard(appState: appState, diagnostics: diagnostics),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder schedule',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diagnostics.usesExactScheduling
                        ? 'ตอนนี้เครื่องนี้ใช้ exactAllowWhileIdle แล้ว เวลาจะตรงกว่าปกติ แต่ยังขึ้นกับ battery policy และเสียงของระบบ'
                        : 'ตอนนี้ยังใช้ inexactAllowWhileIdle อยู่ เวลาการแจ้งเตือนอาจดีเลย์ได้ โดยเฉพาะตอนจอดำหรือเครื่องประหยัดแบต',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    key: AppKeys.settingsNotificationsEnabled,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('เปิดการแจ้งเตือน'),
                    value: settings.notificationsEnabled,
                    onChanged: appState.updateNotificationsEnabled,
                  ),
                  SwitchListTile(
                    key: AppKeys.settingsSoundEnabled,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('เปิดเสียงแจ้งเตือน'),
                    value: settings.soundEnabled,
                    onChanged: canEditAlertStyle
                        ? appState.updateSoundEnabled
                        : null,
                  ),
                  SwitchListTile(
                    key: AppKeys.settingsVibrationEnabled,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('สั่นเมื่อแจ้งเตือน'),
                    value: settings.vibrationEnabled,
                    onChanged: canEditAlertStyle
                        ? appState.updateVibrationEnabled
                        : null,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.music_note_outlined),
                    title: const Text('เสียงแจ้งเตือน'),
                    subtitle: Text(
                      settings.soundEnabled
                          ? soundLabel
                          : 'ปิดเสียงแจ้งเตือนอยู่',
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        key: AppKeys.settingsPickSound,
                        onPressed: canEditAlertStyle && diagnostics.isAndroid
                            ? appState.pickNotificationSound
                            : null,
                        icon: const Icon(Icons.library_music_outlined),
                        label: const Text('เลือกเสียงระบบ'),
                      ),
                      TextButton.icon(
                        key: AppKeys.settingsResetSound,
                        onPressed: canEditAlertStyle && hasCustomSound
                            ? appState.useDefaultNotificationSound
                            : null,
                        icon: const Icon(Icons.restart_alt_outlined),
                        label: const Text('ใช้เสียงเริ่มต้น'),
                      ),
                    ],
                  ),
                  if (!diagnostics.isAndroid) ...[
                    const SizedBox(height: 8),
                    Text(
                      'การเลือกเสียงจากระบบรองรับเฉพาะ Android',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: AppKeys.settingsIntervalMinutes,
                    initialValue: settings.intervalMinutes,
                    decoration: const InputDecoration(
                      labelText: 'รอบแจ้งเตือนเริ่มต้น',
                    ),
                    items: const [1, 30, 45, 60, 90, 120]
                        .map(
                          (minutes) => DropdownMenuItem<int>(
                            value: minutes,
                            child: Text(
                              minutes == 1
                                  ? 'ทุก 1 นาที (สำหรับทดสอบ)'
                                  : 'ทุก $minutes นาที',
                              key: AppKeys.settingsIntervalOption(minutes),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        appState.updateInterval(value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('เริ่มแจ้งเตือนตั้งแต่'),
                    subtitle: Text(settings.activeStart.format(context)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickTime(
                      context,
                      settings.activeStart,
                      (value) => appState.updateActiveWindow(start: value),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.nightlight_outlined),
                    title: const Text('หยุดแจ้งเตือนเวลา'),
                    subtitle: Text(settings.activeEnd.format(context)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickTime(
                      context,
                      settings.activeEnd,
                      (value) => appState.updateActiveWindow(end: value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!appState.hasValidReminderWindow) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'ช่วงเวลาแจ้งเตือนไม่ถูกต้อง เวลาเริ่มและเวลาหยุดต้องไม่ตรงกัน เช่น 08:00 ถึง 16:30 หรือ 18:00 ถึง 02:00',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device checklist',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _BulletRow(
                    text:
                        'ทดสอบบนเครื่องจริงอย่างน้อย 1 เครื่องก่อนใช้งานจริง โดยเฉพาะ Samsung, Xiaomi, Oppo, Vivo หรือ Huawei',
                  ),
                  const _BulletRow(
                    text:
                        'ถ้าต้องการเตือนสม่ำเสมอ ให้ตั้ง Battery ของแอปเป็น Unrestricted และปิด vendor battery saver เพิ่มเติมถ้ามี',
                  ),
                  const _BulletRow(
                    text:
                        'ถ้าเปิด Do Not Disturb หรือปิด notification ของแอปเอง ระบบจะแสดงเตือนไม่ครบตามปกติ',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan reset',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ถ้าอาการเปลี่ยนหรืออยากประเมินใหม่ สามารถทำแบบสอบถามใหม่ได้ ระบบจะล้างแผนและประวัติชุดเดิม',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: AppKeys.settingsRestartOnboarding,
                    onPressed: appState.restartOnboarding,
                    icon: const Icon(Icons.replay_outlined),
                    label: const Text('ทำแบบสอบถามใหม่'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initialValue,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialValue,
    );
    if (picked != null) {
      onPicked(picked);
    }
  }
}

class _ReminderReadinessCard extends StatelessWidget {
  const _ReminderReadinessCard({
    required this.appState,
    required this.diagnostics,
  });

  final AppState appState;
  final ReminderDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: diagnostics.needsAttention
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reminder readiness',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: diagnostics.needsAttention
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              diagnostics.isAndroid
                  ? 'Android สามารถแจ้งเตือนขณะจอดำหรือกำลังใช้แอปอื่นได้ แต่ความตรงเวลาจะขึ้นกับ exact alarm, battery optimization และนโยบายของเครื่อง'
                  : 'เครื่องนี้ไม่ได้ใช้ Android local notification flow แบบเดียวกับแอปเป้าหมาย จึงวินิจฉัยเรื่อง exact alarm และ battery optimization จากหน้านี้ไม่ได้',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: diagnostics.needsAttention
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            _StatusRow(
              label: 'Notification permission',
              value: switch (diagnostics.notificationsEnabled) {
                true => 'พร้อม',
                false => 'ต้องอนุญาต',
                null => 'ตรวจไม่ได้',
              },
            ),
            _StatusRow(
              label: 'Battery optimization',
              value: diagnostics.isAndroid
                  ? switch (diagnostics.ignoresBatteryOptimizations) {
                      true => 'Unrestricted',
                      false => 'อาจหน่วงการเตือน',
                      null => 'ตรวจไม่ได้',
                    }
                  : 'ไม่เกี่ยวข้อง',
            ),
            _StatusRow(
              label: 'Exact alarm',
              value: diagnostics.isAndroid
                  ? switch (diagnostics.exactAlarmsEnabled) {
                      true => 'พร้อม',
                      false => 'ยังไม่เปิด',
                      null => 'ตรวจไม่ได้',
                    }
                  : 'ไม่เกี่ยวข้อง',
            ),
            _StatusRow(
              label: 'Schedule mode',
              value: diagnostics.scheduleModeLabel,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (diagnostics.supportsPermissionPrompt)
                  FilledButton.icon(
                    onPressed: appState.requestNotificationPermission,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('ขอสิทธิ์แจ้งเตือน'),
                  ),
                if (diagnostics.supportsExactAlarmPermissionPrompt)
                  OutlinedButton.icon(
                    key: AppKeys.settingsRequestExactAlarm,
                    onPressed: appState.requestExactAlarmPermission,
                    icon: const Icon(Icons.alarm_on_outlined),
                    label: const Text('เปิด exact alarm'),
                  ),
                if (diagnostics.supportsNotificationSettings)
                  OutlinedButton.icon(
                    onPressed: appState.openNotificationSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('เปิดตั้งค่าการแจ้งเตือน'),
                  ),
                if (diagnostics.supportsBatteryOptimizationSettings)
                  OutlinedButton.icon(
                    onPressed: appState.openBatteryOptimizationSettings,
                    icon: const Icon(Icons.battery_saver_outlined),
                    label: const Text('เปิดตั้งค่า Battery'),
                  ),
                TextButton.icon(
                  onPressed: appState.refreshReminderDiagnostics,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('รีเฟรชสถานะ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

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
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('- '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
