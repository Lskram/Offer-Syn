# OfficeRelief AI Handoff

อัปเดตล่าสุด: 2026-03-19  
Git HEAD ตอนเขียนเอกสาร: `cd5cf4d`  
โปรเจกต์: `C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app`

## 1. เป้าหมายของเอกสารนี้

เอกสารนี้มีไว้ส่งต่อบริบทให้ AI หรือผู้พัฒนาคนถัดไป โดยตั้งใจให้:

- เข้าใจสถานะโปรเจกต์ปัจจุบันจากโค้ดจริง ไม่อิงแค่บทสนทนา
- รู้ว่าอะไรถูกทำแล้ว อะไรยังไม่ทำ
- รู้ logic หลักของแอป ทั้งฝั่ง plan, session, reminder, alarm, diagnostics
- รู้วิธี build และวิธีทดสอบที่พิสูจน์แล้วว่าใช้ได้
- ลดความเสี่ยงที่ AI ตัวถัดไปจะไปแก้งานผิดจุด หรือย้อนกลับไปใช้ assumption เก่า

## 2. ภาพรวมโปรเจกต์

ชื่อแอปปัจจุบันคือ `OfficeRelief`

แนวคิดของแอป:

- แอปช่วยเตือนคนทำงานหน้าคอมให้พักและยืดเส้น
- ใช้แบบสอบถามเพื่อสร้าง `main plan`
- ทำงานแบบ `local-first`
- ไม่มี login
- ไม่มี backend
- เน้น Android เป็นหลัก

สถานะปัจจุบัน:

- มี onboarding / questionnaire
- มี `multi-group plan`
- มีหน้าแก้ `main plan`
- มี exercise session พร้อม timer
- มี local persistence
- มี local notifications
- มี `alert mode` 3 แบบ
- มี `alarm flow` พร้อม `Alarm screen`
- มี diagnostics สำหรับ reminder
- มี real-device verification script สำหรับ notification หลายกรณี

## 3. ขอบเขตปัจจุบันของฟีเจอร์

### ฟีเจอร์ที่มีแล้ว

- เลือกกลุ่มปวดได้มากกว่า 1 กลุ่ม
- แต่ละกลุ่มกำหนดระดับความปวดของตัวเองได้
- แต่ละกลุ่มเลือกท่าได้สูงสุด 2 ท่า
- หน้า Settings มีหน้าแก้ `main plan`
- ตั้งเวลา active window ได้
- ตั้ง interval reminder ได้
- มี notification sound และ vibration toggle
- มี vibration level 3 ระดับ
- มี `AlertMode.notification`
- มี `AlertMode.exact`
- มี `AlertMode.exactFullScreen`
- มี `Alarm screen` สำหรับโหมด full-screen
- มี action บน alarm คือ `start`, `snooze`, `dismiss`
- มี log สถานะ `done`, `skipped`, `snoozed`, `missed`
- มี reminder diagnostics และ reminder sync state

### ฟีเจอร์ที่ยังไม่มี

- backend / cloud sync
- login / register
- release-ready package name
- Google Play Store deployment
- module ท่ากลุ่ม `ข้อมือ`
- module ท่ากลุ่ม `ตา`
- dedicated history screen แยกเป็นหน้าจริง

## 4. กติกาธุรกิจที่ต้องถือเป็นหลัก

### 4.1 กลุ่มปวดและระดับความปวด

มีกลุ่มปวดทั้งหมด 3 กลุ่ม:

- `PainArea.neckShoulders`
- `PainArea.upperBack`
- `PainArea.lowerBack`

แต่ละกลุ่มมี 3 ระดับ:

- `PainLevel.high`
- `PainLevel.medium`
- `PainLevel.low`

### 4.2 จำนวนท่าต่อกลุ่ม

กติกาปัจจุบัน:

