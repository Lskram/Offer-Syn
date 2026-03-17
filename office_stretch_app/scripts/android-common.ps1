Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-AndroidWorkspacePaths {
    param(
        [string]$ProjectRoot,
        [string]$FlutterRoot,
        [string]$AndroidSdkRoot,
        [string]$JavaHome,
        [string]$AndroidWorkRoot
    )

    $workspaceRoot = Split-Path -Parent $ProjectRoot

    return [pscustomobject]@{
        ProjectRoot              = $ProjectRoot
        WorkspaceRoot            = $workspaceRoot
        FlutterRoot              = $FlutterRoot
        FlutterBin               = Join-Path $FlutterRoot 'bin\flutter.bat'
        AndroidSdkRoot           = $AndroidSdkRoot
        JavaHome                 = $JavaHome
        AndroidWorkRoot          = $AndroidWorkRoot
        AndroidAvdHome           = Join-Path $AndroidWorkRoot 'avd'
        AndroidTemp              = Join-Path $AndroidWorkRoot 'tmp'
        GradleUserHome           = Join-Path $AndroidWorkRoot 'gradle-home'
        SdkRedirectRoot          = Join-Path $AndroidWorkRoot 'sdk-redir'
        BuildDirRedirect         = Join-Path $AndroidWorkRoot 'office_stretch_app_build'
        AppDataRoot              = Join-Path $workspaceRoot '.appdata'
        Emulator                 = Join-Path $AndroidSdkRoot 'emulator\emulator.exe'
        Adb                      = Join-Path $AndroidSdkRoot 'platform-tools\adb.exe'
        BuildDir                 = Join-Path $ProjectRoot 'build'
        SdkNdk                   = Join-Path $AndroidSdkRoot 'ndk'
        SdkTemp                  = Join-Path $AndroidSdkRoot '.temp'
        SdkDownloadIntermediates = Join-Path $AndroidSdkRoot '.downloadIntermediates'
    }
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force $Path | Out-Null
    }
}

function Ensure-Junction {
    param(
        [string]$Path,
        [string]$Target
    )

    Ensure-Directory $Target

    if (Test-Path $Path) {
        $item = Get-Item $Path -Force
        if ($item.LinkType -eq 'Junction' -and $item.Target -contains $Target) {
            return
        }

        Remove-Item $Path -Recurse -Force
    }

    New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null
}

function Initialize-AndroidWorkspace {
    param([pscustomobject]$Paths)

    Ensure-Directory $Paths.AndroidWorkRoot
    Ensure-Directory $Paths.AndroidAvdHome
    Ensure-Directory $Paths.AndroidTemp
    Ensure-Directory $Paths.GradleUserHome
    Ensure-Directory $Paths.AppDataRoot
    Ensure-Directory (Join-Path $Paths.AppDataRoot 'roaming')
    Ensure-Directory (Join-Path $Paths.AppDataRoot 'local')
    Ensure-Directory (Join-Path $Paths.AppDataRoot 'pub-cache')
    Ensure-Directory $Paths.SdkRedirectRoot

    Ensure-Junction -Path $Paths.SdkNdk -Target (Join-Path $Paths.SdkRedirectRoot 'ndk')
    Ensure-Junction -Path $Paths.SdkTemp -Target (Join-Path $Paths.SdkRedirectRoot '.temp')
    Ensure-Junction `
        -Path $Paths.SdkDownloadIntermediates `
        -Target (Join-Path $Paths.SdkRedirectRoot '.downloadIntermediates')
    Ensure-Junction -Path $Paths.BuildDir -Target $Paths.BuildDirRedirect

    $env:JAVA_HOME = $Paths.JavaHome
    $env:ANDROID_AVD_HOME = $Paths.AndroidAvdHome
    $env:TEMP = $Paths.AndroidTemp
    $env:TMP = $Paths.AndroidTemp
    $env:GRADLE_USER_HOME = $Paths.GradleUserHome
    $env:APPDATA = Join-Path $Paths.AppDataRoot 'roaming'
    $env:LOCALAPPDATA = Join-Path $Paths.AppDataRoot 'local'
    $env:PUB_CACHE = Join-Path $Paths.AppDataRoot 'pub-cache'
    $env:GIT_CONFIG_GLOBAL = Join-Path $Paths.AppDataRoot 'gitconfig'
    $env:FLUTTER_SUPPRESS_ANALYTICS = 'true'

    if (-not (Test-Path $env:GIT_CONFIG_GLOBAL)) {
        New-Item -ItemType File -Force $env:GIT_CONFIG_GLOBAL | Out-Null
    }

    $safeDirectory = $Paths.FlutterRoot.Replace('\', '/')
    & git config --file $env:GIT_CONFIG_GLOBAL --add safe.directory $safeDirectory
}

function Get-BootedEmulatorDeviceId {
    param([pscustomobject]$Paths)

    $lines = & $Paths.Adb devices
    foreach ($line in $lines) {
        if ($line -match '^(emulator-\d+)\s+device$') {
            return $Matches[1]
        }
    }

    return $null
}

function Wait-ForAndroidBoot {
    param(
        [pscustomobject]$Paths,
        [int]$TimeoutSeconds = 240
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    do {
        $deviceId = Get-BootedEmulatorDeviceId -Paths $Paths
        if ($deviceId) {
            $bootStatus = (& $Paths.Adb -s $deviceId shell getprop sys.boot_completed 2>$null).Trim()
            if ($bootStatus -eq '1') {
                return $deviceId
            }
        }

        Start-Sleep -Seconds 5
    } while ((Get-Date) -lt $deadline)

    throw 'Android emulator did not finish booting within the timeout.'
}

function Ensure-AndroidEmulator {
    param(
        [pscustomobject]$Paths,
        [string]$AvdName,
        [int]$TimeoutSeconds = 240
    )

    $deviceId = Get-BootedEmulatorDeviceId -Paths $Paths
    if (-not $deviceId) {
        Write-Host "Starting emulator $AvdName..."
        Start-Process `
            -FilePath $Paths.Emulator `
            -ArgumentList "-avd $AvdName -no-snapshot-load -gpu swiftshader_indirect"
    }

    return Wait-ForAndroidBoot -Paths $Paths -TimeoutSeconds $TimeoutSeconds
}

function Build-Install-And-LaunchApp {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [string]$ApplicationId = 'com.example.office_stretch_app'
    )

    Push-Location $Paths.ProjectRoot
    try {
        & $Paths.FlutterBin build apk --debug --no-pub
        if ($LASTEXITCODE -ne 0) {
            throw 'flutter build apk failed.'
        }

        & $Paths.Adb -s $DeviceId install -r 'build\app\outputs\flutter-apk\app-debug.apk'
        if ($LASTEXITCODE -ne 0) {
            throw 'adb install failed.'
        }

        & $Paths.Adb -s $DeviceId shell monkey -p $ApplicationId -c android.intent.category.LAUNCHER 1
        if ($LASTEXITCODE -ne 0) {
            throw 'Launching the Android app failed.'
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-AndroidSmokeTest {
    param(
        [pscustomobject]$Paths,
        [string]$DeviceId,
        [string]$TestPath = 'integration_test\app_smoke_test.dart'
    )

    Push-Location $Paths.ProjectRoot
    try {
        & $Paths.FlutterBin test $TestPath -d $DeviceId --no-pub
        if ($LASTEXITCODE -ne 0) {
            throw 'flutter test integration smoke test failed.'
        }
    }
    finally {
        Pop-Location
    }
}
