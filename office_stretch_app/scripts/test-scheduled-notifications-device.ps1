param(
    [string]$DeviceId = 'f4da450d',
    [string]$AndroidWorkRoot = 'D:\Android',
    [string]$AndroidSdkRoot = 'C:\Users\UsEr\AppData\Local\Android\Sdk',
    [string]$JavaHome = 'D:\Android Studio\jbr',
    [switch]$ScreenOff
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$workspaceRoot = Split-Path -Parent $projectRoot
$flutterRoot = Join-Path $workspaceRoot 'flutter'
$applicationId = 'com.lskram.officerelief'
$mainActivity = "$applicationId/.MainActivity"

. (Join-Path $PSScriptRoot 'android-common.ps1')

$paths = Get-AndroidWorkspacePaths `
    -ProjectRoot $projectRoot `
    -FlutterRoot $flutterRoot `
    -AndroidSdkRoot $AndroidSdkRoot `
    -JavaHome $JavaHome `
    -AndroidWorkRoot $AndroidWorkRoot

Initialize-AndroidWorkspace -Paths $paths

$runStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$wrapperLog = Join-Path $paths.AndroidTemp "scheduled-notification-wrapper-$runStamp.log"

function Write-WrapperLog {
    param([string]$Message)

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $wrapperLog -Value "[$timestamp] $Message"
}

function Ensure-DeviceAwakeAndUnlocked {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    try {
        & $Paths.Adb -s $DeviceId shell input keyevent 224 *> $null
        & $Paths.Adb -s $DeviceId shell wm dismiss-keyguard *> $null
        & $Paths.Adb -s $DeviceId shell input swipe 540 1800 540 600 200 *> $null
    } catch {
        Write-WrapperLog "Failed to wake or unlock device: $($_.Exception.Message)"
    }
}

function Get-DisplaySnapshot {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    $dump = (& $Paths.Adb -s $DeviceId shell dumpsys power | Out-String)

    $interactiveMatch = [regex]::Match($dump, 'mWakefulness=\w+|Display Power: state=(\w+)|mInteractive=(true|false)')
    $displayStateMatch = [regex]::Match($dump, 'Display Power: state=(\w+)')
    $interactiveStateMatch = [regex]::Match($dump, 'mInteractive=(true|false)')

    $displayState = if ($displayStateMatch.Success) {
        $displayStateMatch.Groups[1].Value
    } else {
        'unknown'
    }

    $interactive = if ($interactiveStateMatch.Success) {
        [bool]::Parse($interactiveStateMatch.Groups[1].Value)
    } else {
        $false
    }

    return [pscustomobject]@{
        DisplayState = $displayState
        Interactive  = $interactive
        Raw          = $dump.Trim()
    }
}

function Ensure-DeviceScreenOff {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    & $Paths.Adb -s $DeviceId shell input keyevent 3 *> $null
    Start-Sleep -Milliseconds 500

    $snapshot = Get-DisplaySnapshot -Paths $Paths -DeviceId $DeviceId
    if ($snapshot.Interactive -or $snapshot.DisplayState -ne 'OFF') {
        & $Paths.Adb -s $DeviceId shell input keyevent 223 *> $null
    }

    $deadline = (Get-Date).AddSeconds(10)
    do {
        $snapshot = Get-DisplaySnapshot -Paths $Paths -DeviceId $DeviceId
        if (-not $snapshot.Interactive -or $snapshot.DisplayState -eq 'OFF') {
            Write-WrapperLog "Device screen is off. display=$($snapshot.DisplayState) interactive=$($snapshot.Interactive)"
            return $snapshot
        }

        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)

    throw "Unable to turn screen off. Final snapshot: display=$($snapshot.DisplayState) interactive=$($snapshot.Interactive)"
}

function Get-PermissionPromptTapPoint {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    try {
        & $Paths.Adb -s $DeviceId shell uiautomator dump /sdcard/uidump.xml 2>$null *> $null
    } catch {
        Write-WrapperLog "UI hierarchy dump failed: $($_.Exception.Message)"
        return $null
    }

    $xml = (& $Paths.Adb -s $DeviceId shell cat /sdcard/uidump.xml 2>$null) -join ''
    if (-not $xml) {
        return $null
    }

    $patterns = @(
        'resource-id="(?:com\.android\.permissioncontroller|com\.google\.android\.permissioncontroller|com\.android\.packageinstaller|com\.coloros\.securitypermission):id/permission_allow(?:_foreground_only)?_button"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',
        'resource-id="android:id/button1"[^>]*text="(?:Allow|ALLOW|อนุญาต|While using the app)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',
        'package="(?:com\.android\.permissioncontroller|com\.google\.android\.permissioncontroller|com\.android\.packageinstaller|com\.coloros\.securitypermission)"[^>]*text="(?:Allow|ALLOW|อนุญาต|While using the app)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
    )

    foreach ($pattern in $patterns) {
        $match = [regex]::Match($xml, $pattern)
        if ($match.Success) {
            $x = [int](($match.Groups[1].Value -as [int]) + (($match.Groups[3].Value -as [int]) - ($match.Groups[1].Value -as [int])) / 2)
            $y = [int](($match.Groups[2].Value -as [int]) + (($match.Groups[4].Value -as [int]) - ($match.Groups[2].Value -as [int])) / 2)
            return [pscustomobject]@{
                X = $x
                Y = $y
            }
        }
    }

    return $null
}

function Grant-NotificationPermission {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [string]$PackageName = 'com.lskram.officerelief'
    )

    try {
        $pmGrantOutput = (& $Paths.Adb -s $DeviceId shell pm grant $PackageName android.permission.POST_NOTIFICATIONS 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0) {
            Write-WrapperLog "pm grant succeeded for $PackageName."
        } elseif ($pmGrantOutput) {
            Write-WrapperLog "pm grant failed for ${PackageName}: $pmGrantOutput"
        }
    } catch {
        Write-WrapperLog "pm grant raised an exception for ${PackageName}: $($_.Exception.Message)"
    }

    try {
        $appOpsOutput = (& $Paths.Adb -s $DeviceId shell appops set $PackageName POST_NOTIFICATION allow 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0) {
            Write-WrapperLog "appops allow succeeded for $PackageName."
        } elseif ($appOpsOutput) {
            Write-WrapperLog "appops allow failed for ${PackageName}: $appOpsOutput"
        }
    } catch {
        Write-WrapperLog "appops allow raised an exception for ${PackageName}: $($_.Exception.Message)"
    }
}

function Get-PostedNotificationCount {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [string]$PackageName = 'com.lskram.officerelief'
    )

    $dump = (& $Paths.Adb -s $DeviceId shell dumpsys notification --noredact | Out-String)
    $pattern = "AggregatedStats\{\s*key='$([regex]::Escape($PackageName))'.*?numPostedByApp=(\d+)"
    $match = [regex]::Match(
        $dump,
        $pattern,
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    if (-not $match.Success) {
        return 0
    }

    return [int]$match.Groups[1].Value
}

function Read-ScheduleReadyMarker {
    param([string[]]$Lines)

    $joined = $Lines -join [Environment]::NewLine
    $match = [regex]::Match(
        $joined,
        'SCHEDULE_READY mode=(\w+) nextEpochMs=(\d+) nextIso=([^\s]+) exact=(true|false) fullScreen=(true|false) pending=(\d+) permission=(true|false|null)'
    )

    if (-not $match.Success) {
        return $null
    }

    return [pscustomobject]@{
        Mode        = $match.Groups[1].Value
        NextEpochMs = [int64]$match.Groups[2].Value
        NextIso     = $match.Groups[3].Value
        Exact       = [bool]::Parse($match.Groups[4].Value)
        FullScreen  = [bool]::Parse($match.Groups[5].Value)
        Pending     = [int]$match.Groups[6].Value
        Permission  = $match.Groups[7].Value
    }
}

function Read-DeviceMarker {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [string]$Prefix
    )

    $logcat = (& $Paths.Adb -s $DeviceId logcat -d | Out-String)
    $matches = [regex]::Matches($logcat, "$Prefix.*")
    if ($matches.Count -eq 0) {
        return $null
    }

    return $matches[$matches.Count - 1].Value.Trim()
}

function Read-DeviceScheduleReadyMarker {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    $line = Read-DeviceMarker -Paths $Paths -DeviceId $DeviceId -Prefix 'SCHEDULE_READY'
    if ($null -eq $line) {
        return $null
    }

    return Read-ScheduleReadyMarker -Lines @($line)
}

function Build-And-InstallDebugApp {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    Push-Location $Paths.ProjectRoot
    try {
        $targetPlatform = Resolve-AndroidDebugTargetPlatform -Paths $Paths -DeviceId $DeviceId
        Write-WrapperLog "Building debug APK for target platform $targetPlatform"
        & $Paths.FlutterBin build apk --debug --target-platform $targetPlatform --no-pub
        if ($LASTEXITCODE -ne 0) {
            throw 'flutter build apk --debug failed.'
        }

        & $Paths.Adb -s $DeviceId install -r 'build\app\outputs\flutter-apk\app-debug.apk'
        if ($LASTEXITCODE -ne 0) {
            throw 'adb install failed.'
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-ScheduledReminderAutomation {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [string]$Mode
    )

    Ensure-DeviceAwakeAndUnlocked -Paths $Paths -DeviceId $DeviceId
    & $Paths.Adb -s $DeviceId logcat -c *> $null
    & $Paths.Adb -s $DeviceId shell am force-stop $applicationId *> $null
    Grant-NotificationPermission -Paths $Paths -DeviceId $DeviceId -PackageName $applicationId

    $startOutput = & $Paths.Adb -s $DeviceId shell am start -W `
        -n $mainActivity `
        --es codexAction prepareScheduledReminder `
        --es alertMode $Mode `
        --ei intervalMinutes 1 `
        --ei delayMinutes 1 `
        --ei startHour 0 `
        --ei startMinute 0 `
        --ei endHour 23 `
        --ei endMinute 59
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to launch automation intent for mode '$Mode'."
    }
    $startOutput | Write-Host

    $deadline = (Get-Date).AddMinutes(2)
    do {
        Ensure-DeviceAwakeAndUnlocked -Paths $Paths -DeviceId $DeviceId
        Grant-NotificationPermission -Paths $Paths -DeviceId $DeviceId -PackageName $applicationId

        $tapPoint = Get-PermissionPromptTapPoint -Paths $Paths -DeviceId $DeviceId
        if ($tapPoint) {
            Write-Host "Allowing notification permission at [$($tapPoint.X),$($tapPoint.Y)]"
            Write-WrapperLog "Tapping allow button at [$($tapPoint.X),$($tapPoint.Y)]."
            & $Paths.Adb -s $DeviceId shell input tap $tapPoint.X $tapPoint.Y *> $null
            Start-Sleep -Seconds 2
        }

        $marker = Read-DeviceScheduleReadyMarker -Paths $Paths -DeviceId $DeviceId
        if ($null -ne $marker) {
            Write-WrapperLog "Detected device marker for ${Mode}: next=$($marker.NextIso), exact=$($marker.Exact), fullScreen=$($marker.FullScreen), pending=$($marker.Pending), permission=$($marker.Permission)"
            return $marker
        }

        Start-Sleep -Seconds 1
    } while ((Get-Date) -lt $deadline)

    $errorLine = Read-DeviceMarker -Paths $Paths -DeviceId $DeviceId -Prefix 'SCHEDULE_ERROR'
    if ($errorLine) {
        throw "Automation reported an error for mode '$Mode': $errorLine"
    }

    throw "Timed out waiting for SCHEDULE_READY from app automation for mode '$Mode'."
}

