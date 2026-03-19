# OfficeRelief AI Handoff

Last updated: 2026-03-20  
Project root: `C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app`  
Current Android package: `com.lskram.officerelief`

## Purpose

เอกสารนี้ใช้ส่งต่องานให้ AI หรือผู้พัฒนาคนถัดไปโดยยึดสถานะจริงของโค้ดและผลทดสอบล่าสุด ไม่อิงจากบทสนทนาอย่างเดียว

หลักสำคัญ:

- แอปนี้ไม่ใช่ single-program app อีกต่อไป
- แกนปัจจุบันคือ `multi-group plan + reminder diagnostics + alarm flow + history`
- ห้ามใช้ `missed` เป็นหลักฐานแทน notification delivery จริง
- การพิสูจน์ reminder บนมือถือจริงให้ยึด `adb/dumpsys-based device scripts` เป็น source of truth

## Product Scope ปัจจุบัน

OfficeRelief เป็น Flutter app แบบ local-first สำหรับเตือนพนักงานออฟฟิศให้พักและยืดเส้น

Scope ที่มีแล้ว:

- ไม่มี login
- ไม่มี backend
- Android-first
- local persistence
- multi-group pain plan
- edit main plan หลัง onboarding
- history screen
- normal / exact / exact + full-screen alert modes
- alarm flow
- diagnostics สำหรับ notification

## Business Rules

### Pain groups

มีทั้งหมด 3 กลุ่ม:

1. `neckShoulders`
2. `upperBack`
3. `lowerBack`

### Pain levels

แต่ละกลุ่มมี 3 ระดับ:

1. `high`
2. `medium`
3. `low`

### Exercise selection

ผู้ใช้เลือกได้ `1-3` กลุ่ม และแต่ละกลุ่มมี:

- pain level ของตัวเอง
- selected exercise ids ของตัวเอง

กติกา:

- ต่อกลุ่มเลือก active exercises ได้สูงสุด `2`
- ถ้ามี `1` ท่า -> ใช้ `1`
- ถ้ามี `2` ท่า -> ใช้ `2`
- ถ้ามีมากกว่า `2` -> ยัง active ได้ไม่เกิน `2`

ขนาดรวมของ plan:

- 1 กลุ่ม -> สูงสุด 2 ท่า
- 2 กลุ่ม -> สูงสุด 4 ท่า
- 3 กลุ่ม -> สูงสุด 6 ท่า

### Reminder interval

`ExercisePlan.reminderIntervalMinutes` ใช้ค่าที่ถี่ที่สุดของทุกกลุ่มที่เลือก

ตัวอย่าง:

- `high + low` -> `30`
- `medium + low` -> `45`

### Edit Main Plan

ผู้ใช้แก้แผนหลักได้ตลอดเวลา

แก้ได้:

- กลุ่มที่ปวด
- ระดับความปวดรายกลุ่ม
- ท่าที่เลือกต่อกลุ่ม
- active start
- active end
- reminder interval

หลัง save:

- plan ใหม่ต้อง active ทันที
- home / session / reminders ต้อง resync

## Exercise Data ปัจจุบัน

อ้างอิง: [exercise_catalog.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\data\exercise_catalog.dart)

จำนวนท่าต่อระดับ:

- neck/shoulders
  - `high` = 3
  - `medium` = 2
  - `low` = 3
- upper back
  - `high` = 2
  - `medium` = 3
  - `low` = 1
- lower back
  - `high` = 2
  - `medium` = 3
  - `low` = 1

หมายเหตุ:

- ตอนนี้ collection สูงสุดคือ `3` ท่า
- rule เรื่อง `เลือกได้สูงสุด 2` รองรับแล้ว

## Core Models

อ้างอิง: [app_models.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\models\app_models.dart)

model สำคัญ:

- `PainSelection`
- `UserProfile`
- `ExercisePlan`
- `PlannedExercise`
- `ReminderSettings`
- `ReminderLaunchPayload`
- `PendingReminderLaunch`
- `ExerciseLog`
- `ExerciseStatus`
- `AlertMode`
- `VibrationLevel`

## App State และ Persistence

อ้างอิง:

- [app_state.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\app\app_state.dart)
- [app_persistence.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\app_persistence.dart)

`AppState` ดูแล:

- `UserProfile`
- active `ExercisePlan`
- `ReminderSettings`
- logs
- `nextReminderAt`
- `ReminderDiagnostics`
- `ReminderSyncState`
- pending reminder launch

Lifecycle:

- app resume เรียก `handleAppResumed()`
- ใช้ reconcile reminder state และ refresh diagnostics

## Notification และ Alarm Architecture

### Reminder scheduler

อ้างอิง: [reminder_scheduler.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\reminder_scheduler.dart)

รองรับ:

- `notification`
- `exact`
- `exactFullScreen`

behavior:

- exact mode พยายามใช้ exact scheduling ถ้า platform อนุญาต
- exact full-screen mode พยายามใช้ exact scheduling + full-screen intent
- ถ้า exact หรือ full-screen ไม่พร้อม จะ fallback โดยไม่ทำให้แอปล้ม

### Native launch path

ไฟล์ Android หลัก:

- [BaseFlutterActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\lskram\officerelief\BaseFlutterActivity.kt)
- [EntryActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\lskram\officerelief\EntryActivity.kt)
- [MainActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\lskram\officerelief\MainActivity.kt)
- [AlarmActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\lskram\officerelief\AlarmActivity.kt)

Flutter bridge:

- [app_launch_bridge.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\app_launch_bridge.dart)

flow:

