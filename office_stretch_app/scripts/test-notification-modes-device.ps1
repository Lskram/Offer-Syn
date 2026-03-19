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

$wrapperLog = Join-Path $paths.AndroidTemp 'notification-modes-wrapper.log'
Remove-Item $wrapperLog -Force -ErrorAction SilentlyContinue

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

    Write-WrapperLog 'Polling UI hierarchy for permission prompt.'
    try {
        & $Paths.Adb -s $DeviceId shell uiautomator dump /sdcard/uidump.xml 2>$null *> $null
    } catch {
        Write-WrapperLog "UI hierarchy dump failed: $($_.Exception.Message)"
        return $null
    }

    $xml = (& $Paths.Adb -s $DeviceId shell cat /sdcard/uidump.xml 2>$null) -join ''
    if (-not $xml) {
        Write-WrapperLog 'UI hierarchy was empty.'
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
            Write-WrapperLog "Detected permission prompt with tap target [$x,$y]."
            return [pscustomobject]@{
                X = $x
                Y = $y
            }
        }
    }

    Write-WrapperLog 'No permission prompt detected in current hierarchy.'
    return $null
}

function Invoke-NotificationModeDeviceTest {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId
    )

    $stdout = Join-Path $Paths.AndroidTemp 'notification-modes.stdout.log'
    $stderr = Join-Path $Paths.AndroidTemp 'notification-modes.stderr.log'
    Remove-Item $stdout, $stderr -Force -ErrorAction SilentlyContinue

    $flutterCommand = "`"$($Paths.FlutterBin)`" test integration_test\notification_modes_device_test.dart -d $DeviceId --no-pub"
    Write-WrapperLog "Starting flutter integration test: $flutterCommand"
    $process = Start-Process `
        -FilePath 'cmd.exe' `
        -ArgumentList @('/c', $flutterCommand) `
        -WorkingDirectory $Paths.ProjectRoot `
        -NoNewWindow `
        -PassThru `
        -RedirectStandardOutput $stdout `
        -RedirectStandardError $stderr

    $grantedPrompt = $false

    while (-not $process.HasExited) {
        Write-WrapperLog 'Integration test still running.'
        $tapPoint = Get-PermissionPromptTapPoint -Paths $Paths -DeviceId $DeviceId
        if ($tapPoint) {
            Write-Host "Allowing notification permission at [$($tapPoint.X),$($tapPoint.Y)]"
            Write-WrapperLog "Tapping allow button at [$($tapPoint.X),$($tapPoint.Y)]."
            & $Paths.Adb -s $DeviceId shell input tap $tapPoint.X $tapPoint.Y *> $null
            $grantedPrompt = $true
            Start-Sleep -Seconds 2
            continue
        }

        Start-Sleep -Seconds 1
    }

    Write-WrapperLog "Integration test process exited with code $($process.ExitCode)."
    $process.WaitForExit()
    $output = if (Test-Path $stdout) { Get-Content $stdout } else { @() }
    $errorOutput = if (Test-Path $stderr) { Get-Content $stderr } else { @() }

    if ($output) {
        $output | Write-Host
    }
    if ($errorOutput) {
        $errorOutput | Write-Host
    }

    $testsPassed = ($output -join [Environment]::NewLine) -match 'All tests passed!'
    if ($testsPassed) {
        Write-WrapperLog 'Detected successful test completion from stdout.'
        return
    }

    if ($process.ExitCode -ne 0) {
        Write-WrapperLog "Throwing failure. Permission prompt handled: $grantedPrompt"
        throw "Notification mode integration test failed. Permission prompt handled: $grantedPrompt"
    }
}

try {
    Write-WrapperLog 'Wrapper script started.'
    Invoke-NotificationModeDeviceTest -Paths $paths -DeviceId $DeviceId
    Write-WrapperLog 'Wrapper script completed successfully.'
} catch {
    Write-WrapperLog "Wrapper script failed: $($_.Exception.Message)"
    throw
}
