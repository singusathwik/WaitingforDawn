param([string]$Adb='E:/WaitingForDawnTools/Android/sdk/platform-tools/adb.exe',[string]$Serial='emulator-5560',[ValidatePattern('^[a-zA-Z0-9-]+$')][string]$EvidenceSuffix='092')
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$output=Join-Path $root "unreal/docs/evidence/android-screens-$EvidenceSuffix"
New-Item -ItemType Directory -Force -Path $output | Out-Null
& $Adb -s $Serial shell am force-stop org.waitingfordawn.unrealpreview
& $Adb -s $Serial logcat -c
& $Adb -s $Serial shell "am start -n org.waitingfordawn.unrealpreview/com.epicgames.unreal.GameActivity --es cmdline '-WDThreatTest -unattended'"
$wanted=@('VisibleApproach','VisibleChase','CeilingCrawl','VisibleCapture');$seen=@{};$until=(Get-Date).AddSeconds(140)
do{
    $log=(& $Adb -s $Serial logcat -d -s UE AndroidRuntime)-join "`n"
    $phases=[regex]::Matches($log,'WD_CAMPAIGN ([A-Za-z0-9]+)')
    if($phases.Count){
        $phase=$phases[$phases.Count-1].Groups[1].Value
        if($wanted -contains $phase -and !$seen.ContainsKey($phase)){
            Start-Sleep -Milliseconds 600
            & $Adb -s $Serial shell screencap -p /sdcard/wd-threat.png | Out-Null
            & $Adb -s $Serial pull /sdcard/wd-threat.png (Join-Path $output ($phase+'.png')) | Out-Null
            if($LASTEXITCODE -ne 0){throw 'Capture failed'}
            $seen[$phase]=$true;Write-Output "Captured $phase"
        }
    }
    $result=[regex]::Match($log,'WD_CAMPAIGN_RESULT (\{[^\r\n]+\})')
    if($result.Success){break}
    Start-Sleep -Milliseconds 200
}while((Get-Date)-lt $until)
$log | Set-Content (Join-Path $root "artifacts/unreal-setup/threat-android-$EvidenceSuffix.log")
if(!$result.Success){throw 'Threat test timeout'}
$result.Groups[1].Value | Set-Content (Join-Path $root "unreal/docs/evidence/threat-android-$EvidenceSuffix.json")
if(!($result.Groups[1].Value|ConvertFrom-Json).passed -or $seen.Count-ne $wanted.Count){throw 'Threat test or screenshots failed'}
Write-Output $result.Groups[1].Value
