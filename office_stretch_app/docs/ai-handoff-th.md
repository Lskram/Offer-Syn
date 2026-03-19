# OfficeRelief AI Handoff

อัปเดตล่าสุด: 2026-03-19  
Git HEAD ตอนเขียนเอกสาร: `bdfe5de`  
โปรเจ็กต์: `C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app`

## 1. เป้าหมายของเอกสาร

เอกสารนี้มีไว้ส่งต่อบริบทให้ AI หรือผู้พัฒนาคนถัดไป โดยต้องการให้:

- เข้าใจสถานะโปรเจ็กต์จากโค้ดจริง ไม่อิงแค่บทสนทนา
- รู้ business rules ปัจจุบันของแอป
- รู้โครงสร้าง reminder, alarm, notification, diagnostics, และ test harness
- รู้สิ่งที่ทำแล้ว สิ่งที่ยังไม่ทำ และสิ่งที่ไม่ควรถอยกลับ
- รู้วิธี build และทดสอบซ้ำบน emulator และมือถือจริง

## 2. ภาพรวมโปรเจ็กต์

ชื่อแอปปัจจุบันคือ `OfficeRelief`

แนวคิดของแอป:

- แอปช่วยเตือนให้คนทำงานหน้าคอมพักและยืดเส้น
- ใช้แบบสอบถามเพื่อสร้าง `main plan`
- เป็นแอป `local-first`
- ไม่มี login
- ไม่มี backend
- เน้น Android เป็นหลัก

สถานะปัจจุบัน:

- มี onboarding / questionnaire
- มี `multi-group main plan`
- มีหน้าแก้ `main plan`
- มี exercise session พร้อม timer
- มี local persistence
- มี local notifications
- มี `alert mode` 3 แบบ
- มี `Alarm screen`
- มี reminder diagnostics
- มี device verification scripts สำหรับ notification และ alarm

## 3. ขอบเขตฟีเจอร์ปัจจุบัน

### 3.1 สิ่งที่มีแล้ว

- เลือกกลุ่มปวดได้มากกว่า 1 กลุ่ม
- แต่ละกลุ่มเลือกระดับความปวดของตัวเองได้
- แต่ละกลุ่มเลือกท่าได้สูงสุด 2 ท่า
- แก้ `main plan` ได้จากในแอป
- แก้เวลาเตือน, active window, และ reminder interval ได้
- เปิด/ปิดเสียงได้
- เปิด/ปิดการสั่นได้
- เลือกระดับการสั่นได้ 3 ระดับ
- มีโหมดแจ้งเตือน:
  - `notification`
  - `exact`
  - `exactFullScreen`
- มี `Alarm screen` พร้อม action:
  - `เริ่มทำท่า`
  - `เลื่อน 10 นาที`
  - `ปิดรอบนี้`
- มี history/log ระดับ status:
  - `done`
  - `skipped`
  - `snoozed`
  - `missed`
- มี diagnostics ของ reminder และ sync state

### 3.2 สิ่งที่ยังไม่มี

- backend / cloud sync
- login / register
- package name สำหรับ production
- release signing flow แบบพร้อมปล่อยจริง
- กลุ่มท่า `ข้อมือ`
- กลุ่มท่า `ตา`
- history screen แบบหน้าเฉพาะที่สมบูรณ์
- native `AlarmActivity` แยกจาก `MainActivity`

## 4. Business rules ที่ต้องถือเป็นหลัก

### 4.1 กลุ่มปวด

มีกลุ่มปวดทั้งหมด 3 กลุ่ม:

- `PainArea.neckShoulders`
- `PainArea.upperBack`
- `PainArea.lowerBack`

### 4.2 ระดับความปวด

แต่ละกลุ่มมี 3 ระดับ:

- `PainLevel.high`
- `PainLevel.medium`
- `PainLevel.low`

### 4.3 กติกาการเลือกท่า

- ผู้ใช้เลือกกลุ่มปวดได้ `1-3 กลุ่ม`
- แต่ละกลุ่มมี collection ของท่าตาม `area + level`
- แต่ละกลุ่มเลือกท่าได้สูงสุด `2 ท่า`
- ถ้า collection มี `1 ท่า` ให้ใช้ `1`
- ถ้า collection มี `2 ท่า` ให้ใช้ `2`
- ถ้า collection มีมากกว่า `2 ท่า` ให้ active จริงได้ไม่เกิน `2` และสลับเลือกได้

