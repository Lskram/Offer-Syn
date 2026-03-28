param(
    [string]$DeviceId = 'f4da450d',
    [string]$AndroidWorkRoot = 'D:\Android',
    [string]$AndroidSdkRoot = 'C:\Users\UsEr\AppData\Local\Android\Sdk',
    [string]$JavaHome = 'D:\Android Studio\jbr'
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
$logRoot = Join-Path $projectRoot 'artifacts\device-test-logs'
if (-not (Test-Path $logRoot)) {
    New-Item -ItemType Directory -Force $logRoot | Out-Null
}
$wrapperLog = Join-Path $logRoot "full-screen-screen-states-wrapper-$runStamp.log"

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
        'resource-id="android:id/button1"[^>]*text="(?:Allow|ALLOW|While using the app)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',
        'package="(?:com\.android\.permissioncontroller|com\.google\.android\.permissioncontroller|com\.android\.packageinstaller|com\.coloros\.securitypermission)"[^>]*text="(?:Allow|ALLOW|While using the app)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
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
        & $Paths.Adb -s $DeviceId shell pm grant $PackageName android.permission.POST_NOTIFICATIONS *> $null
    } catch {
        Write-WrapperLog "pm grant raised an exception for ${PackageName}: $($_.Exception.Message)"
    }

    try {
        & $Paths.Adb -s $DeviceId shell appops set $PackageName POST_NOTIFICATION allow *> $null
    } catch {
        Write-WrapperLog "appops allow raised an exception for ${PackageName}: $($_.Exception.Message)"
    }
}

function Build-And-InstallDebugApp {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    Push-Location $Paths.ProjectRoot
    try {
        & $Paths.FlutterBin build apk --debug --target-platform android-arm64 --no-pub
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

function Read-ArmedMarker {
    param([string]$Line)

    $match = [regex]::Match(
        $Line,
        'IMMEDIATE_ARMED mode=(\w+) fireEpochMs=(\d+) fireIso=([^\s]+) exact=(true|false) fullScreen=(true|false) permission=(true|false|null)'
    )

    if (-not $match.Success) {
        return $null
    }

    return [pscustomobject]@{
        Mode       = $match.Groups[1].Value
        FireEpochMs = [int64]$match.Groups[2].Value
        FireIso    = $match.Groups[3].Value
        Exact      = [bool]::Parse($match.Groups[4].Value)
        FullScreen = [bool]::Parse($match.Groups[5].Value)
        Permission = $match.Groups[6].Value
    }
}

function Read-ImmediateReadyMarker {
    param([string]$Line)

    $match = [regex]::Match(
        $Line,
        'IMMEDIATE_READY mode=(\w+) exact=(true|false) fullScreen=(true|false) permission=(true|false|null) category=([^\s]+) hasFullScreenIntent=(true|false) title=([^\s]+)'
    )

    if (-not $match.Success) {
        return $null
    }

    return [pscustomobject]@{
        Mode                = $match.Groups[1].Value
        Exact               = [bool]::Parse($match.Groups[2].Value)
        FullScreen          = [bool]::Parse($match.Groups[3].Value)
        Permission          = $match.Groups[4].Value
        Category            = $match.Groups[5].Value
        HasFullScreenIntent = [bool]::Parse($match.Groups[6].Value)
        Title               = $match.Groups[7].Value
    }
}

function Read-ImmediateErrorMarker {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    return Read-DeviceMarker -Paths $Paths -DeviceId $DeviceId -Prefix 'IMMEDIATE_ERROR'
}

function Invoke-ArmImmediateNotification {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [int]$DelaySeconds = 8
    )

    Ensure-DeviceAwakeAndUnlocked -Paths $Paths -DeviceId $DeviceId
    & $Paths.Adb -s $DeviceId logcat -c *> $null
    & $Paths.Adb -s $DeviceId shell am force-stop $applicationId *> $null
    Grant-NotificationPermission -Paths $Paths -DeviceId $DeviceId -PackageName $applicationId

    $startOutput = & $Paths.Adb -s $DeviceId shell am start -W `
        -n $mainActivity `
        --es codexAction armImmediateNotification `
        --es alertMode exactFullScreen `
        --ei intervalMinutes 1 `
        --ei delayMinutes 1 `
        --ei delaySeconds $DelaySeconds `
        --ei startHour 0 `
        --ei startMinute 0 `
        --ei endHour 23 `
        --ei endMinute 59
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to launch armImmediateNotification automation.'
    }
    $startOutput | Write-Host

    $deadline = (Get-Date).AddMinutes(1)
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

        $line = Read-DeviceMarker -Paths $Paths -DeviceId $DeviceId -Prefix 'IMMEDIATE_ARMED'
        if ($line) {
            $marker = Read-ArmedMarker -Line $line
            if ($null -ne $marker -and $marker.Mode -eq 'exactFullScreen') {
                Write-WrapperLog "Detected armed marker: $line"
                return $marker
            }
        }

        Start-Sleep -Seconds 1
    } while ((Get-Date) -lt $deadline)

    throw 'Timed out waiting for IMMEDIATE_ARMED.'
}

