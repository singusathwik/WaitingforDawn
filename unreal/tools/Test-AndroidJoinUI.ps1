# Coordinates are for the reviewed 2400x1080 landscape test emulator.
param([string]$Adb='E:/WaitingForDawnTools/Android/sdk/platform-tools/adb.exe',[string]$Serial='emulator-5560',[ValidatePattern('^[a-zA-Z0-9-]+$')][string]$EvidenceSuffix='092')
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
& $Adb -s $Serial shell am force-stop org.waitingfordawn.unrealpreview
& $Adb -s $Serial logcat -c
& $Adb -s $Serial shell "am start -n org.waitingfordawn.unrealpreview/com.epicgames.unreal.GameActivity --es cmdline '-WDHouseNetClient -WDExpectedPlayers=2 -unattended'"
$until=(Get-Date).AddSeconds(60)
do{Start-Sleep -Seconds 1;$log=(& $Adb -s $Serial logcat -d -s UE)-join "`n"}while($log -notmatch 'Bringing up level for play took' -and (Get-Date)-lt $until)
if($log -notmatch 'Bringing up level for play took'){throw 'Android home did not load'}
# Allow the first rendered HUD frame to finish on ARM64 translation before tapping.
Start-Sleep -Seconds 7
& $Adb -s $Serial shell input tap 320 750
Start-Sleep -Milliseconds 500
& $Adb -s $Serial shell input tap 320 750
Start-Sleep -Milliseconds 500
& $Adb -s $Serial shell input tap 500 344
Start-Sleep -Seconds 1
& $Adb -s $Serial shell input text '10.0.2.2'
Start-Sleep -Milliseconds 500
& $Adb -s $Serial shell input keyevent 66
Start-Sleep -Seconds 1
& $Adb -s $Serial shell input tap 2000 700
Start-Sleep -Milliseconds 500
$output=Join-Path $root 'artifacts/unreal-setup/android-network-ui-inner.log'
# A previous run's Host ready line must not satisfy this run's readiness wait.
Set-Content -LiteralPath $output -Value ''
$inner=Start-Process (Join-Path $PSHOME 'pwsh.exe') -ArgumentList @('-NoProfile','-File',('"'+(Join-Path $PSScriptRoot 'Test-AndroidWindowsNetwork.ps1')+'"'),'-Port','7777','-ManualJoin','-EvidenceSuffix',$EvidenceSuffix) -WindowStyle Hidden -PassThru -RedirectStandardOutput $output -RedirectStandardError (Join-Path $root 'artifacts/unreal-setup/android-network-ui-inner.stderr')
$null=$inner.Handle
$until=(Get-Date).AddSeconds(45)
do{Start-Sleep -Milliseconds 300;$ready=Get-Content $output -Raw -ErrorAction SilentlyContinue}while($ready -notmatch 'Host ready' -and (Get-Date)-lt $until -and !$inner.HasExited)
if($ready -notmatch 'Host ready'){throw 'UI test host did not start'}
& $Adb -s $Serial shell input tap 1200 398
Start-Sleep -Seconds 2
$log=(& $Adb -s $Serial logcat -d -s UE)-join "`n"
if($log -notmatch 'Browse:.*10.0.2.2|Connecting to|PendingNetGame'){
    & $Adb -s $Serial shell input tap 1200 398
}
$until=(Get-Date).AddSeconds(120)
while(!$inner.HasExited -and (Get-Date)-lt $until){Start-Sleep -Seconds 1}
if(!$inner.HasExited){Stop-Process -Id $inner.Id;throw 'Join UI test timed out'}
$inner.WaitForExit()
if($inner.ExitCode-ne 0){throw 'Join UI network test failed; inspect inner log'}
Write-Output 'Android home -> Join with friends -> entered host IP -> Join house -> network gameplay PASS'