### 4.4 จำนวนท่ารวมของแผน

- เลือก `1 กลุ่ม` ได้ท่ารวมสูงสุด `2`
- เลือก `2 กลุ่ม` ได้ท่ารวมสูงสุด `4`
- เลือก `3 กลุ่ม` ได้ท่ารวมสูงสุด `6`

จำนวนจริงอาจน้อยกว่านี้ได้ ถ้าบางกลุ่มมีท่าในระดับนั้นไม่ถึง 2

### 4.5 Reminder interval ของแผน

`ExercisePlan.reminderIntervalMinutes` ใช้ค่าที่ถี่ที่สุดของทุกกลุ่มที่เลือก

ตัวอย่าง:

- `high + low` -> `30 นาที`
- `medium + low` -> `45 นาที`

### 4.6 Edit Main Plan

ผู้ใช้แก้แผนหลักได้ตลอดเวลา โดยแก้ได้ทั้งหมด:

- เพิ่ม/ลบกลุ่มปวด
- เปลี่ยนระดับความปวดรายกลุ่ม
- เลือก/สลับท่ารายกลุ่ม
- เปลี่ยน active start
- เปลี่ยน active end
- เปลี่ยน reminder interval

เมื่อกด save:

- plan ใหม่ต้องมีผลทันที
- home / session / reminder ต้อง sync ตามแผนใหม่

## 5. จำนวนท่าจริงในข้อมูลปัจจุบัน

อ้างอิงจาก [exercise_catalog.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\data\exercise_catalog.dart)

### คอ/บ่า/ไหล่

- `high` = 3 ท่า
- `medium` = 2 ท่า
- `low` = 3 ท่า

### สะบัก/หลังบน

- `high` = 2 ท่า
- `medium` = 3 ท่า
- `low` = 1 ท่า

### หลังล่าง/เอว

- `high` = 2 ท่า
- `medium` = 3 ท่า
- `low` = 1 ท่า

สรุป:

- ตอนนี้ collection สูงสุดต่อระดับคือ 3 ท่า
- logic รองรับกรณี `> 2` แล้ว

## 6. Data model ปัจจุบัน

ไฟล์หลัก: [app_models.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\models\app_models.dart)

โมเดลสำคัญ:

- `PainSelection`
  - `area`
  - `level`
  - `selectedExerciseIds`
- `UserProfile`
  - `painSelections`
  - `workHours`
  - `stretchHabit`
- `ExercisePlan`
  - `id`
  - `title`
  - `subtitle`
  - `groups`
  - `exercises`
  - `reminderIntervalMinutes`
- `PendingReminderLaunch`
  - `plan`
  - `alertMode`
  - `reminderAt`
  - `isTest`
- `ExerciseStatus`
  - `done`
  - `skipped`
  - `snoozed`
  - `missed`

## 7. State management และ persistence

แกนหลักอยู่ที่ [app_state.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\app\app_state.dart)

สิ่งที่ `AppState` ดูแล:

- current `UserProfile`
- current `ExercisePlan`
- current `ReminderSettings`
- exercise logs
- `nextReminderAt`
- `ReminderDiagnostics`
- `ReminderSyncState`
- pending reminder launch

Persistence:

- ใช้ `shared_preferences` ผ่าน [app_persistence.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\app_persistence.dart)
- snapshot รวมอยู่ใน `PersistedAppData`

Lifecycle:

- [app.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\app\app.dart) ใช้ `WidgetsBindingObserver`
- ตอนแอป `resumed` จะเรียก `appState.handleAppResumed()`
- ใช้เพื่อ reconcile reminder state และ refresh diagnostics

## 8. Questionnaire และ Edit Main Plan

### Questionnaire

- หน้า onboarding อยู่ที่ [questionnaire_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\questionnaire_screen.dart)
- ใช้ฟอร์มหลักจาก [plan_editor_form.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\widgets\plan_editor_form.dart)

### Edit Main Plan

- อยู่ที่ [plan_editor_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\plan_editor_screen.dart)
- เข้าได้จาก Settings
- save ผ่าน `appState.savePlan(...)`

## 9. Reminder / Notification / Alarm architecture

