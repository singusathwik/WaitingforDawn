param([string]$Adb='E:/WaitingForDawnTools/Android/sdk/platform-tools/adb.exe',[string]$Serial='emulator-5560',[int]$Port=7783,[switch]$ManualJoin,[ValidatePattern('^[a-zA-Z0-9-]+$')][string]$EvidenceSuffix='092')
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$project=Join-Path $root 'unreal/WaitingForDawn/WaitingForDawn.uproject'
$results=Join-Path $root 'unreal/WaitingForDawn/Saved/Validation'
$package='org.waitingfordawn.unrealpreview';$started=Get-Date
if(Get-NetUDPEndpoint -LocalPort $Port -ErrorAction SilentlyContinue){throw 'Test port occupied'}
$server=$null
try {
    $args=@(('"'+$project+'"'),'/Game/Maps/House?listen','-game','-NullRHI','-nosound','-nosplash','-unattended','-stdout','-FullStdOutLogOutput','-ExecCmds="t.MaxFPS 30"','-WDHouseNetServer','-WDExpectedPlayers=2',"-port=$Port")
    $server=Start-Process 'D:/UE_5.7/Engine/Binaries/Win64/UnrealEditor-Cmd.exe' -ArgumentList $args -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $results 'android-host.log') -RedirectStandardError (Join-Path $results 'android-host.stderr')
    $null=$server.Handle
    $deadline=(Get-Date).AddSeconds(45)
    while((Get-Date)-lt $deadline){
        if($server.HasExited){throw 'Host exited during startup'}
        if((Get-Content (Join-Path $results 'android-host.log') -Raw -ErrorAction SilentlyContinue)-match "listening on port $Port"){break}
        Start-Sleep -Milliseconds 500
    }
    if(!$ManualJoin){
        & $Adb -s $Serial shell am force-stop $package
        & $Adb -s $Serial logcat -c
        & $Adb -s $Serial shell "am start -n $package/com.epicgames.unreal.GameActivity --es cmdline '10.0.2.2:$Port -WDHouseNetClient -WDExpectedPlayers=2 -unattended'"
    } else {Write-Output 'Host ready. Join through the already-open Android interface.'}
    $deadline=(Get-Date).AddSeconds(160);$match=$null
    do {
        Start-Sleep -Seconds 2
        $log=(& $Adb -s $Serial logcat -d -s UE AndroidRuntime) -join "`n"
        $match=[regex]::Match($log,'WD_CAMPAIGN_RESULT (\{[^\r\n]+\})')
    } while((!$match.Success -or !$server.HasExited)-and (Get-Date)-lt $deadline)
    $log | Set-Content (Join-Path $root 'artifacts/unreal-setup/android-network.log')
    if(!$match.Success){throw 'Android network probe timed out'}
    $client=$match.Groups[1].Value | ConvertFrom-Json
    if(!$client.passed){throw $client.detail}
    $server.WaitForExit(2000) | Out-Null
    if(!$server.HasExited -or $server.ExitCode -ne 0){throw 'Windows host did not pass'}
    $file=Get-Item (Join-Path $results 'house-net-server.json')
    if($file.LastWriteTime-lt $started){throw 'Stale host result'}
    $hostResult=Get-Content $file.FullName -Raw | ConvertFrom-Json
    if(!$hostResult.passed){throw $hostResult.detail}
    [ordered]@{environment='Android API 35 ARM64 translation with host Vulkan GPU; Windows UE 5.7.4; emulator virtual network, not physical Wi-Fi';joined_through_android_ui=[bool]$ManualJoin;client=$client;host=$hostResult} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $root "unreal/docs/evidence/network-android-windows-$EvidenceSuffix.json")
    Write-Output 'Android client and Windows host PASS'
} finally {if($server -and !$server.HasExited){Stop-Process -Id $server.Id}}
