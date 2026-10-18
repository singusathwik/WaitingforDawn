param([int]$Port=7781)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$project=Join-Path $root 'unreal/WaitingForDawn/WaitingForDawn.uproject'
$editor='D:/UE_5.7/Engine/Binaries/Win64/UnrealEditor-Cmd.exe'
$results=Join-Path $root 'unreal/WaitingForDawn/Saved/Validation'
$runs=@();$started=Get-Date;$deadline=$started.AddSeconds(170)
if(Get-NetUDPEndpoint -LocalPort $Port -ErrorAction SilentlyContinue){throw 'Test port occupied'}
function Start-Run($name,$url,$flags){
    $args=@(('"'+$project+'"'),$url,'-game','-NullRHI','-nosound','-nosplash','-unattended','-stdout','-FullStdOutLogOutput','-ExecCmds="t.MaxFPS 30"')+$flags
    $p=Start-Process -FilePath $editor -ArgumentList $args -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $results ($name+'.log')) -RedirectStandardError (Join-Path $results ($name+'.stderr'))
    $null=$p.Handle
    return $p
}
try{
    $runs+=Start-Run 'house-net-server' '/Game/Maps/House?listen' @('-WDHouseNetServer',"-port=$Port",'-multihome=127.0.0.1')
    while((Get-Date)-lt $deadline){
        if($runs[0].HasExited){throw 'Server exited early'}
        if((Get-Content (Join-Path $results 'house-net-server.log') -Raw -ErrorAction SilentlyContinue)-match "listening on port $Port"){break}
        Start-Sleep -Milliseconds 500
    }
    $runs+=Start-Run 'house-net-client0' "127.0.0.1:$Port" @('-WDHouseNetClient')
    # Fourth process deliberately joins after the server has already collected the key.
    while((Get-Date)-lt $deadline){
        if((Get-Content (Join-Path $results 'house-net-server.log') -Raw -ErrorAction SilentlyContinue)-match 'WD_CAMPAIGN WaitHiding'){break}
        if($runs[0].HasExited){throw 'Server failed before late join'}
        Start-Sleep -Milliseconds 500
    }
    $runs+=Start-Run 'house-net-client1' "127.0.0.1:$Port" @('-WDHouseNetClient','-WDObserver=1')
    $runs+=Start-Run 'house-net-client2' "127.0.0.1:$Port" @('-WDHouseNetClient','-WDObserver=2')
    while((Get-Date)-lt $deadline -and ($runs | Where-Object {!$_.HasExited})){Start-Sleep -Milliseconds 500}
    foreach($p in $runs){if(!$p.HasExited){throw 'Network timeout'};$p.WaitForExit();if($p.ExitCode-ne 0){throw "Process failed $($p.ExitCode)"}}
    foreach($name in @('house-net-server','house-net-client0','house-net-client1','house-net-client2')){
        $file=Get-Item (Join-Path $results ($name+'.json'));if($file.LastWriteTime-lt $started){throw 'Stale result'}
        $r=Get-Content $file.FullName -Raw|ConvertFrom-Json;if(!$r.passed){throw $r.detail};Write-Output "$name PASS: $($r.detail)"
    }
}finally{foreach($p in $runs){if(!$p.HasExited){Stop-Process -Id $p.Id}}}