### 9.1 โหมดการแจ้งเตือน

มี 3 โหมด:

- `AlertMode.notification`
- `AlertMode.exact`
- `AlertMode.exactFullScreen`

พฤติกรรม:

- `notification` -> notification ปกติ
- `exact` -> exact scheduling ถ้าสิทธิ์พร้อม ไม่พร้อมก็ fallback
- `exactFullScreen` -> ขอ full-screen intent ถ้าระบบอนุญาต ไม่พร้อมก็ fallback

### 9.2 Scheduler

ไฟล์หลัก: [reminder_scheduler.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\reminder_scheduler.dart)

สิ่งที่ scheduler ทำ:

- สร้าง notification details ตาม mode
- ใช้ exact / inexact ตาม capability จริง
- ส่ง payload ที่มี `alertMode` และ `reminderAt`
- บันทึก sync state และ diagnostics

หมายเหตุสำคัญ:

- มีการอุด bug ที่เคย schedule เวลาซึ่ง `<= now` แล้ว plugin ปฏิเสธ
- ตอนนี้ scheduler จะ normalize ให้เวลาเริ่มอยู่ในอนาคตเสมอ

### 9.3 Alarm flow

หน้าหลัก: [alarm_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\alarm_screen.dart)

action:

- `เริ่มทำท่า` -> เข้า session
- `เลื่อน 10 นาที` -> `snoozed`
- `ปิดรอบนี้` -> `skipped`

Routing:

- เข้าแอปผ่าน payload
- `HomeShell` ตัดสินใจว่าจะเปิด session หรือ alarm screen

### 9.4 Full-screen behavior ปัจจุบัน

ไฟล์หลัก:

- [AndroidManifest.xml](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\AndroidManifest.xml)
- [MainActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\example\office_stretch_app\MainActivity.kt)

สิ่งที่เปิดใช้งานแล้ว:

- `showWhenLocked`
- `turnScreenOn`
- runtime behavior สำหรับ lock-screen path

ข้อจำกัด:

- ตอนนี้ยังไม่มี native `AlarmActivity`
- full-screen path ยังผ่าน `MainActivity` แล้วค่อยเข้า Flutter route
- ถ้าต้องการให้ใกล้ alarm app ของระบบมากขึ้น งานถัดไปคือเพิ่ม `AlarmActivity` แยก

## 10. Reminder diagnostics และ missed logic

สิ่งสำคัญ:

- อย่าใช้ `missed` เป็นหลักฐานว่า notification ถูกส่งจริง
- ตอนนี้แอปแยก `schedule proof` ออกจาก `delivery proof` มากขึ้นแล้ว
- การพิสูจน์ delivery จริงบนมือถือ ใช้ `adb/dumpsys` harness

หน้า diagnostics อยู่ใน [settings_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\settings_screen.dart)

ข้อมูลที่ใช้:

- `ReminderDiagnostics`
- `ReminderSyncState`

## 11. Branding และ assets

สิ่งที่เปลี่ยนแล้ว:

- ชื่อแอปเป็น `OfficeRelief`
- adaptive icon foreground/background มีแล้ว
- notification small icon มีแล้ว
- in-app brand image มีแล้ว
- mascot และ missed-state image มีแล้ว

สิ่งที่ยังไม่ finalize:

- package name ยังเป็น `com.example.office_stretch_app`

## 12. Android และ package

package ปัจจุบัน:

- `com.example.office_stretch_app`

ข้อควรระวัง:

- scripts และ adb harness หลายตัวผูกกับ package นี้
- ถ้าจะเปลี่ยน package name ต้องแก้ scripts, install path, และ test harness ให้ครบก่อน

## 13. Stack และ dependency สำคัญ

อ้างอิงจาก [pubspec.yaml](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\pubspec.yaml)

- Flutter
- `shared_preferences`
- `flutter_local_notifications`
- `timezone`
- `flutter_timezone`
- `flutter_test`
- `integration_test`

สถาปัตยกรรมโดยรวม:

- state หลักรวมอยู่ใน `AppState`
- business logic หลักอยู่ใน `ExerciseCatalog`, `ReminderTimeline`, `ReminderScheduler`
- persistence เป็น local snapshot
- ไม่มี backend

## 14. วิธี build และ scripts สำคัญ

### Build release APK