function Wait-ForImmediateReady {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [datetime]$Deadline
    )

    do {
        $line = Read-DeviceMarker -Paths $Paths -DeviceId $DeviceId -Prefix 'IMMEDIATE_READY'
        if ($line) {
            $marker = Read-ImmediateReadyMarker -Line $line
            if ($null -ne $marker -and $marker.Mode -eq 'exactFullScreen') {
                Write-WrapperLog "Detected immediate ready marker: $line"
                return $marker
            }
        }

        $errorLine = Read-ImmediateErrorMarker -Paths $Paths -DeviceId $DeviceId
        if ($errorLine -and $errorLine -match 'mode=exactFullScreen') {
            throw "Automation reported an error: $errorLine"
        }

        Start-Sleep -Seconds 1
    } while ((Get-Date) -lt $Deadline)

    throw 'Timed out waiting for IMMEDIATE_READY.'
}

function Get-DisplaySnapshot {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    $dump = (& $Paths.Adb -s $DeviceId shell dumpsys power | Out-String)

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
    & $Paths.Adb -s $DeviceId shell input keyevent 223 *> $null

    $deadline = (Get-Date).AddSeconds(10)
    do {
        $snapshot = Get-DisplaySnapshot -Paths $Paths -DeviceId $DeviceId
        if (-not $snapshot.Interactive -or $snapshot.DisplayState -eq 'OFF') {
            Write-WrapperLog "Device screen is off. display=$($snapshot.DisplayState) interactive=$($snapshot.Interactive)"
            return $snapshot
        }

        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)

    throw 'Unable to turn screen off.'
}

function Get-ActivityDump {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    return (& $Paths.Adb -s $DeviceId shell dumpsys activity activities | Out-String)
}

function Save-Screenshot {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [string]$Name
    )

    $remote = "/sdcard/$Name"
    $local = Join-Path $Paths.ProjectRoot "artifacts\$Name"
    & $Paths.Adb -s $DeviceId shell screencap -p $remote *> $null
    try {
        & $Paths.Adb -s $DeviceId pull $remote $local *> $null
    } catch {
        if (-not (Test-Path $local)) {
            throw
        }
    }
    return $local
}

function Assert-FullScreenMarkers {
    param(
        [pscustomobject]$ArmedMarker,
        [pscustomobject]$ReadyMarker
    )

    if (-not $ArmedMarker.Exact -or -not $ArmedMarker.FullScreen -or $ArmedMarker.Permission -ne 'true') {
        throw "Armed marker was invalid: $($ArmedMarker | ConvertTo-Json -Compress)"
    }

    if (-not $ReadyMarker.Exact -or -not $ReadyMarker.FullScreen -or $ReadyMarker.Permission -ne 'true' -or $ReadyMarker.Category -ne 'alarm' -or -not $ReadyMarker.HasFullScreenIntent) {
        throw "Ready marker was invalid: $($ReadyMarker | ConvertTo-Json -Compress)"
    }
}

