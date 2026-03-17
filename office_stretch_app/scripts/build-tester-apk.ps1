param(
    [string]$AndroidWorkRoot = 'D:\Android',
    [string]$AndroidSdkRoot = 'C:\Users\UsEr\AppData\Local\Android\Sdk',
    [string]$JavaHome = 'D:\Android Studio\jbr',
    [string]$OutputName = 'office-stretch-tester.apk'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$workspaceRoot = Split-Path -Parent $projectRoot
$flutterRoot = Join-Path $workspaceRoot 'flutter'
$artifactRoot = Join-Path $projectRoot 'artifacts'

. (Join-Path $PSScriptRoot 'android-common.ps1')

$paths = Get-AndroidWorkspacePaths `
    -ProjectRoot $projectRoot `
    -FlutterRoot $flutterRoot `
    -AndroidSdkRoot $AndroidSdkRoot `
    -JavaHome $JavaHome `
    -AndroidWorkRoot $AndroidWorkRoot

Initialize-AndroidWorkspace -Paths $paths
Ensure-Directory $artifactRoot

Push-Location $paths.ProjectRoot
try {
    & $paths.FlutterBin build apk --release --no-pub
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter build apk --release failed.'
    }

    $releaseApk = Join-Path $paths.ProjectRoot 'build\app\outputs\flutter-apk\app-release.apk'
    if (-not (Test-Path $releaseApk)) {
        throw "Release APK not found at $releaseApk"
    }

    $targetPath = Join-Path $artifactRoot $OutputName
    Copy-Item $releaseApk $targetPath -Force
    Write-Host "Tester APK ready at $targetPath"
}
finally {
    Pop-Location
}
