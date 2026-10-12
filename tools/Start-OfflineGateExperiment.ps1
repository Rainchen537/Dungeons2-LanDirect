param(
    [Parameter(Mandatory=$true)][string]$TestRoot,
    [switch]$KeepSteamForControl
)
$ErrorActionPreference='Stop'
$TestRoot=(Resolve-Path -LiteralPath $TestRoot).Path
$marker=Join-Path $TestRoot 'landirect-test.json'
if (-not (Test-Path -LiteralPath $marker)) { throw 'Prepared isolated test environment required.' }
$record=Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
if ($record.testRoot -ne $TestRoot) { throw 'Test environment marker differs.' }
$game=Join-Path $TestRoot 'Client'
$user=Join-Path $TestRoot 'ClientUser'
$shipping=Join-Path $game 'Dungeons\Binaries\Win64\Dungeons-Win64-Shipping.exe'
if ($game -notlike '*\LanDirectTests\*\Client') { throw 'Experiment is restricted to LanDirectTests Client copies.' }
if ((Get-FileHash -LiteralPath $shipping).Hash -ne '3A8703406FD50520F83C4F70A0212C000CB3B584EF28EB38032902230C01EBDD') { throw 'Unsupported executable.' }
$built=Join-Path (Split-Path -Parent $PSScriptRoot) 'artifacts\OfflineGate-experiment\dwmapi.dll'
$installed=Join-Path (Split-Path -Parent $shipping) 'dwmapi.dll'
if ((Get-FileHash -LiteralPath $built).Hash -ne (Get-FileHash -LiteralPath $installed).Hash) { throw 'Deploy the backed up experimental build first.' }
if (-not (Test-Path -LiteralPath (Join-Path $user 'Saved\SaveGames'))) { throw 'Isolated saves missing.' }
foreach ($running in Get-Process -Name Dungeons,Dungeons-Win64-Shipping -ErrorAction SilentlyContinue) {
    if ($running.Path -eq $shipping -or $running.Path -eq (Join-Path $game 'Dungeons.exe')) { throw 'Client is already running.' }
}
$mode=if($KeepSteamForControl){'-LanDirectOfflineFlowControl'}else{'-nosteam'}
$arguments='-UserDir="'+$user+'" -SaveToUserDir -windowed -ResX=960 -ResY=540 -nosplash -LanDirectQuietDebug -LanDirectOfflineGateExperiment '+$mode
Start-Process -FilePath (Join-Path $game 'Dungeons.exe') -ArgumentList $arguments -WorkingDirectory $game -WindowStyle Normal