function Wait-ForPostedNotificationDelta {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [int]$BaselineCount,
        [datetime]$Deadline
    )

    do {
        $currentCount = Get-PostedNotificationCount -Paths $Paths -DeviceId $DeviceId
        if ($currentCount -gt $BaselineCount) {
            return $currentCount
        }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $Deadline)

    $finalCount = Get-PostedNotificationCount -Paths $Paths -DeviceId $DeviceId
    throw "Timed out waiting for full-screen notification post. Baseline=$BaselineCount Final=$finalCount"
}

function Invoke-FullScreenScenario {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [string]$Scenario
    )

    $baselineCount = Get-PostedNotificationCount -Paths $Paths -DeviceId $DeviceId -PackageName $applicationId
    $armed = Invoke-ArmImmediateNotification -Paths $Paths -DeviceId $DeviceId -DelaySeconds 8

    if ($Scenario -eq 'screenOnHome') {
        & $Paths.Adb -s $DeviceId shell input keyevent 3 *> $null
        Start-Sleep -Seconds 1
    } elseif ($Scenario -eq 'screenOff') {
        $null = Ensure-DeviceScreenOff -Paths $Paths -DeviceId $DeviceId
    } else {
        throw "Unknown scenario '$Scenario'."
    }

    $fireAt = [DateTimeOffset]::FromUnixTimeMilliseconds($armed.FireEpochMs).LocalDateTime
    $deadline = $fireAt.AddSeconds(20)
    $ready = Wait-ForImmediateReady -Paths $Paths -DeviceId $DeviceId -Deadline $deadline
    Assert-FullScreenMarkers -ArmedMarker $armed -ReadyMarker $ready
    $finalCount = Wait-ForPostedNotificationDelta -Paths $Paths -DeviceId $DeviceId -BaselineCount $baselineCount -Deadline $deadline

    $powerSnapshot = Get-DisplaySnapshot -Paths $Paths -DeviceId $DeviceId
    $activityDump = Get-ActivityDump -Paths $Paths -DeviceId $DeviceId
    $screenshotName = if ($Scenario -eq 'screenOnHome') {
        'full-screen-screen-on-home.png'
    } else {
        'full-screen-screen-off.png'
    }
    $screenshot = Save-Screenshot -Paths $Paths -DeviceId $DeviceId -Name $screenshotName

    $containsAlarmActivity = $activityDump -match 'com\.lskram\.officerelief/\.AlarmActivity'
    if ($Scenario -eq 'screenOff' -and -not $containsAlarmActivity) {
        throw "AlarmActivity was not present in the activity dump for scenario '$Scenario'."
    }

    Write-Host (
        "FULL_SCREEN_RESULT scenario=$Scenario baseline=$baselineCount final=$finalCount " +
        "delta=$($finalCount - $baselineCount) fireAt=$($armed.FireIso) " +
        "interactive=$($powerSnapshot.Interactive) display=$($powerSnapshot.DisplayState) " +
        "alarmActivity=$containsAlarmActivity screenshot=$screenshot"
    )
}

try {
    Write-WrapperLog 'Wrapper script started.'
    Build-And-InstallDebugApp -Paths $paths -DeviceId $DeviceId
    Grant-NotificationPermission -Paths $paths -DeviceId $DeviceId -PackageName $applicationId

    Invoke-FullScreenScenario -Paths $paths -DeviceId $DeviceId -Scenario 'screenOnHome'
    Invoke-FullScreenScenario -Paths $paths -DeviceId $DeviceId -Scenario 'screenOff'

    Write-WrapperLog 'Wrapper script completed successfully.'
} catch {
    Write-WrapperLog "Wrapper script failed: $($_.Exception.Message)"
    throw
}
