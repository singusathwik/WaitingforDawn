[CmdletBinding()]
param(
    [string]$EngineRoot = 'D:\UE_5.7',
    [ValidateSet('Check','Editor','Map','Tests','Windows','Android')][string]$Action = 'Check',
    [string]$OutputDirectory = 'E:\WaitingForDawnBuilds'
)
$ErrorActionPreference = 'Stop'
$projectPath = Join-Path $PSScriptRoot '../WaitingForDawn/WaitingForDawn.uproject'
$projectPath = [IO.Path]::GetFullPath($projectPath)
$editorPath = Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe'
$buildPath = Join-Path $EngineRoot 'Engine/Build/BatchFiles/Build.bat'
$uatPath = Join-Path $EngineRoot 'Engine/Build/BatchFiles/RunUAT.bat'
$versionPath = Join-Path $EngineRoot 'Engine/Build/Build.version'
if (!(Test-Path -LiteralPath $versionPath) -or !(Test-Path -LiteralPath $editorPath)) {
    throw "Unreal installation is incomplete or absent at $EngineRoot. Finish installing UE 5.7 with Android support."
}
$version = Get-Content -LiteralPath $versionPath -Raw | ConvertFrom-Json
if ($version.MajorVersion -ne 5 -or $version.MinorVersion -ne 7) { throw 'This project targets Unreal 5.7. Use a matching engine.' }
$vswhere = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'
if (!(Test-Path -LiteralPath $vswhere)) { throw 'Visual Studio C++ Build Tools are not installed.' }
$vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (!$vs) { throw 'Missing the MSVC x64 compiler. Install the C++ Build Tools workload.' }
Write-Output "UE $($version.MajorVersion).$($version.MinorVersion).$($version.PatchVersion); C++ tools: $vs"
if ($Action -eq 'Check') { exit 0 }
if ($Action -eq 'Editor') {
    & $buildPath WaitingForDawnEditor Win64 Development "-Project=$projectPath" -WaitMutex -NoHotReloadFromIDE
} elseif ($Action -eq 'Map') {
    $mapScript = Join-Path $PSScriptRoot 'build_map.py'
    & $editorPath $projectPath -run=pythonscript "-script=$mapScript" -unattended -nosplash -stdout -FullStdOutLogOutput
} elseif ($Action -eq 'Tests') {
    & $editorPath $projectPath /Game/Maps/StairHall -unattended -NullRHI -nosplash '-ExecCmds=Automation RunTests WaitingForDawn' '-TestExit=Automation Test Queue Empty' '-ReportExportPath=Saved/Automation' -stdout -FullStdOutLogOutput
} else {
    if (!(Test-Path -LiteralPath (Join-Path (Split-Path $projectPath) 'Content/Maps/StairHall.umap'))) {
        throw 'Generate and validate StairHall first. Refusing to package an empty project.'
    }
    $platform = if ($Action -eq 'Windows') {'Win64'} else {'Android'}
    $buildArgs = @('BuildCookRun',"-project=$projectPath",'-noP4',"-platform=$platform",'-clientconfig=Development','-build','-cook','-stage','-pak','-archive',"-archivedirectory=$OutputDirectory",'-map=/Game/Maps/StairHall','-utf8output')
    if ($Action -eq 'Android') { $buildArgs += '-cookflavor=ASTC' }
    & $uatPath @buildArgs
}
if ($LASTEXITCODE -ne 0) { throw "Unreal $Action failed with exit $LASTEXITCODE. See the engine log; no build success is implied." }
