param(
    [string]$Godot = "$env:USERPROFILE/.cache/hollow-house/engine/Godot_v4.5.2-stable_win64_console.exe",
    [switch]$Release
)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
if (!(& $Godot --version).StartsWith('4.5.2.stable')) { throw 'Godot 4.5.2 stable is required.' }
New-Item -ItemType Directory -Force (Join-Path $project 'artifacts') | Out-Null
& $Godot --headless --path $project --editor --import --quit
if ($LASTEXITCODE) { throw 'Import failed' }
if ($Release) {
    foreach ($key in @('GODOT_ANDROID_KEYSTORE_RELEASE_PATH','GODOT_ANDROID_KEYSTORE_RELEASE_USER','GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD')) {
        if (![Environment]::GetEnvironmentVariable($key)) { throw "Set $key outside the repository first" }
    }
    & $Godot --headless --path $project --export-release Android (Join-Path $project 'artifacts/WaitingForDawn-0.8.1.apk')
} else {
    & $Godot --headless --path $project --export-debug Android (Join-Path $project 'artifacts/WaitingForDawn-0.8.1.apk')
}
if ($LASTEXITCODE) { throw 'Android export failed' }
& $Godot --headless --path $project --export-release 'Windows Desktop' (Join-Path $project 'artifacts/WaitingForDawn-0.8.1.exe')
if ($LASTEXITCODE) { throw 'Windows export failed' }
Get-FileHash (Join-Path $project 'artifacts/WaitingForDawn-0.8.1.apk') -Algorithm SHA256 | Format-List