1. notification ยิงเข้า `EntryActivity`
2. `EntryActivity` เลือกว่าจะเปิด `MainActivity` หรือ `AlarmActivity`
3. `AlarmActivity` รองรับ lock-screen path
4. Flutter รับ staged payload ผ่าน `app_launch_bridge`
5. [home_shell.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\home_shell.dart) เปิด:
   - `AlarmScreen` สำหรับ full-screen launches
   - `ExerciseSessionScreen` สำหรับ standard reminder launches

### Alarm screen

อ้างอิง: [alarm_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\alarm_screen.dart)

action ที่มี:

- `start` -> เข้า session
- `snooze` -> log `snoozed` และ reschedule
- `dismiss` -> log `skipped`

## Missed Reminder Logic

ห้ามลด logic นี้กลับไปเป็น time-only inference

กติกาปัจจุบัน:

- จะเชื่อ `missed` ได้ก็ต่อเมื่อ scheduler ยืนยัน pending requests ได้
- `ReminderSyncState.canTrustMissedInference` เป็นตัว gate
- `done`, `snoozed`, `skipped` ต้องกัน `missed` ซ้ำใน slot เดียวกัน

## History Screen

อ้างอิง: [history_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\history_screen.dart)

มีแล้ว:

- summary cards
- daily grouping
- statuses:
  - `done`
  - `skipped`
  - `snoozed`
  - `missed`
- empty state

## Branding และ UI ล่าสุด

รอบล่าสุดมีการเปลี่ยน asset และ UI เพิ่มเติม:

- adaptive icon foreground ใหม่ที่ [ic_launcher_foreground.png](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\res\drawable-nodpi\ic_launcher_foreground.png)
- in-app assets แบบ `No BG` ถูกแทนที่แล้ว:
  - [office_relief_in_app_logo.png](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\assets\branding\office_relief_in_app_logo.png)
  - [office_relief_mascot.png](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\assets\branding\office_relief_mascot.png)
  - [office_relief_missed_state.png](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\assets\branding\office_relief_missed_state.png)
  - [office_relief_complete_state.png](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\assets\branding\office_relief_complete_state.png)
- complete state ถูกใช้ใน [session_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\session_screen.dart)
- แบบสอบถามและ plan editor ถูกแก้ contrast ของ chip text/background ที่ [plan_editor_form.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\widgets\plan_editor_form.dart)
- หน้า Home กดเข้า edit plan ได้จาก card แผนหลักที่ [home_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\home_screen.dart)
- หน้า Settings มี permission note แบบกด `i` ได้ที่ [settings_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\settings_screen.dart)

## Test Strategy ที่ต้องใช้ต่อ

### Local

สคริปต์:

- [verify-local.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\verify-local.ps1)

ขั้นต่ำ:

- `flutter analyze`
- `flutter test`

### Emulator

สคริปต์:

- [smoke-test-android.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\smoke-test-android.ps1)

Smoke ปัจจุบันครอบ:

- onboarding
- Home
- Library
- Tips
- History
- Settings
- key controls ของ Home และ Settings

### Real device

สคริปต์หลัก:

- [test-notification-modes-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-notification-modes-device.ps1)
- [test-full-screen-screen-states.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-full-screen-screen-states.ps1)
- [test-scheduled-notifications-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-scheduled-notifications-device.ps1)

Operational rule:

- รันทีละตัวเท่านั้น
- ไม่รันขนานกันบนเครื่องเดียว
- ไม่รันขนานกับ script อื่นที่เรียก `Initialize-AndroidWorkspace`

เหตุผล:

- share device state
- share temp/workspace state
- เสี่ยงชน `.appdata\gitconfig`

## Latest Verified Results

วันที่ยืนยันล่าสุด: 2026-03-20

### Local

- `flutter analyze` ผ่าน
- `flutter test` ผ่าน `25 tests`

### Emulator

- smoke test ผ่าน

### Real device

device id: `f4da450d`

ผ่านครบ:

- notification modes
  - `notification`
  - `exact`
  - `exactFullScreen`
- full-screen screen states
  - `screenOff` -> เข้า `AlarmActivity`
  - `screenOnHome` -> fallback เป็น notification path ซึ่งยอมรับได้ตาม platform behavior
- scheduled 1-minute + screen off
  - `notification`
  - `exact`
  - `exactFullScreen`

### Latest release artifact

- [office-stretch-tester.apk](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\artifacts\office-stretch-tester.apk)
- [Final.apk](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\artifacts\Final.apk)

ทั้งสองไฟล์ชี้ไปที่ release build ล่าสุดของรอบนี้

## Known Caveats

- `Exact + full-screen` ตอนหน้าจอเปิดไม่ takeover เต็มจอทุกครั้งบน ROM นี้
- behavior นี้ยอมรับได้ เพราะ Android/ROM อาจเลือก heads-up notification path
- ถ้าจะพิสูจน์เรื่อง device delivery ให้ใช้ device scripts ไม่ใช่ดูจาก `missed` อย่างเดียว

## Safe Next Steps

งานถัดไปที่ปลอดภัย:

1. release signing / versioning discipline
2. final polish เฉพาะ copy หรือ spacing ที่ไม่กระทบ architecture
3. final regression อีกรอบก่อน freeze

สิ่งที่ไม่ควรทำโดยไม่ตั้งใจ:

- รื้อกลับเป็น single-program model
- ลด missed logic ให้เหลือ time-only
- เปลี่ยน reminder scripts ให้รันขนานกัน
- สรุปว่า full-screen ต้องเต็มจอทุกสถานการณ์บนทุก ROM
