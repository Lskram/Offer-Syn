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

. (Join-Path $PSScriptRoot 'android-common.ps1')

$paths = Get-AndroidWorkspacePaths `
    -ProjectRoot $projectRoot `
    -FlutterRoot $flutterRoot `
    -AndroidSdkRoot $AndroidSdkRoot `
    -JavaHome $JavaHome `
    -AndroidWorkRoot $AndroidWorkRoot

Initialize-AndroidWorkspace -Paths $paths

$runStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$wrapperLog = Join-Path $paths.AndroidTemp "full-screen-screen-states-wrapper-$runStamp.log"
$stdout = Join-Path $paths.AndroidTemp "full-screen-screen-states-$runStamp.stdout.log"
$stderr = Join-Path $paths.AndroidTemp "full-screen-screen-states-$runStamp.stderr.log"

function Write-WrapperLog {
    param([string]$Message)

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $wrapperLog -Value "[$timestamp] $Message"
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
        'resource-id="android:id/button1"[^>]*text="(?:Allow|ALLOW|อนุญาต|While using the app|ขณะใช้แอป|ขณะใช้งานแอป)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',
        'package="(?:com\.android\.permissioncontroller|com\.google\.android\.permissioncontroller|com\.android\.packageinstaller|com\.coloros\.securitypermission)"[^>]*text="(?:Allow|ALLOW|อนุญาต|While using the app|ขณะใช้แอป|ขณะใช้งานแอป)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
    )

    foreach ($pattern in $patterns) {
        $match = [regex]::Match($xml, $pattern)
        if ($match.Success) {
            $x = [int](($match.Groups[1].Value -as [int]) + (($match.Groups[3].Value -as [int]) - ($match.Groups[1].Value -as [int])) / 2)
            $y = [int](($match.Groups[2].Value -as [int]) + (($match.Groups[4].Value -as [int]) - ($match.Groups[2].Value -as [int])) / 2)
            return [pscustomobject]@{ X = $x; Y = $y }
        }
    }

    return $null
}

function Read-StdoutLines {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return @()
    }

    return Get-Content $Path
}

function Get-TopActivity {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    return (& $Paths.Adb -s $DeviceId shell dumpsys activity activities | Select-String -Pattern 'mResumedActivity').ToString().Trim()
}

function Get-Wakefulness {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    return (& $Paths.Adb -s $DeviceId shell dumpsys power | Select-String -Pattern 'mWakefulness=').ToString().Trim()
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
    & $Paths.Adb -s $DeviceId pull $remote $local *> $null
    return $local
}

function Invoke-FullScreenStateTest {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    $flutterCommand = "`"$($Paths.FlutterBin)`" test integration_test\full_screen_screen_states_device_test.dart -d $DeviceId --no-pub"
    Write-WrapperLog "Starting flutter integration test: $flutterCommand"
    $process = Start-Process `
        -FilePath 'cmd.exe' `
        -ArgumentList @('/c', $flutterCommand) `
        -WorkingDirectory $Paths.ProjectRoot `
        -NoNewWindow `
        -PassThru `
        -RedirectStandardOutput $stdout `
        -RedirectStandardError $stderr

    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $screenOnSummary = ''
    $screenOffSummary = ''
    $screenOnWakefulness = ''
    $screenOffWakefulness = ''
    $permissionHandled = $false
    $screenOnCaptureAt = $null
    $screenOffCaptureAt = $null
    $screenOnCaptured = $false
    $screenOffCaptured = $false

    while (-not $process.HasExited) {
        if (-not $permissionHandled) {
            $tapPoint = Get-PermissionPromptTapPoint -Paths $Paths -DeviceId $DeviceId
            if ($tapPoint) {
                Write-Host "Allowing notification permission at [$($tapPoint.X),$($tapPoint.Y)]"
                Write-WrapperLog "Tapping allow button at [$($tapPoint.X),$($tapPoint.Y)]."
                & $Paths.Adb -s $DeviceId shell input tap $tapPoint.X $tapPoint.Y *> $null
                $permissionHandled = $true
                Start-Sleep -Seconds 2
            }
        }

        if ($screenOnCaptureAt -and -not $screenOnCaptured -and (Get-Date) -ge $screenOnCaptureAt) {
            try {
                $screenOnSummary = Get-TopActivity -Paths $Paths -DeviceId $DeviceId
                $screenOnWakefulness = Get-Wakefulness -Paths $Paths -DeviceId $DeviceId
                $null = Save-Screenshot -Paths $Paths -DeviceId $DeviceId -Name 'full-screen-screen-on-home.png'
                Write-WrapperLog "Screen-on result: $screenOnSummary | $screenOnWakefulness"
            } catch {
                Write-WrapperLog "Failed to capture screen-on result: $($_.Exception.Message)"
            }
            $screenOnCaptured = $true
        }

        if ($screenOffCaptureAt -and -not $screenOffCaptured -and (Get-Date) -ge $screenOffCaptureAt) {
            try {
                $screenOffSummary = Get-TopActivity -Paths $Paths -DeviceId $DeviceId
                $screenOffWakefulness = Get-Wakefulness -Paths $Paths -DeviceId $DeviceId
                $null = Save-Screenshot -Paths $Paths -DeviceId $DeviceId -Name 'full-screen-screen-off.png'
                Write-WrapperLog "Screen-off result: $screenOffSummary | $screenOffWakefulness"
            } catch {
                Write-WrapperLog "Failed to capture screen-off result: $($_.Exception.Message)"
            } finally {
                & $Paths.Adb -s $DeviceId shell input keyevent 26 *> $null
            }
            $screenOffCaptured = $true
        }

        foreach ($line in Read-StdoutLines -Path $stdout) {
            if (-not $seen.Add($line)) {
                continue
            }

            if ($line -match 'READY_SCREEN_ON_HOME') {
                Write-WrapperLog 'Received READY_SCREEN_ON_HOME. Sending HOME key.'
                & $Paths.Adb -s $DeviceId shell input keyevent 3 *> $null
                $screenOnCaptureAt = (Get-Date).AddSeconds(10)
            } elseif ($line -match 'READY_SCREEN_OFF') {
                Write-WrapperLog 'Received READY_SCREEN_OFF. Turning screen off.'
                & $Paths.Adb -s $DeviceId shell input keyevent 26 *> $null
                $screenOffCaptureAt = (Get-Date).AddSeconds(10)
            }
        }

        Start-Sleep -Seconds 1
    }

    $process.WaitForExit()
    $output = if (Test-Path $stdout) { Get-Content $stdout } else { @() }
    $errorOutput = if (Test-Path $stderr) { Get-Content $stderr } else { @() }

    if ($output) { $output | Write-Host }
    if ($errorOutput) { $errorOutput | Write-Host }

    $testsPassed = ($output -join [Environment]::NewLine) -match 'All tests passed!'
    if (-not $testsPassed) {
        throw 'Full-screen screen-state integration test did not pass.'
    }

    Write-Host "SCREEN_ON_TOP=$screenOnSummary"
    Write-Host "SCREEN_ON_WAKE=$screenOnWakefulness"
    Write-Host "SCREEN_OFF_TOP=$screenOffSummary"
    Write-Host "SCREEN_OFF_WAKE=$screenOffWakefulness"
}

Invoke-FullScreenStateTest -Paths $paths -DeviceId $DeviceId
