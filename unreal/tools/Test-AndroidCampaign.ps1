param(
    [string]$Adb='E:/WaitingForDawnTools/Android/sdk/platform-tools/adb.exe',
    [string]$Serial='emulator-5560',
    [string]$Apk='E:/WaitingForDawnBuilds/Android_ASTC/WaitingForDawn-arm64.apk'
)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$package='org.waitingfordawn.unrealpreview'
& $Adb -s $Serial install -r $Apk
if($LASTEXITCODE -ne 0){throw 'APK install failed'}
& $Adb -s $Serial shell am force-stop $package
& $Adb -s $Serial logcat -c
& $Adb -s $Serial shell "am start -n $package/com.epicgames.unreal.GameActivity --es cmdline '-WDHouseTest -unattended'"
$deadline=(Get-Date).AddMinutes(7)
do {
    Start-Sleep -Seconds 3
    $log=(& $Adb -s $Serial logcat -d -s UE AndroidRuntime) -join "`n"
    $match=[regex]::Match($log,'WD_CAMPAIGN_RESULT (\{[^\r\n]+\})')
    if($match.Success){break}
    if($log -match 'FATAL EXCEPTION|Fatal error:'){throw 'Android runtime crash; inspect logcat'}
} while((Get-Date) -lt $deadline)
$log | Set-Content (Join-Path $root 'artifacts/unreal-setup/android-campaign.log')
if(!$match.Success){throw 'Android campaign timed out'}
$result=$match.Groups[1].Value
$result | Set-Content (Join-Path $root 'unreal/docs/evidence/campaign-android.json')
if(!($result | ConvertFrom-Json).passed){throw $result}
Write-Output $result
