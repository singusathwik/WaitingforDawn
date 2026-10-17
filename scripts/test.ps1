param([string]$Godot = "$env:USERPROFILE/.cache/hollow-house/engine/Godot_v4.5.2-stable_win64_console.exe", [switch]$InteractionsOnly)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$results = Join-Path $project 'artifacts/tests'
New-Item -ItemType Directory -Force $results | Out-Null
function Launch([string]$Mode, [string]$Label) {
    $process = Start-Process -FilePath $Godot -ArgumentList '--headless','--path',('"'+$project+'"'),'--',"--test=$Mode" -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $results "$Label.log") -RedirectStandardError (Join-Path $results "$Label.err")
    $null = $process.Handle
    return $process
}
function Check($Process,[string]$Label) {
    if (!$Process.WaitForExit(120000)) { $Process.Kill(); throw "$Label timed out" }
    $Process.Refresh()
    Get-Content (Join-Path $results "$Label.log")
    $errors = Get-Content (Join-Path $results "$Label.err") -Raw
    if ($Process.ExitCode -ne 0 -or $errors -match 'SCRIPT ERROR|ERROR:') { throw "$Label failed: $errors" }
}
if (!$InteractionsOnly) {
$rules = Launch 'rules' 'rules'
Check $rules 'rules'
foreach ($count in @(2,4)) {
    $mode = if ($count -eq 4) {'host4'} else {'host'}
    $hostProcess = Launch $mode "host$count"
    Start-Sleep -Milliseconds 700
    $clients = @()
    for ($i=1; $i -lt $count; $i++) { $clients += Launch 'client' "client$count-$i" }
    Check $hostProcess "host$count"
    for ($i=1; $i -lt $count; $i++) { Check $clients[$i-1] "client$count-$i" }
}
$hostProcess = Launch 'host' 'mismatch-host'
Start-Sleep -Milliseconds 700
$clientProcess = Launch 'mismatch' 'mismatch'
Check $clientProcess 'mismatch'
if (!$hostProcess.HasExited) { $hostProcess.Kill(); $hostProcess.WaitForExit() }
foreach ($mode in @('departurehost','repeat-host')) {
    $hostProcess = Launch $mode $mode
    Start-Sleep -Milliseconds 700
    $clientMode = if ($mode -eq 'departurehost') {'departclient'} else {'client'}
    $clientProcess = Launch $clientMode $clientMode
    Check $hostProcess $mode
    Check $clientProcess $clientMode
}
$hostProcess = Launch 'host' 'late-host'
Start-Sleep -Milliseconds 700
$clientProcess = Launch 'client' 'late-client'
Start-Sleep -Seconds 4
$late = Launch 'late' 'late'
Check $late 'late'
Check $hostProcess 'late-host'
Check $clientProcess 'late-client'
$hostProcess = Launch 'lobbyhost' 'capacity-host'
Start-Sleep -Milliseconds 700
$clients=@()
for ($i=1; $i -le 3; $i++) { $clients += Launch 'waiting' "capacity-$i" }
Start-Sleep -Seconds 1
$full = Launch 'full' 'full'
Check $full 'full'
Check $hostProcess 'capacity-host'
for ($i=1; $i -le 3; $i++) { Check $clients[$i-1] "capacity-$i" }
$timeout = Launch 'timeout' 'timeout'
Check $timeout 'timeout'
Write-Output 'PASS: rules, two/four peers, movement, departures, persistence, mismatch, repeated matches, active-match rejection, capacity and timeout.'
$hostProcess = Launch 'coop-host' 'coop-host'
Start-Sleep -Milliseconds 700
$clients=@()
for ($i=1; $i -le 3; $i++) { $clients += Launch 'coop-client' "coop-client-$i" }
Check $hostProcess 'coop-host'
for ($i=1; $i -le 3; $i++) { Check $clients[$i-1] "coop-client-$i" }
Write-Output 'PASS: four-peer pickup race, revival, shared objectives, all-player boarding, synchronized victory and restart.'

$scares = Launch 'scares' 'scares'
Check $scares 'scares'

$art = Launch 'art' 'art'
Check $art 'art'

& $Godot --headless --path $project --script res://tests/ios_configuration.gd
if ($LASTEXITCODE) { throw "iOS configuration checks failed" }

$difficulty = Launch "difficulty" "difficulty"
Check $difficulty "difficulty"

}
$horror = Launch 'horror' 'horror'
Check $horror 'horror'
$horrorHost = Launch 'horror-host' 'horror-host'
Start-Sleep -Milliseconds 700
$horrorClient = Launch 'horror-client' 'horror-client'
Check $horrorHost 'horror-host'
Check $horrorClient 'horror-client'

$exploration = Launch 'exploration' 'exploration'
Check $exploration 'exploration'
$hostProcess = Launch 'search-host' 'search-host'
Start-Sleep -Milliseconds 700
$clientProcess = Launch 'search-client' 'search-client'
Check $hostProcess 'search-host'
Check $clientProcess 'search-client'