- แต่ละกลุ่มเลือกท่าได้สูงสุด 2 ท่า
- ถ้ามีท่าใน collection แค่ 1 ท่า ให้ใช้ 1 ท่า
- ถ้ามีท่า 2 ท่า ให้ใช้ 2 ท่า
- ถ้ามีมากกว่า 2 ท่า ให้ active จริงได้แค่ 2 ท่า และผู้ใช้สลับเลือกได้

กติกานี้ถูก implement ใน:

- [exercise_catalog.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\data\exercise_catalog.dart)
- [plan_editor_form.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\widgets\plan_editor_form.dart)

### 4.3 จำนวนท่ารวมตามจำนวนกลุ่มที่เลือก

- ถ้าเลือก 1 กลุ่ม จะได้ท่ารวมสูงสุด 2 ท่า
- ถ้าเลือก 2 กลุ่ม จะได้ท่ารวมสูงสุด 4 ท่า
- ถ้าเลือก 3 กลุ่ม จะได้ท่ารวมสูงสุด 6 ท่า

จำนวนจริงอาจน้อยกว่าได้ ถ้าบางกลุ่มมีท่าในระดับนั้นไม่ถึง 2

### 4.4 การคำนวณ reminder interval ของ plan

`ExercisePlan.reminderIntervalMinutes` ใช้ค่าที่ถี่ที่สุดของทุกกลุ่มที่เลือก

ตัวอย่าง:

- ถ้าเลือก `high + low` จะได้ interval = 30 นาที
- ถ้าเลือก `medium + low` จะได้ interval = 45 นาที

## 5. จำนวนท่าที่มีจริงในข้อมูลตอนนี้

ข้อมูลมาจาก [exercise_catalog.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\data\exercise_catalog.dart)

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

- ตอนนี้ยังไม่มี collection ไหนเกิน 3 ท่า
- ระบบรองรับกรณี `> 2` แล้ว

## 6. Data model ปัจจุบัน

ไฟล์หลัก: [app_models.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\models\app_models.dart)

### Model สำคัญ

`PainSelection`

- เก็บ `area`
- เก็บ `level`
- เก็บ `selectedExerciseIds`

`UserProfile`

- เก็บ `painSelections`
- เก็บ `workHours`
- เก็บ `stretchHabit`

`ExercisePlan`

- เก็บ `id`
- เก็บ `title`
- เก็บ `subtitle`
- เก็บ `groups`
- เก็บ `exercises`
- เก็บ `reminderIntervalMinutes`

`PendingReminderLaunch`

- ใช้ตอน notification หรือ full-screen alarm เข้ามาเปิดแอป
- ถือข้อมูล `plan`, `alertMode`, `reminderAt`, `isTest`

`ExerciseStatus`

- `done`
- `skipped`
- `snoozed`
- `missed`

## 7. State management และ persistence

ไฟล์แกน: [app_state.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\app\app_state.dart)

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

- `OfficeStretchApp` ใน [app.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\app\app.dart) ใช้ `WidgetsBindingObserver`
- เมื่อแอป `resumed` จะเรียก `appState.handleAppResumed()`
- ใช้สำหรับ reconcile missed reminder และ sync ใหม่

## 8. Questionnaire และการแก้ Main Plan

### Questionnaire

หน้า onboarding อยู่ที่:

- [questionnaire_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\questionnaire_screen.dart)

แบบฟอร์มจริง reuse จาก:

- [plan_editor_form.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\widgets\plan_editor_form.dart)

### Edit Main Plan

หน้าแก้ plan อยู่ที่:

- [plan_editor_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\plan_editor_screen.dart)

ตอนนี้หน้า `Edit Main Plan` แก้ได้:

- เพิ่ม/ลบกลุ่มปวด
- เปลี่ยนระดับความปวดรายกลุ่ม
- เลือก/สลับท่ารายกลุ่ม
- เปลี่ยน interval
- เปลี่ยน active start
- เปลี่ยน active end

เมื่อกด save:

- เรียก `appState.savePlan(...)`
- plan ใหม่มีผลทันที
- reminder ถูก resync

## 9. Home, Session, Alarm flow

### Home

ไฟล์:

