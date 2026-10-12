# Isolated filesystem fixtures only; no real game or saves.
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$fixture=Join-Path $root ('artifacts\native-test-'+[guid]::NewGuid().ToString('N'))
$game=Join-Path $fixture 'Game'
$local=Join-Path $fixture 'Local'
$state=Join-Path $fixture 'State'
$save=Join-Path $local 'Dungeons2\Saved\SaveGames'
$config=Join-Path $local 'Dungeons2\Saved\Config\Windows\Engine.ini'
$exe=Join-Path $game 'Dungeons\Binaries\Win64\Dungeons-Win64-Shipping.exe'
$dll=Join-Path (Split-Path -Parent $exe) 'dwmapi.dll'
foreach ($dir in @($save,(Split-Path -Parent $config),(Split-Path -Parent $exe))) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[IO.File]::WriteAllText($exe,'fixture-native-game')
[IO.File]::WriteAllText((Join-Path $save 'CharacterFixture.sav'),'current-progress')
[IO.File]::WriteAllText($config,"[SystemSettings]`r`nr.Test=7`r`n[Other]`r`nPreserve=1`r`n")
$configHash=(Get-FileHash -LiteralPath $config).Hash
$saveHash=(Get-FileHash -LiteralPath (Join-Path $save 'CharacterFixture.sav')).Hash
$source=[IO.File]::ReadAllText((Join-Path $root 'scripts\Manage-NativeBridge.ps1'))
$source=$source.Replace('3a8703406fd50520f83c4f70a0212c000cb3b584ef28eb38032902230c01ebdd',(Get-FileHash -LiteralPath $exe).Hash)
$script=Join-Path $fixture 'Installer.ps1'
[IO.File]::WriteAllText($script,$source,(New-Object Text.UTF8Encoding($true)))
$harness=Join-Path $fixture 'Harness.ps1'
$harnessSource=@'
param($ScriptPath,$Action,$GameRoot,$PackageRoot,$StateRoot,$LocalRoot,[int]$Running)
$env:LOCALAPPDATA=$LocalRoot
function Get-Process { param($Name,$ErrorAction); if ($Running -eq 1) { [pscustomobject]@{HasExited=$false} } }
& $ScriptPath -Action $Action -GameRoot $GameRoot -PackageRoot $PackageRoot -StateRoot $StateRoot -NonInteractive
exit $LASTEXITCODE
'@
[IO.File]::WriteAllText($harness,$harnessSource)
function Run-Case($Label,$Action,$Expected,[int]$Running=0) {
    $output=& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $harness -ScriptPath $script -Action $Action -GameRoot $game -PackageRoot (Join-Path $root 'artifacts\NativeBridge-0.1.1') -StateRoot $state -LocalRoot $local -Running $Running 2>&1
    if ($LASTEXITCODE -ne $Expected) { throw "$Label failed: $output" }
    Write-Host "PASS: $Label"
}
Run-Case 'reject while game runs' 'Install' 1 1
[IO.File]::WriteAllText($dll,'another-loader')
Run-Case 'preserve another DLL' 'Install' 1
if ([IO.File]::ReadAllText($dll) -ne 'another-loader') { throw 'Other DLL changed.' }
Remove-Item -LiteralPath $dll
Run-Case 'install native bridge and streaming' 'Install' 0
$installedHash=(Get-FileHash -LiteralPath $config).Hash
$ini=[IO.File]::ReadAllText($config)
if ([regex]::Matches($ini,'(?m)^\[SystemSettings\]').Count -ne 1 -or $ini -notmatch 'r.Test=7' -or $ini -notmatch 'Preserve=1') { throw 'Existing settings were lost or section duplicated.' }
Run-Case 'check native and config' 'Check' 0
Run-Case 'reject duplicate install' 'Install' 1
[IO.File]::AppendAllText($config,"`r`nLaterChange=1")
Run-Case 'preserve later config changes' 'Uninstall' 1
if (-not (Test-Path -LiteralPath $dll)) { throw 'Rejected uninstall moved DLL.' }
$record=Get-Content -LiteralPath (Join-Path $state 'installation.json') -Raw | ConvertFrom-Json
Copy-Item -LiteralPath (Join-Path $record.backupDir 'Engine.installed.ini') -Destination $config -Force
if ((Get-FileHash -LiteralPath $config).Hash -ne $installedHash) { throw 'Fixture restoration failed.' }
Run-Case 'restore exact original config' 'Uninstall' 0
if ((Get-FileHash -LiteralPath $config).Hash -ne $configHash -or (Test-Path -LiteralPath $dll)) { throw 'Uninstall did not restore original state.' }
# Native PowerShell deletion, only the explicit file within this fixture.
Remove-Item -LiteralPath $config
Run-Case 'install without prior Engine.ini' 'Install' 0
Run-Case 'uninstall newly created Engine.ini' 'Uninstall' 0
if (Test-Path -LiteralPath $config) { throw 'New config left behind.' }
if ((Get-FileHash -LiteralPath (Join-Path $save 'CharacterFixture.sav')).Hash -ne $saveHash) { throw 'Save was modified.' }
Write-Host 'All native installer fixture checks passed.'
exit 0
