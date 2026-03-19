# OfficeRelief AI Handoff

Last updated: 2026-03-19  
Git HEAD when this document was refreshed: `141d09a`  
Project root: `C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app`

## Purpose

เอกสารนี้มีไว้ส่งต่อให้ AI หรือผู้พัฒนาคนถัดไปโดยไม่ให้หลุดประเด็นจากสถานะจริงของโค้ด, rules, notification architecture, และผลทดสอบล่าสุด

หลักสำคัญ:

- ใช้อิงจากโค้ดจริง ไม่ใช่จากบทสนทนาอย่างเดียว
- ห้ามย้อน architecture กลับไปเป็น single-program app
- ห้ามใช้ `missed` เป็นหลักฐานแทน notification delivery จริง
- สำหรับ real-device reminder proof ให้ถือ `adb/dumpsys-based harness` เป็น source of truth

## Current Product Scope

OfficeRelief is a local-first Flutter app for office workers. It recommends short stretch plans, reminds the user to take breaks, and tracks what happened during each reminder cycle.

Current scope:

- no login
- no backend
- Android-first
- local persistence only
- multi-group pain plan
- reminder diagnostics
- alarm-style notification modes
- history screen

## What Is Already Implemented

Core user flows:

- onboarding / questionnaire
- multi-group main plan creation
- edit main plan after onboarding
- exercise session with timer
- local reminder scheduling
- history/log view
- settings for alert mode, vibration, sound, and active window

Reminder modes:

- `notification`
- `exact`
- `exactFullScreen`

Alarm flow:

- alarm screen exists
- user actions:
  - start session
  - snooze 10 minutes
  - dismiss current round

Diagnostics:

- notification permission
- exact alarm capability
- full-screen intent capability
- battery optimization status
- next reminder and sync state

Branding:

- OfficeRelief name, icon assets, in-app branding, mascot assets already wired

## Business Rules

### Pain groups

There are exactly 3 pain groups:

1. `neckShoulders`
2. `upperBack`
3. `lowerBack`

### Pain levels

Each group has 3 levels:

1. `high`
2. `medium`
3. `low`

### Exercise selection rules

The user can select `1-3` pain groups.

Each selected group has:

- its own pain level
- its own selected exercise ids

Selection cap:

- max `2` active exercises per group

Rule:

- if a collection has `1` exercise -> use `1`
- if a collection has `2` exercises -> use `2`
- if a collection has `>2` exercises -> active selection is still capped at `2`

Total plan size:

- 1 selected group -> up to 2 exercises
- 2 selected groups -> up to 4 exercises
- 3 selected groups -> up to 6 exercises

### Reminder interval rule

`ExercisePlan.reminderIntervalMinutes` uses the most frequent interval among selected groups.

Examples:

- `high + low` -> `30`
- `medium + low` -> `45`

### Edit Main Plan rule

The user can edit the main plan at any time. Editable fields:

- selected pain groups
- pain level per group
- selected exercises per group
- active start
- active end
- reminder interval

After save:

- the plan must become active immediately
- home, session, and reminders must resync

## Current Exercise Data

Source: [exercise_catalog.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\data\exercise_catalog.dart)

Group counts:

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

Important:

- current collections top out at `3` exercises
- the `>2` selection rule is already supported

## Key Models

Main file: [app_models.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\models\app_models.dart)

Important models:

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

## App State and Persistence

Main state file: [app_state.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\app\app_state.dart)

`AppState` owns:

- `UserProfile`
- active `ExercisePlan`
- `ReminderSettings`
- logs
- `nextReminderAt`
- `ReminderDiagnostics`
- `ReminderSyncState`
- pending reminder launch

Persistence:

- implemented through [app_persistence.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\app_persistence.dart)
- snapshot model: `PersistedAppData`

Lifecycle:

- app resume calls `handleAppResumed()`
- this reconciles reminder state and refreshes diagnostics

## Notification and Alarm Architecture

### Reminder scheduler

Main file: [reminder_scheduler.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\reminder_scheduler.dart)

Behavior:

- normal notifications use regular reminder category
- exact mode prefers exact scheduling when allowed
- exact full-screen mode prefers exact scheduling and full-screen intent when allowed
- fallback remains in place if the platform does not grant exact/full-screen capability

### Native launch path

This project no longer relies only on the old launcher path for alarm entry.

Native Android files:

- [BaseFlutterActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\example\office_stretch_app\BaseFlutterActivity.kt)
- [EntryActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\example\office_stretch_app\EntryActivity.kt)
- [MainActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\example\office_stretch_app\MainActivity.kt)
- [AlarmActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\example\office_stretch_app\AlarmActivity.kt)

Flutter bridge:

- [app_launch_bridge.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\app_launch_bridge.dart)

Current flow:

1. Notification launches `EntryActivity`
2. `EntryActivity` decides whether the payload should go to `MainActivity` or `AlarmActivity`
3. `AlarmActivity` enables lock-screen behavior and captures the alarm payload
4. Flutter receives the staged launch command through `app_launch_bridge`
5. [home_shell.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\home_shell.dart) presents:
   - `AlarmScreen` for full-screen alarm launches
   - `ExerciseSessionScreen` for standard reminder launches

### Alarm screen behavior

Main file: [alarm_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\alarm_screen.dart)

Actions:

- `start` -> opens the session
- `snooze` -> logs `snoozed` and reschedules
- `dismiss` -> logs `skipped`

## Missed Reminder Logic

Missed logic must not infer delivery from time alone.

Current rule:

- `missed` is only trusted when the scheduler can confirm pending requests
- `ReminderSyncState.canTrustMissedInference` gates missed inference
- `done`, `snoozed`, and `skipped` should prevent duplicate `missed` entries for the same slot

This is deliberate. Do not simplify it back to time-only inference.

## History Screen

Main file: [history_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\history_screen.dart)

Current capabilities:

- summary cards
- daily grouping
- statuses:
  - `done`
  - `skipped`
  - `snoozed`
  - `missed`
- empty state for new users

## Real-Device Verification Strategy

The original device proof that relied on long-running `integration_test` sessions became unstable after the native alarm-entry work.

The current verified proof strategy is:

- `notification modes` -> `adb + app automation + dumpsys notification`
- `full-screen screen states` -> `adb + app automation + activity dump + screenshot`
- `scheduled 1-minute + screen off` -> `adb + app automation + dumpsys notification`

This means:

- do not treat `integration_test` alone as the source of truth for device reminder delivery
- use the PowerShell wrappers below

## Test Scripts That Matter

Core scripts:

- [verify-local.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\verify-local.ps1)
- [smoke-test-android.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\smoke-test-android.ps1)
- [build-tester-apk.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\build-tester-apk.ps1)

Real-device scripts:

- [test-notification-modes-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-notification-modes-device.ps1)
- [test-full-screen-screen-states.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-full-screen-screen-states.ps1)
- [test-scheduled-notifications-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-scheduled-notifications-device.ps1)

Operational rule:

- run device scripts one at a time
- do not run them in parallel on the same phone
- do not run them in parallel with another script that calls `Initialize-AndroidWorkspace`

Reason:

- they share device state
- they share workspace temp state
- they can race on `.appdata\gitconfig`

## Latest Verified Regression Baseline

### Local

- `flutter analyze` passed
- `flutter test` passed with `23 tests`

### Emulator

- [smoke-test-android.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\smoke-test-android.ps1) passed

### Real device

Device id:

- `f4da450d`

Passed:

- [test-notification-modes-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-notification-modes-device.ps1)
  - `notification`
  - `exact`
  - `exactFullScreen`
- [test-scheduled-notifications-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-scheduled-notifications-device.ps1) with `-ScreenOff`
  - `notification`
  - `exact`
  - `exactFullScreen`
- [test-full-screen-screen-states.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-full-screen-screen-states.ps1)
  - `screenOnHome`: alarm notification posted with `hasFullScreenIntent=true`, but no `AlarmActivity`
  - `screenOff`: alarm notification posted and `AlarmActivity` present in the activity dump

### Release

- [build-tester-apk.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\build-tester-apk.ps1) passed
- latest APK: [office-stretch-tester.apk](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\artifacts\office-stretch-tester.apk)

## Meaning of the Current Full-Screen Result

Interpret the full-screen result correctly:

- `screenOnHome` not switching into `AlarmActivity` is acceptable on this ROM
- `screenOff` is the critical acceptance case for `exactFullScreen`

Required contract for this project:

- `screenOff + exactFullScreen` -> native alarm path observed
- `screenOnHome + exactFullScreen` -> alarm notification observed, even if Android keeps it as heads-up / notification UI

Do not treat `screenOnHome` fallback as a hard bug unless the product requirement changes.

## Known Risks / Caveats

1. `screenOnHome` full-screen behavior is ROM-controlled
- Android may keep it as heads-up

2. Exact/full-screen permissions are still capability-based
- the app must fall back safely

3. Package name is still not production-ready
- current package is still `com.example.office_stretch_app`

4. Release hardening is not finished
- package rename
- versioning cleanup
- signing flow

## Files Most Likely To Matter Next

Core:

- [main.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\main.dart)
- [app_state.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\app\app_state.dart)
- [home_shell.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\home_shell.dart)
- [alarm_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\alarm_screen.dart)
- [history_screen.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\screens\history_screen.dart)

Services:

- [reminder_scheduler.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\reminder_scheduler.dart)
- [reminder_timeline.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\reminder_timeline.dart)
- [device_automation.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\device_automation.dart)
- [app_launch_bridge.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\lib\services\app_launch_bridge.dart)

Android:

- [BaseFlutterActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\example\office_stretch_app\BaseFlutterActivity.kt)
- [EntryActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\example\office_stretch_app\EntryActivity.kt)
- [MainActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\example\office_stretch_app\MainActivity.kt)
- [AlarmActivity.kt](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\kotlin\com\example\office_stretch_app\AlarmActivity.kt)
- [AndroidManifest.xml](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\android\app\src\main\AndroidManifest.xml)

Tests:

- [app_smoke_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\integration_test\app_smoke_test.dart)
- [app_state_test.dart](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\test\app_state_test.dart)

## Recommended Next Work

Highest-value next steps:

1. Change the package name away from `com.example.office_stretch_app`
2. Do release hardening
3. Rerun the full regression stack after the package-name change

Regression stack to rerun after that:

- local
  - `flutter analyze`
  - `flutter test`
- emulator
  - [smoke-test-android.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\smoke-test-android.ps1)
- real device
  - [test-notification-modes-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-notification-modes-device.ps1)
  - [test-full-screen-screen-states.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-full-screen-screen-states.ps1)
  - [test-scheduled-notifications-device.ps1](C:\Users\UsEr\OneDrive\Documents\Playground\office_stretch_app\scripts\test-scheduled-notifications-device.ps1) with `-ScreenOff`

## Do Not Regress These Decisions

- do not revert back to single-program plan logic
- do not revert reminder proof back to time-only missed inference
- do not rely on pure `integration_test` as the only proof of real-device reminder delivery
- do not run device scripts in parallel