- [home_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\home_screen.dart)

แสดง:

- จำนวนกลุ่มใน plan
- จำนวนท่ารวม
- interval
- next reminder
- summary ของกลุ่มที่เลือก
- รายการท่าใน plan
- recent activity log
- missed reminder card เมื่อมี missed วันนี้

### Session

ไฟล์:

- [session_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\session_screen.dart)

พฤติกรรม:

- รับ `ExercisePlan`
- รับ `reminderAt` ได้
- เมื่อทำครบ จะ log เป็น `done`
- เมื่อมาจาก reminder จะผูก `reminderAt` ลง log ด้วย

### Alarm flow

ไฟล์:

- [alarm_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\alarm_screen.dart)
- [home_shell.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\home_shell.dart)

กติกา:

- ถ้า notification payload เข้ามาและ `alertMode.prefersFullScreenIntent == true`
- `HomeShell` จะเปิด `AlarmScreen`

Action บน Alarm screen:

- `start` -> เปิด session ทันที
- `snooze` -> เรียก `appState.snoozePendingReminder()`
- `dismiss` -> เรียก `appState.dismissPendingReminder()`

## 10. Reminder / Notification / Alarm system

ไฟล์แกน:

- [reminder_scheduler.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\reminder_scheduler.dart)
- [reminder_timeline.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\reminder_timeline.dart)
- [reminder_sync_state.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\models\reminder_sync_state.dart)
- [reminder_diagnostics.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\models\reminder_diagnostics.dart)

### Alert modes

มี 3 โหมด:

- `notification`
- `exact`
- `exactFullScreen`

Behavior:

- `notification` = notification ปกติ ไม่ขอ exact alarm
- `exact` = ขอ exact alarm ถ้าเครื่องอนุญาต
- `exactFullScreen` = ขอ exact alarm + ขอ full-screen intent ถ้าเครื่องอนุญาต

Fallback:

- ถ้า exact ใช้ไม่ได้ จะ fallback ไป inexact
- ถ้า full-screen ใช้ไม่ได้ จะ fallback ไป high-priority notification

### Schedule mode จริง

การ schedule ใช้:

- `AndroidScheduleMode.exactAllowWhileIdle` เมื่อ exact ใช้ได้
- `AndroidScheduleMode.inexactAllowWhileIdle` เมื่อ exact ใช้ไม่ได้

### Active window

ระบบรองรับ:

- กะปกติ เช่น `08:00 -> 16:30`
- กะข้ามวัน เช่น `18:00 -> 02:00`

เงื่อนไข invalid:

- `start == end`

### Missed reminder inference

จุดสำคัญ:

- ระบบจะไม่ลง `missed` จากเวลาล้วน ๆ อีกแล้ว
- จะเชื่อเฉพาะรอบที่มีหลักฐานจาก `ReminderSyncState` ว่าถูก schedule สำเร็จจริง

เงื่อนไขที่ใช้:

- permission ตอน sync ต้องพร้อม
- `pendingRequestCount > 0`
- `scheduledReminders` ต้องไม่ว่าง
- `lastError == null`

## 11. Diagnostics ที่มีในแอป

หน้า Settings อยู่ที่:

- [settings_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\settings_screen.dart)

ตอนนี้ diagnostics แสดงอย่างน้อย:

- notification permission
- battery optimization state
- exact alarm state
- full-screen intent state
- schedule mode ที่ใช้อยู่
- pending request count
- confirmed reminders
- next scheduled reminder
- last sync
- error ล่าสุดถ้ามี

Action ในหน้า Settings ที่มี:

- ขอ notification permission
- ขอ exact alarm permission
- เปิดหน้า system notification settings
- เปิด battery settings
- เปิด full-screen intent settings
- test notification ทันที
- resync reminders ทันที

## 12. Android-specific implementation

ไฟล์ Android สำคัญ:

- [MainActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\example\office_stretch_app\MainActivity.kt)
- [AndroidManifest.xml](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\AndroidManifest.xml)

