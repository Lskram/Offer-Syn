# Office Stretch App

Flutter MVP scaffold for an office stretching app focused on people who work in front of a computer for long periods.

## Current scope

- No login or backend
- Questionnaire-driven plan generation
- Home dashboard with recommended program
- Exercise library
- Guided session screen with countdown timer
- Tips and settings screens
- Local persistence for questionnaire, settings, logs, and next reminder time
- Local notification scheduling for Android/iOS/macOS targets

## Project notes

- The app is intentionally `local-first` for the MVP.
- Wrist and eye exercise modules are deferred because the current source material is incomplete for those categories.
- The revised Thai requirements document lives in `docs/requirements-mvp-th.md`.
- On Windows, Flutter plugins require symlink support. If `flutter run` complains, enable Developer Mode first.

## Android reminder behavior

- Reminders now prefer `AndroidScheduleMode.exactAllowWhileIdle` when the app has exact-alarm access.
- If exact alarms are not available, the app falls back to `AndroidScheduleMode.inexactAllowWhileIdle`.
- They can still appear while the screen is off or while the user is in another app.
- Delivery time may still be delayed by Doze mode, OEM battery restrictions, muted notification channels, or user notification settings.
- The Settings screen now includes:
  - notification permission status
  - battery optimization status
  - exact alarm status
  - a 1-minute interval option for testing
  - shortcuts to Android notification and battery settings
  - a system sound picker plus vibration toggle
- Missed reminders are recorded in the daily activity log once the app resumes and detects that a full reminder window passed without any completed exercise.

For reliable behavior on a real device, allow notifications and set the app battery mode to `Unrestricted` when the device vendor supports that option.

## Run

```powershell
cd office_stretch_app
.\scripts\run-android.ps1
```

The script above:

- ensures Android temp/build output is redirected to `D:\Android`
- boots the `OfficeStretch_API34` emulator if it is not already running
- builds a debug APK
- installs and launches the app on the emulator

Override defaults if your machine uses different paths:

```powershell
.\scripts\run-android.ps1 -AvdName MyAvd -AndroidWorkRoot D:\Android -AndroidSdkRoot C:\Users\UsEr\AppData\Local\Android\Sdk -JavaHome "D:\Android Studio\jbr"
```

## Smoke test

```powershell
cd office_stretch_app
.\scripts\smoke-test-android.ps1
```

The smoke test runs on the emulator and verifies:

- onboarding questionnaire
- home, library, tips, and settings navigation
- starting and completing an exercise session
- settings updates
- resetting back to onboarding

The integration test file is [app_smoke_test.dart](C:/Users/UsEr/OneDrive/Documents/Playground/office_stretch_app/integration_test/app_smoke_test.dart).

## Tester build

```powershell
cd office_stretch_app
.\scripts\build-tester-apk.ps1
```

The script builds a release APK for internal testing and copies it to:

`office_stretch_app/artifacts/office-stretch-tester.apk`

Tester instructions live in [tester-checklist-th.md](C:/Users/UsEr/OneDrive/Documents/Playground/office_stretch_app/docs/tester-checklist-th.md).

## Build note

Run `.\scripts\run-android.ps1` and `.\scripts\smoke-test-android.ps1` one at a time. Running both at the same time can corrupt or lock the Android Gradle/Kotlin build caches in the redirected build directory.
