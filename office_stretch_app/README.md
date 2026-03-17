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

- Reminders are scheduled with `AndroidScheduleMode.inexactAllowWhileIdle`.
- They can still appear while the screen is off or while the user is in another app.
- Delivery time is not exact. Android may delay reminders because of Doze mode, OEM battery restrictions, or notification settings.
- The onboarding screen now includes a reminder checklist, and the Settings screen includes a readiness card with:
  - notification permission status
  - battery optimization status
  - shortcuts to Android notification and battery settings

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

## Build note

Run `.\scripts\run-android.ps1` and `.\scripts\smoke-test-android.ps1` one at a time. Running both at the same time can corrupt or lock the Android Gradle/Kotlin build caches in the redirected build directory.
