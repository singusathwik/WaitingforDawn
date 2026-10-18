param([switch]$Test)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$map=Join-Path $root 'unreal/WaitingForDawn/Content/Maps/House.umap'
$backup=Join-Path $root ('artifacts/unreal-setup/House-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.umap')
if (!$map.StartsWith($root+[IO.Path]::DirectorySeparatorChar) -or !$backup.StartsWith($root+[IO.Path]::DirectorySeparatorChar)) {throw 'Unsafe map path'}
if(Test-Path -LiteralPath $map){Move-Item -LiteralPath $map -Destination $backup}
$env:WD_HOUSE='1'
${env:UE-LocalDataCachePath}='E:/WaitingForDawnTools/DerivedDataCache'
& (Join-Path $PSScriptRoot 'Build.ps1') -Action Map > (Join-Path $root 'artifacts/unreal-setup/house-import.log') 2>&1
if($LASTEXITCODE -ne 0){throw 'House generation failed; previous map preserved in artifacts'}
foreach($script in @('repair_ghost_animation_scale.py','update_encounters_091.py')){
    & 'D:/UE_5.7/Engine/Binaries/Win64/UnrealEditor-Cmd.exe' (Join-Path $root 'unreal/WaitingForDawn/WaitingForDawn.uproject') -run=pythonscript "-script=$(Join-Path $PSScriptRoot $script)" -unattended -nosplash -stdout -FullStdOutLogOutput > (Join-Path $root "artifacts/unreal-setup/$script.log") 2>&1
    if($LASTEXITCODE-ne 0){throw "Post-import repair failed: $script"}
}
if($Test){& (Join-Path $PSScriptRoot 'Build.ps1') -Action Campaign > (Join-Path $root 'artifacts/unreal-setup/campaign-test.log') 2>&1}