- [build-tester-apk.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\build-tester-apk.ps1)

ผลลัพธ์:

- [office-stretch-tester.apk](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\artifacts\office-stretch-tester.apk)

### Run บน emulator

- [run-android.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\run-android.ps1)

### Smoke test บน emulator

- [smoke-test-android.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\smoke-test-android.ps1)

### Verify local analyze/test

- [verify-local.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\verify-local.ps1)

### Device verification scripts

- [test-notification-modes-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-notification-modes-device.ps1)
- [test-full-screen-screen-states.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-full-screen-screen-states.ps1)
- [test-scheduled-notifications-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-scheduled-notifications-device.ps1)

## 15. การทดสอบที่มีอยู่

### Unit / widget tests

ไฟล์หลัก:

- [exercise_plan_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\test\exercise_plan_test.dart)
- [app_state_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\test\app_state_test.dart)
- [home_shell_alarm_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\test\home_shell_alarm_test.dart)
- [reminder_settings_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\test\reminder_settings_test.dart)
- [reminder_timeline_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\test\reminder_timeline_test.dart)

ครอบคลุม:

- max 2 exercises ต่อกลุ่ม
- multi-group plan
- reminder timeline และ overnight window
- alarm routing ใน `HomeShell`
- reminder settings serialization
- reminder / missed logic บางส่วน

### Integration / device tests

ไฟล์หลัก:

- [app_smoke_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\integration_test\app_smoke_test.dart)
- [notification_modes_device_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\integration_test\notification_modes_device_test.dart)
- [full_screen_screen_states_device_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\integration_test\full_screen_screen_states_device_test.dart)
- [alarm_flow_device_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\integration_test\alarm_flow_device_test.dart)

## 16. สิ่งที่พิสูจน์แล้วบนเครื่องจริง

อุปกรณ์ที่ใช้ทดสอบจริง:

- device id: `f4da450d`
- model: `RMX3491`

สิ่งที่พิสูจน์แล้ว:

- immediate notification ใช้งานได้ทุกโหมด
- `exact` ใช้งานได้
- `exactFullScreen` ใช้งานได้ในระดับ notification object และ alarm flow
- full-screen screen-state test ผ่านทั้งกรณี screen on และ screen off
- `Alarm screen` action flow ทำงานจริง
- scheduled notification พิสูจน์ด้วย `adb/dumpsys` ได้แล้ว

### ผลทดสอบสำคัญล่าสุด: screen-off + 1-minute scheduled reminder

รันเมื่อวันที่ `2026-03-19` ด้วย [test-scheduled-notifications-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-scheduled-notifications-device.ps1) แบบ `-ScreenOff`

ผล:

- `notification`
  - `baseline=0`
  - `final=1`
  - `delta=1`
  - `screenOff=True`
  - `interactive=False`
- `exact`
  - `baseline=1`
  - `final=2`
  - `delta=1`
  - `screenOff=True`
  - `interactive=False`
- `exactFullScreen`
  - `baseline=2`
  - `final=3`
  - `delta=1`
  - `screenOff=True`
  - `interactive=False`

ข้อสรุป:

- ตอนหน้าจอดับจริง ระบบโพสต์แจ้งเตือนขึ้นได้ครบทั้ง 3 โหมดในรอบ 1 นาที
- harness ใช้ `dumpsys notification` เพื่อพิสูจน์ `numPostedByApp` โดยไม่พึ่ง inference จาก `missed`

หมายเหตุ:

- บน ROM นี้ `dumpsys power` ไม่คืน `display state` ในรูปแบบที่คงที่เสมอ จึงใช้ `interactive=False` เป็นตัวชี้หลักของสถานะจอดับ

## 17. Known caveats

### 17.1 Full-screen caveat

- `exactFullScreen` ไม่ได้แปลว่า takeover เต็มจอ 100% ทุกสถานการณ์
- Android/ROM อาจ fallback เป็น heads-up notification
- โดยเฉพาะตอนหน้าจอเปิดอยู่

### 17.2 Exact alarm caveat

- exact alarm ยังขึ้นกับ permission และ device policy
- ถ้า permission ไม่พร้อม ระบบจะ fallback

### 17.3 Current architecture caveat