สิ่งที่ `MainActivity.kt` ทำ:

- bridge notification/system settings ผ่าน `MethodChannel`
- bridge automation command สำหรับ device verification
- รับ launch intent extras เพื่อเตรียม automation mode

ข้อเท็จจริงสำคัญ:

- package name ตอนนี้ยังเป็น `com.example.office_stretch_app`
- ถ้าจะทำ release จริง ควรเปลี่ยน package name

## 13. Branding และ asset

แบรนด์ปัจจุบัน:

- ชื่อแอป `OfficeRelief`
- มีโลโก้, mascot, missed-state image แล้ว

Asset หลัก:

- [office_relief_in_app_logo.png](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\assets\branding\office_relief_in_app_logo.png)
- [office_relief_mascot.png](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\assets\branding\office_relief_mascot.png)
- [office_relief_missed_state.png](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\assets\branding\office_relief_missed_state.png)

Android icon assets ที่มีแล้ว:

- adaptive icon foreground
- adaptive icon background
- launcher icon
- notification small icon `ic_stat_office_relief`

## 14. Stack และ dependency สำคัญ

จาก [pubspec.yaml](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\pubspec.yaml)

- Flutter
- `shared_preferences`
- `flutter_local_notifications`
- `timezone`
- `flutter_timezone`
- `flutter_test`
- `integration_test`

สถาปัตยกรรมโดยรวม:

- state หลักรวมอยู่ใน `AppState`
- business logic กระจายที่ `ExerciseCatalog`, `ReminderTimeline`, `ReminderScheduler`
- persistence เป็น local snapshot
- ไม่มี backend integration

## 15. วิธี build และ script สำคัญ

### Build release APK สำหรับ tester

- [build-tester-apk.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\build-tester-apk.ps1)

ผลลัพธ์:

- [office-stretch-tester.apk](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\artifacts\office-stretch-tester.apk)

### Run บน emulator

- [run-android.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\run-android.ps1)

### Smoke test บน emulator

- [smoke-test-android.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\smoke-test-android.ps1)

### Verify local analyze/test

- [verify-local.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\verify-local.ps1)

## 16. การทดสอบที่มีอยู่

### Unit / widget tests

ไฟล์สำคัญ:

- [exercise_plan_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\test\exercise_plan_test.dart)
- [app_state_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\test\app_state_test.dart)
- [home_shell_alarm_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\test\home_shell_alarm_test.dart)
- [reminder_settings_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\test\reminder_settings_test.dart)
- [reminder_timeline_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\test\reminder_timeline_test.dart)

สิ่งที่ถูกคุมด้วย test:

- max 2 exercises ต่อกลุ่ม
- แผนรวมหลายกลุ่ม
- normalize selection
- reminder timeline และ overnight window
- alarm routing ใน `HomeShell`
- reminder setting serialization
- missed reminder logic บางส่วน

### Integration / device tests

ไฟล์สำคัญ:

- [app_smoke_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\integration_test\app_smoke_test.dart)
- [notification_modes_device_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\integration_test\notification_modes_device_test.dart)
- [full_screen_screen_states_device_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\integration_test\full_screen_screen_states_device_test.dart)
- [alarm_flow_device_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\integration_test\alarm_flow_device_test.dart)

Script สำคัญ:

- [test-notification-modes-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-notification-modes-device.ps1)
- [test-full-screen-screen-states.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-full-screen-screen-states.ps1)
- [test-scheduled-notifications-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-scheduled-notifications-device.ps1)

## 17. สิ่งที่พิสูจน์แล้วบนเครื่องจริง

อุปกรณ์ที่ทดสอบจริง:

- Android device `f4da450d`
- ผู้ใช้ใช้งานจริงบนเครื่อง `RMX3491`

สิ่งที่พิสูจน์แล้ว:

