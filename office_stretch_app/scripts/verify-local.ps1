param(
    [ValidateSet('analyze', 'test')]
    [string]$Mode = 'analyze',
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

Push-Location $paths.ProjectRoot
try {
    switch ($Mode) {
        'analyze' {
            & $paths.FlutterBin analyze --no-pub
            if ($LASTEXITCODE -ne 0) {
                throw 'flutter analyze failed.'
            }
        }
        'test' {
            & $paths.FlutterBin test --no-pub
            if ($LASTEXITCODE -ne 0) {
                throw 'flutter test failed.'
            }
        }
    }
}
finally {
    Pop-Location
}
