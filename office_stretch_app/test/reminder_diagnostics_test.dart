import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/models/reminder_diagnostics.dart';

void main() {
  test('delivery drift labels on-time and delayed samples clearly', () {
    final onTime = ReminderDeliveryDrift(
      notificationId: 1000,
      scheduledAt: DateTime(2026, 3, 29, 19, 0, 0),
      postedAt: DateTime(2026, 3, 29, 19, 0, 0),
    );
    final delayed = ReminderDeliveryDrift(
      notificationId: 1001,
      scheduledAt: DateTime(2026, 3, 29, 19, 0, 0),
      postedAt: DateTime(2026, 3, 29, 19, 0, 14),
    );

    expect(onTime.delayLabel, 'On time');
    expect(delayed.delayLabel, 'late 14s');
    expect(delayed.isNoticeablyDelayed, isTrue);
    expect(delayed.isSeverelyDelayed, isFalse);
  });

  test('diagnostics attention includes noticeable delivery drift', () {
    final diagnostics = ReminderDiagnostics.android(
      notificationsEnabled: true,
      ignoresBatteryOptimizations: true,
      exactAlarmsEnabled: true,
      fullScreenIntentEnabled: true,
      lastObservedReminderDelivery: ReminderDeliveryDrift(
        notificationId: 1000,
        scheduledAt: DateTime(2026, 3, 29, 19, 0, 0),
        postedAt: DateTime(2026, 3, 29, 19, 0, 30),
      ),
    );

    expect(diagnostics.hasDeliverySample, isTrue);
    expect(diagnostics.needsDeliveryAttention, isTrue);
    expect(diagnostics.needsAttention, isTrue);
  });
}