- immediate notification ทุกโหมดใช้งานได้
- exact mode ใช้งานได้
- exact + full-screen ใช้งานได้ในระดับ notification object และ alarm flow
- full-screen screen state test ผ่านทั้งกรณี screen on และ screen off
- `Alarm screen` action flow ทำงาน
- scheduled notification ถูกพิสูจน์ด้วย `adb/dumpsys` harness แล้ว

แนวทางพิสูจน์ scheduled path ปัจจุบัน:

- ไม่ใช้ `integration_test` เป็นตัวถือ alarm ค้างอีกต่อไป
- ใช้ installed-app automation ผ่าน [device_automation.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\device_automation.dart)
- แล้ว verify จาก `adb shell dumpsys notification --noredact`

เหตุผล:

- integration runner เคย force-stop / cleanup app หลังจบ test
- ทำให้ Android ล้าง alarm และทำให้ผล scheduled path ไม่น่าเชื่อถือ

## 18. Known caveats ที่ AI ถัดไปต้องรู้

### สำคัญมาก

- อย่าใช้ `missed` log เป็นหลักฐานว่า notification ถูกส่งจริง
- ถ้าจะพิสูจน์ delivery จริง ให้ใช้ diagnostics, pending requests, และ `adb/dumpsys` verification

### Full-screen caveat

- `exactFullScreen` ไม่ได้แปลว่า takeover เต็มจอ 100% ทุกสถานการณ์
- Android/ROM อาจ fallback เป็น heads-up notification
- โดยเฉพาะตอนหน้าจอเปิดอยู่

### Exact alarm caveat

- exact alarm ยังขึ้นกับ permission และ device policy
- ถ้า permission ไม่พร้อม ระบบจะ fallback เป็น inexact

### Product caveat

- แอปยังไม่ใช่ production release
- package name ยังไม่ final
- ไม่มี release signing flow ที่ปิดงานแล้ว

## 19. สิ่งที่ไม่ควรถูกทำโดย AI ถัดไปแบบไม่คิด

- อย่ารื้อ reminder flow กลับไปใช้ `single program`
- อย่าลด `multi-group plan` กลับไปเหลือ `painArea เดียว`
- อย่าลบ `ReminderSyncState` หรือ `scheduledReminders` ถ้ายังไม่แทนด้วยกลไกที่พิสูจน์ schedule ได้จริง
- อย่าพึ่งพา `integration_test` อย่างเดียวสำหรับ scheduled notification บน device จริง
- อย่าเปลี่ยน package name ระหว่างที่ยังต้องทดสอบบนเครื่องผู้ใช้ โดยไม่จัดการ install path และ scripts ให้ครบ

## 20. งานถัดไปที่แนะนำ

ลำดับที่คุ้มที่สุด:

1. ทำ `History screen` เป็นหน้าจริง
2. เปลี่ยน package name ให้เป็นของจริง
3. เตรียม release signing / versioning
4. เพิ่ม wrist/eye modules ก็ต่อเมื่อมี source content ที่ชัด

ถ้าจะขยาย alarm flow ต่อ:

- เพิ่ม dedicated alarm analytics / diagnostics ใน UI
- เพิ่ม action button บน notification ถ้าต้องการ

ถ้าจะขยาย data model ต่อ:

- รักษากติกา `1-3 groups`, `max 2 exercises per group`

## 21. แผนที่ไฟล์สำคัญ

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

## 22. สรุปสุดท้ายแบบสั้น

โปรเจกต์นี้ไม่ใช่แค่ MVP แบบถามตอบแล้วเปิดหน้าท่าเดี่ยวอีกต่อไป แต่ตอนนี้เป็นแอป local-first ที่มี:

- `multi-group main plan`
- `editable plan`
- `reminder diagnostics`
- `alarm flow`
- `real-device notification verification`

ถ้าจะส่งต่องานให้ AI ตัวถัดไป จุดที่สำคัญที่สุดคือ:

- รักษา architecture ปัจจุบันไว้
- อย่าถอย logic กลับไปแบบ single program
- ใช้ diagnostics และ device harness เมื่อแตะ notification
- แยก `schedule proof` ออกจาก `delivery proof` เสมอ
