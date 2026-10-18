# Landscape emulator: 2400 x 1080. Uses actual touch input, not a start-engine RPC fixture.
param([string]$Adb='E:/WaitingForDawnTools/Android/sdk/platform-tools/adb.exe',[string]$Serial='emulator-5560',[ValidatePattern('^[a-zA-Z0-9-]+$')][string]$EvidenceSuffix='093')
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$output=Join-Path $root "unreal/docs/evidence/car-android-$EvidenceSuffix"
New-Item -ItemType Directory -Force -Path $output|Out-Null
& $Adb -s $Serial shell am force-stop org.waitingfordawn.unrealpreview
& $Adb -s $Serial logcat -c
& $Adb -s $Serial shell "am start -n org.waitingfordawn.unrealpreview/com.epicgames.unreal.GameActivity --es cmdline '-WDHouseTest -WDCarOnly -WDCarUI -unattended'"
$seen=@{};$deadline=(Get-Date).AddSeconds(150)
do{
    $log=(& $Adb -s $Serial logcat -d -s UE AndroidRuntime)-join "`n"
    $phases=[regex]::Matches($log,'WD_CAMPAIGN ([A-Za-z0-9]+)')
    if($phases.Count){
        $phase=$phases[$phases.Count-1].Groups[1].Value
        if(@('TouchGetOut','TouchBoard','TouchStart','Departure','VictoryScreen') -contains $phase -and !$seen.ContainsKey($phase)){
            Start-Sleep -Milliseconds 650
            & $Adb -s $Serial shell screencap -p /sdcard/wd-car.png|Out-Null
            & $Adb -s $Serial pull /sdcard/wd-car.png (Join-Path $output ($phase+'.png'))|Out-Null
            if($LASTEXITCODE-ne 0){throw 'Car capture failed'}
            $seen[$phase]=$true
            switch($phase){
                TouchGetOut {& $Adb -s $Serial shell input tap 1510 955}
                TouchBoard {& $Adb -s $Serial shell input tap 2288 773}
                TouchStart {& $Adb -s $Serial shell input tap 817 955}
            }
            Write-Output "Captured and exercised $phase"
        }
    }
    $result=[regex]::Match($log,'WD_CAMPAIGN_RESULT (\{[^\r\n]+\})')
    if($result.Success){break}
    Start-Sleep -Milliseconds 250
}while((Get-Date)-lt $deadline)
$log|Set-Content (Join-Path $root "artifacts/unreal-setup/car-ui-android-$EvidenceSuffix.log")
if(!$result.Success){throw 'Android car UI test timed out'}
$result.Groups[1].Value|Set-Content (Join-Path $root "unreal/docs/evidence/car-ui-android-$EvidenceSuffix.json")
if(!($result.Groups[1].Value|ConvertFrom-Json).passed -or $seen.Count-ne 5){throw 'Car UI result or screenshots failed'}
Write-Output $result.Groups[1].Value
