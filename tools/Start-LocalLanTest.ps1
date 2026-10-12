param(
    [Parameter(Mandatory=$true)][ValidateSet('Host','Client')][string]$Role,
    [Parameter(Mandatory=$true)][string]$TestRoot
)
$ErrorActionPreference='Stop'
$TestRoot=(Resolve-Path -LiteralPath $TestRoot).Path
$marker=Join-Path $TestRoot 'landirect-test.json'
if (-not (Test-Path -LiteralPath $marker)) { throw 'This directory is not a prepared isolated LAN test environment.' }
$record=Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
if ($record.testRoot -ne $TestRoot) { throw 'Test environment marker path differs.' }
$game=Join-Path $TestRoot $Role
$user=Join-Path $TestRoot ($Role+'User')
$shipping=Join-Path $game 'Dungeons\Binaries\Win64\Dungeons-Win64-Shipping.exe'
if ((Get-FileHash -LiteralPath $shipping -Algorithm SHA256).Hash -ne '3A8703406FD50520F83C4F70A0212C000CB3B584EF28EB38032902230C01EBDD') { throw 'Unsupported copied game executable.' }
if (-not (Test-Path -LiteralPath (Join-Path $user 'Saved\SaveGames'))) { throw 'Isolated test saves have not been prepared.' }
if (-not (Get-Process -Name steam -ErrorAction SilentlyContinue)) { throw 'Start your existing Steam client first.' }
foreach ($running in Get-Process -Name 'Dungeons','Dungeons-Win64-Shipping' -ErrorAction SilentlyContinue) {
    if ($running.Path -eq $shipping -or $running.Path -eq (Join-Path $game 'Dungeons.exe')) { throw "The $Role test instance is already running." }
}
# Steam's documented local testing hint. Only written inside test copies.
foreach ($file in @((Join-Path $game 'steam_appid.txt'),(Join-Path (Split-Path -Parent $shipping) 'steam_appid.txt'))) {
    [IO.File]::WriteAllText($file,'1912410')
}
# Repeated OutputDebugStringW waits can stall two local instances. Suppress
# debug-print notifications in these isolated test copies; mod files remain.
$arguments='-UserDir="'+$user+'" -SaveToUserDir -windowed -ResX=960 -ResY=540 -nosplash -LanDirectQuietDebug'
# Use the original bootstrap, which supplies the project argument; show the
# interactive game window so the user can operate it and handle OS prompts.
$started=Start-Process -FilePath (Join-Path $game 'Dungeons.exe') -ArgumentList $arguments -WorkingDirectory $game -WindowStyle Normal -PassThru
Write-Host "$Role bootstrap PID=$($started.Id)"
Write-Host "Isolated saves: $user\Saved\SaveGames"
Write-Host 'Host: create LAN lobby, then original Play. Client: join 127.0.0.1:7777.'