- ตอนนี้ยังไม่มี native `AlarmActivity`
- full-screen path ยังวิ่งผ่าน `MainActivity`
- ถ้าต้องการลดความรู้สึกช้า/หน่วงจาก heads-up -> full-screen งานถัดไปที่ถูกที่สุดคือเพิ่ม `AlarmActivity`

### 17.4 Product caveat

- แอปยังไม่ใช่ production release
- package name ยังไม่ final
- ยังไม่มี release signing flow ที่ปิดงานจริง

## 18. สิ่งที่ AI ถัดไปไม่ควรถอยกลับ

- อย่ารื้อ `multi-group plan` กลับไปเป็น `single program`
- อย่าลบ `ReminderSyncState` หรือ device harness โดยไม่มีตัวแทนที่พิสูจน์ scheduled delivery ได้จริง
- อย่ากลับไปใช้ `missed` เป็นหลักฐานแทนการส่ง notification จริง
- อย่าพึ่ง `integration_test` อย่างเดียวสำหรับ scheduled notification บนเครื่องจริง
- อย่าเปลี่ยน package name โดยไม่ไล่แก้ scripts และ adb harness ทั้งชุด

## 19. งานถัดไปที่แนะนำ

ลำดับที่คุ้มที่สุด:

1. ทำ `History screen` เป็นหน้าจริง
2. เปลี่ยน package name ให้เป็นของจริง
3. เตรียม release signing / versioning
4. ถ้าจะดัน alarm UX ต่อ:
   - เพิ่ม native `AlarmActivity`
   - แยก full-screen entry point ออกจาก `MainActivity`
5. เพิ่ม wrist/eye modules เมื่อมี content จริง

## 20. แผนที่ไฟล์สำคัญ

Core app:

- [main.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\main.dart)
- [app.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\app\app.dart)
- [app_state.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\app\app_state.dart)

Models:

- [app_models.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\models\app_models.dart)
- [reminder_diagnostics.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\models\reminder_diagnostics.dart)
- [reminder_sync_state.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\models\reminder_sync_state.dart)
- [persisted_app_data.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\models\persisted_app_data.dart)

Business logic:

- [exercise_catalog.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\data\exercise_catalog.dart)
- [reminder_scheduler.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\reminder_scheduler.dart)
- [reminder_timeline.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\reminder_timeline.dart)
- [device_automation.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\device_automation.dart)

Screens:

- [questionnaire_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\questionnaire_screen.dart)
- [home_shell.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\home_shell.dart)
- [home_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\home_screen.dart)
- [session_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\session_screen.dart)
- [settings_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\settings_screen.dart)
- [plan_editor_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\plan_editor_screen.dart)
- [alarm_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\alarm_screen.dart)

Widgets:

- [plan_editor_form.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\widgets\plan_editor_form.dart)
- [office_relief_brand_mark.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\widgets\office_relief_brand_mark.dart)
- [office_relief_mascot.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\widgets\office_relief_mascot.dart)
- [office_relief_missed_state.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\widgets\office_relief_missed_state.dart)

Android:

- [MainActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\example\office_stretch_app\MainActivity.kt)
- [AndroidManifest.xml](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\AndroidManifest.xml)

Scripts:

- [run-android.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\run-android.ps1)
- [smoke-test-android.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\smoke-test-android.ps1)
- [build-tester-apk.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\build-tester-apk.ps1)
- [verify-local.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\verify-local.ps1)
- [test-notification-modes-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-notification-modes-device.ps1)
- [test-full-screen-screen-states.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-full-screen-screen-states.ps1)
- [test-scheduled-notifications-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-scheduled-notifications-device.ps1)

## 21. สรุปสั้น

สถานะปัจจุบันของโปรเจ็กต์:

- ไม่ใช่แค่ MVP แบบ single plan แล้ว
- เป็น local-first app ที่มี:
  - `multi-group plan`
  - `editable main plan`
  - `alert modes`
  - `alarm flow`
  - `diagnostics`
  - `real-device verification harness`

จุดที่สำคัญที่สุดสำหรับ AI ถัดไป:

- รักษา architecture ปัจจุบันไว้
- อย่าถอย logic กลับเป็น single program
- ใช้ `adb/dumpsys` เมื่อพิสูจน์ scheduled reminder บนเครื่องจริง
- แยก `schedule proof` ออกจาก `delivery proof` เสมอ
