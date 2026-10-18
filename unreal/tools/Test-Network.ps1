[CmdletBinding()]
param([string]$EngineRoot='D:\UE_5.7',[int]$Port=7779)
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../WaitingForDawn/WaitingForDawn.uproject'))
$editor=Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe'
$results=Join-Path (Split-Path $project) 'Saved/Validation'
New-Item -ItemType Directory -Path $results -Force > $null
if (Get-NetUDPEndpoint -LocalPort $Port -ErrorAction SilentlyContinue) { throw "Port $Port is already in use" }
$started=Get-Date
$quotedProject='"'+$project+'"'
$common=@('-game','-NullRHI','-nosound','-nosplash','-unattended','-stdout','-FullStdOutLogOutput','-ExecCmds="t.MaxFPS 30"')
$hostProcess=$null; $clientProcess=$null
try {
    $hostProcess=Start-Process -FilePath $editor -ArgumentList (@($quotedProject,'/Game/Maps/StairHall?listen','-WDNetworkServer',"-port=$Port",'-multihome=127.0.0.1')+$common) -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $results 'network-server.log') -RedirectStandardError (Join-Path $results 'network-server.stderr')
    $null=$hostProcess.Handle # Keep the native handle so Windows PowerShell retains ExitCode.
    $deadline=(Get-Date).AddSeconds(90)
    while ((Get-Date) -lt $deadline) {
        if ($hostProcess.HasExited) { throw 'Listen server exited before client startup' }
        if ((Get-Content (Join-Path $results 'network-server.log') -Raw -ErrorAction SilentlyContinue) -match "listening on port $Port") { break }
        Start-Sleep -Milliseconds 500
    }
    $clientProcess=Start-Process -FilePath $editor -ArgumentList (@($quotedProject,"127.0.0.1:$Port",'-WDNetworkClient')+$common) -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $results 'network-client.log') -RedirectStandardError (Join-Path $results 'network-client.stderr')
    $null=$clientProcess.Handle
    while ((Get-Date) -lt $deadline -and (!$hostProcess.HasExited -or !$clientProcess.HasExited)) { Start-Sleep -Milliseconds 500 }
    foreach ($run in @($hostProcess,$clientProcess)) {
        if (!$run.HasExited) { throw 'A network test process timed out' }
        $run.WaitForExit()
        if ($run.ExitCode -ne 0) { throw "Network process exited with code $($run.ExitCode)" }
    }
    foreach ($role in @('server','client')) {
        $file=Get-Item (Join-Path $results "network-$role.json") -ErrorAction Stop
        if ($file.LastWriteTime -lt $started) { throw "Stale $role result" }
        $result=Get-Content $file.FullName -Raw | ConvertFrom-Json
        if (!$result.passed) { throw "$role failed: $($result.detail)" }
        Write-Output "$role PASS: $($result.detail)"
    }
} finally {
    foreach ($ownedProcess in @($clientProcess,$hostProcess)) {
        if ($ownedProcess -and !$ownedProcess.HasExited) { Stop-Process -Id $ownedProcess.Id }
    }
}
