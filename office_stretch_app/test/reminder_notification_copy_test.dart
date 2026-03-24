import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/models/app_models.dart';
import 'package:office_stretch_app/services/reminder_scheduler.dart';

void main() {
  const plan = ExercisePlan(
    id: 'plan-1',
    title: 'โปรแกรมคอ บ่า ไหล่',
    subtitle: 'คลายตึงระหว่างวัน',
    groups: <PainSelection>[],
    exercises: <PlannedExercise>[],
    reminderIntervalMinutes: 60,
  );

  test('builds readable reminder notification copy', () {
    expect(ReminderNotificationCopy.reminderTitle, 'ถึงเวลาพักยืดเส้น');
    expect(
      ReminderNotificationCopy.reminderBody(
        plan: plan,
        settings: defaultReminderSettings,
      ),
      'โปรแกรมคอ บ่า ไหล่ • 0 ท่า • รอบละ 60 นาที',
    );
  });

  test('builds readable test notification copy', () {
    expect(
      ReminderNotificationCopy.testBody(plan: null),
      'หากเห็นข้อความนี้ แปลว่าระบบแจ้งเตือนของแอปทำงานแล้ว',
    );
    expect(
      ReminderNotificationCopy.testBody(plan: plan),
      'หากเห็นข้อความนี้ แปลว่าระบบแจ้งเตือนพร้อมสำหรับโปรแกรม โปรแกรมคอ บ่า ไหล่',
    );
  });
}
