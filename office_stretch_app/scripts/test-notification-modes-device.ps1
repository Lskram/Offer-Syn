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
$wrapperLog = Join-Path $logRoot "notification-modes-wrapper-$runStamp.log"

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

function Invoke-ImmediateNotificationAutomation {
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
        --es codexAction postImmediateNotification `
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

        $line = Read-DeviceMarker -Paths $Paths -DeviceId $DeviceId -Prefix 'IMMEDIATE_READY'
        if ($line) {
            $marker = Read-ImmediateReadyMarker -Line $line
            if ($null -ne $marker -and $marker.Mode -eq $Mode) {
                Write-WrapperLog "Detected immediate marker for ${Mode}: $line"
                return $marker
            }
        }

        $errorLine = Read-ImmediateErrorMarker -Paths $Paths -DeviceId $DeviceId
        if ($errorLine -and $errorLine -match "mode=$Mode") {
            throw "Automation reported an error for mode '$Mode': $errorLine"
        }

        Start-Sleep -Seconds 1
    } while ((Get-Date) -lt $deadline)

    throw "Timed out waiting for IMMEDIATE_READY from app automation for mode '$Mode'."
}

function Wait-ForPostedNotificationDelta {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [int]$BaselineCount,
        [string]$Mode
    )

    $deadline = (Get-Date).AddSeconds(20)
    do {
        $currentCount = Get-PostedNotificationCount -Paths $Paths -DeviceId $DeviceId
        if ($currentCount -gt $BaselineCount) {
            return $currentCount
        }

        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)

    $finalCount = Get-PostedNotificationCount -Paths $Paths -DeviceId $DeviceId
    throw "Timed out waiting for posted notification delta in mode '$Mode'. Baseline=$BaselineCount Final=$finalCount"
}

function Assert-MarkerMatchesMode {
    param([pscustomobject]$Marker)

    switch ($Marker.Mode) {
        'notification' {
            if ($Marker.Exact -or $Marker.FullScreen -or $Marker.Category -ne 'reminder' -or $Marker.HasFullScreenIntent) {
                throw "Notification mode marker was invalid: $($Marker | ConvertTo-Json -Compress)"
            }
        }
        'exact' {
            if (-not $Marker.Exact -or $Marker.FullScreen -or $Marker.Category -ne 'alarm' -or $Marker.HasFullScreenIntent) {
                throw "Exact mode marker was invalid: $($Marker | ConvertTo-Json -Compress)"
            }
        }
        'exactFullScreen' {
            if (-not $Marker.Exact -or -not $Marker.FullScreen -or $Marker.Category -ne 'alarm' -or -not $Marker.HasFullScreenIntent) {
                throw "Exact full-screen marker was invalid: $($Marker | ConvertTo-Json -Compress)"
            }
        }
        default {
            throw "Unknown mode in marker: $($Marker.Mode)"
        }
    }

    if ($Marker.Permission -ne 'true') {
        throw "Notification permission was not enabled during mode '$($Marker.Mode)'."
    }
}

try {
    Write-WrapperLog 'Wrapper script started.'
    Build-And-InstallDebugApp -Paths $paths -DeviceId $DeviceId
    Grant-NotificationPermission -Paths $paths -DeviceId $DeviceId -PackageName $applicationId

    $modes = @('notification', 'exact', 'exactFullScreen')
    foreach ($mode in $modes) {
        Write-Host "=== Verifying notification mode: $mode ==="
        Write-WrapperLog "Verifying notification mode: $mode"

        $baselineCount = Get-PostedNotificationCount -Paths $paths -DeviceId $DeviceId -PackageName $applicationId
        $marker = Invoke-ImmediateNotificationAutomation -Paths $paths -DeviceId $DeviceId -Mode $mode
        Assert-MarkerMatchesMode -Marker $marker
        $finalCount = Wait-ForPostedNotificationDelta -Paths $paths -DeviceId $DeviceId -BaselineCount $baselineCount -Mode $mode

        Write-Host (
            "IMMEDIATE_RESULT mode=$mode baseline=$baselineCount final=$finalCount " +
            "delta=$($finalCount - $baselineCount) exact=$($marker.Exact) " +
            "fullScreen=$($marker.FullScreen) category=$($marker.Category) " +
            "hasFullScreenIntent=$($marker.HasFullScreenIntent) title=$($marker.Title)"
        )
        Write-WrapperLog "Immediate mode result for ${mode}: $($marker | ConvertTo-Json -Compress)"
    }

    Write-WrapperLog 'Wrapper script completed successfully.'
} catch {
    Write-WrapperLog "Wrapper script failed: $($_.Exception.Message)"
    throw
}