function Wait-ForPostedNotificationDelta {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [int]$BaselineCount,
        [datetime]$Deadline,
        [string]$Mode
    )

    do {
        $currentCount = Get-PostedNotificationCount -Paths $Paths -DeviceId $DeviceId
        if ($currentCount -gt $BaselineCount) {
            Write-WrapperLog "Detected notification post for $Mode. Baseline=$BaselineCount Current=$currentCount"
            return $currentCount
        }

        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $Deadline)

    $finalCount = Get-PostedNotificationCount -Paths $Paths -DeviceId $DeviceId
    throw "Timed out waiting for scheduled notification in mode '$Mode'. Baseline=$BaselineCount Final=$finalCount Deadline=$Deadline"
}

function Read-NotificationRecordSnapshot {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [string]$PackageName = 'com.lskram.officerelief'
    )

    $dump = (& $Paths.Adb -s $DeviceId shell dumpsys notification --noredact | Out-String)
    $pattern = "NotificationRecord\{.*?$([regex]::Escape($PackageName)).*?(?=NotificationRecord\{|$)"
    $matches = [regex]::Matches(
        $dump,
        $pattern,
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    if ($matches.Count -eq 0) {
        return $null
    }

    return $matches[$matches.Count - 1].Value.Trim()
}

try {
    Write-WrapperLog 'Wrapper script started.'
    Build-And-InstallDebugApp -Paths $paths -DeviceId $DeviceId
    Grant-NotificationPermission -Paths $paths -DeviceId $DeviceId -PackageName $applicationId

    $modes = @('notification', 'exact', 'exactFullScreen')
    foreach ($mode in $modes) {
        Write-Host "=== Verifying scheduled notifications for mode: $mode ==="
        Write-WrapperLog "Verifying scheduled notifications for mode: $mode"

        $baselineCount = Get-PostedNotificationCount -Paths $paths -DeviceId $DeviceId -PackageName $applicationId
        Write-WrapperLog "Baseline numPostedByApp for ${mode}: $baselineCount"

        $marker = Invoke-ScheduledReminderAutomation -Paths $paths -DeviceId $DeviceId -Mode $mode

        & $paths.Adb -s $DeviceId shell input keyevent 3 *> $null
        Start-Sleep -Seconds 1

        if ($ScreenOff) {
            $preWaitSnapshot = Ensure-DeviceScreenOff -Paths $paths -DeviceId $DeviceId
            Write-WrapperLog (
                "Screen-off verification armed for $mode. " +
                "display=$($preWaitSnapshot.DisplayState) interactive=$($preWaitSnapshot.Interactive)"
            )
        }

        $nextReminderAt = [DateTimeOffset]::FromUnixTimeMilliseconds($marker.NextEpochMs).LocalDateTime
        $graceSeconds = if ($marker.Exact) { 90 } else { 180 }
        $deadline = $nextReminderAt.AddSeconds($graceSeconds)
        Write-WrapperLog "Waiting for scheduled post for $mode until $deadline"

        $finalCount = Wait-ForPostedNotificationDelta `
            -Paths $paths `
            -DeviceId $DeviceId `
            -BaselineCount $baselineCount `
            -Deadline $deadline `
            -Mode $mode

        $postWaitSnapshot = Get-DisplaySnapshot -Paths $paths -DeviceId $DeviceId
        $notificationRecord = Read-NotificationRecordSnapshot -Paths $paths -DeviceId $DeviceId -PackageName $applicationId
        Write-WrapperLog (
            "Post-fire snapshot for ${mode}: " +
            "display=$($postWaitSnapshot.DisplayState) interactive=$($postWaitSnapshot.Interactive)"
        )
        if ($notificationRecord) {
            Write-WrapperLog "Notification record for ${mode}: $notificationRecord"
        }

        Write-Host (
            "SCHEDULE_RESULT mode=$mode baseline=$baselineCount final=$finalCount " +
            "delta=$($finalCount - $baselineCount) next=$($marker.NextIso) " +
            "exact=$($marker.Exact) fullScreen=$($marker.FullScreen) pending=$($marker.Pending) " +
            "screenOff=$($ScreenOff.IsPresent) display=$($postWaitSnapshot.DisplayState) interactive=$($postWaitSnapshot.Interactive)"
        )

        if ($ScreenOff) {
            Ensure-DeviceAwakeAndUnlocked -Paths $paths -DeviceId $DeviceId
        }
    }

    Write-WrapperLog 'Wrapper script completed successfully.'
} catch {
    Write-WrapperLog "Wrapper script failed: $($_.Exception.Message)"
    throw
}
