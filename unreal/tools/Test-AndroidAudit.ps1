param([string]$Adb='E:/WaitingForDawnTools/Android/sdk/platform-tools/adb.exe',[string]$Serial='emulator-5560',[ValidatePattern('^[a-zA-Z0-9-]+$')][string]$EvidenceSuffix='093')
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
& $Adb -s $Serial shell am force-stop org.waitingfordawn.unrealpreview
& $Adb -s $Serial logcat -c
& $Adb -s $Serial shell "am start -n org.waitingfordawn.unrealpreview/com.epicgames.unreal.GameActivity --es cmdline '-WDAuditTest -unattended'"
$deadline=(Get-Date).AddMinutes(7)
do{
    Start-Sleep -Seconds 2
    $log=(& $Adb -s $Serial logcat -d -s UE AndroidRuntime)-join "`n"
    $result=[regex]::Match($log,'WD_CAMPAIGN_RESULT (\{[^\r\n]+\})')
    if($result.Success){break}
    if($log -match 'FATAL EXCEPTION|Fatal error:'){throw 'Android audit crashed'}
}while((Get-Date)-lt $deadline)
$log|Set-Content (Join-Path $root "artifacts/unreal-setup/audit-android-$EvidenceSuffix.log")
if(!$result.Success){throw 'Android audit timed out'}
$result.Groups[1].Value|Set-Content (Join-Path $root "unreal/docs/evidence/component-audit-android-$EvidenceSuffix.json")
if(!($result.Groups[1].Value|ConvertFrom-Json).passed){throw $result.Groups[1].Value}
Write-Output $result.Groups[1].Value
