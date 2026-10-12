param([string]$InstallerPath)
# Isolated filesystem fixtures only; no real game or saves.
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$version=([xml](Get-Content -LiteralPath (Join-Path $root 'mods\LanDirect\LanDirect.csproj') -Raw)).Project.PropertyGroup.Version
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
if (-not $InstallerPath) { $InstallerPath=Join-Path $root 'scripts\Manage-NativeBridge.ps1' }
$source=[IO.File]::ReadAllText($InstallerPath)
$source=$source.Replace('3a8703406fd50520f83c4f70a0212c000cb3b584ef28eb38032902230c01ebdd',(Get-FileHash -LiteralPath $exe).Hash)
$script=Join-Path $fixture 'Installer.ps1'
[IO.File]::WriteAllText($script,$source,(New-Object Text.UTF8Encoding($true)))
$harness=Join-Path $fixture 'Harness.ps1'
$harnessSource=@'
param($ScriptPath,$Action,$GameRoot,$PackageRoot,$StateRoot,$LocalRoot,[int]$Running,[int]$FailRecord)
$env:LOCALAPPDATA=$LocalRoot
function Get-Process { param($Name,$ErrorAction); if ($Running -eq 1) { [pscustomobject]@{HasExited=$false} } }
function Set-Content {
    param([string]$LiteralPath,[Parameter(ValueFromPipeline=$true)]$Value,[string]$Encoding)
    process {
        if ($FailRecord -eq 1 -and [IO.Path]::GetFileName($LiteralPath) -eq 'installation.json') { throw 'Fixture: state write failed.' }
        Microsoft.PowerShell.Management\Set-Content -LiteralPath $LiteralPath -Value $Value -Encoding $Encoding
    }
}
& $ScriptPath -Action $Action -GameRoot $GameRoot -PackageRoot $PackageRoot -StateRoot $StateRoot -NonInteractive
exit $LASTEXITCODE
'@
[IO.File]::WriteAllText($harness,$harnessSource)
function Run-Case($Label,$Action,$Expected,[int]$Running=0,[int]$FailRecord=0) {
    $output=& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $harness -ScriptPath $script -Action $Action -GameRoot $game -PackageRoot (Join-Path $root "artifacts\NativeBridge-$version") -StateRoot $state -LocalRoot $local -Running $Running -FailRecord $FailRecord 2>&1
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
if (-not ([IO.File]::GetAttributes($config) -band [IO.FileAttributes]::ReadOnly)) { throw 'Config is writable.' }
try { [IO.File]::WriteAllText($config,'runtime rewrite'); throw 'Runtime write was allowed.' }
catch { if ($_.Exception.Message -eq 'Runtime write was allowed.') { throw } }
try { [IO.File]::Delete($config); throw 'Runtime deletion was allowed.' }
catch { if ($_.Exception.Message -eq 'Runtime deletion was allowed.') { throw } }
if ((Get-FileHash -LiteralPath $config).Hash -ne $installedHash) { throw 'Protected config changed.' }
Write-Host 'PASS: block runtime rewrite and deletion'
Run-Case 'reject repair while game runs' 'Repair' 1 1
Run-Case 'reject duplicate install' 'Install' 1
[IO.File]::SetAttributes($config,[IO.FileAttributes]::Normal)
[IO.File]::AppendAllText($config,"`r`nLaterChange=1")
Run-Case 'preserve later config changes' 'Uninstall' 1
if (-not (Test-Path -LiteralPath $dll)) { throw 'Rejected uninstall moved DLL.' }
$record=Get-Content -LiteralPath (Join-Path $state 'installation.json') -Raw | ConvertFrom-Json
Copy-Item -LiteralPath (Join-Path $record.backupDir 'Engine.installed.ini') -Destination $config -Force
if ((Get-FileHash -LiteralPath $config).Hash -ne $installedHash) { throw 'Fixture restoration failed.' }
Run-Case 'restore exact original config' 'Uninstall' 0
if ((Get-FileHash -LiteralPath $config).Hash -ne $configHash -or (Test-Path -LiteralPath $dll)) { throw 'Uninstall did not restore original state.' }
if ([IO.File]::GetAttributes($config) -band [IO.FileAttributes]::ReadOnly) { throw 'Original writable attribute not restored.' }
# Native PowerShell deletion, only the explicit file within this fixture.
Remove-Item -LiteralPath $config
Run-Case 'install without prior Engine.ini' 'Install' 0
Run-Case 'uninstall newly created Engine.ini' 'Uninstall' 0
if (Test-Path -LiteralPath $config) { throw 'New config left behind.' }

# Upgrade a legacy installation after the engine regenerated a writable config.
[IO.File]::WriteAllText($config,";latest settings`r`n[SystemSettings]`r`nr.Test=9`r`n[Other]`r`nPreserve=2`r`n")
$latestHash=(Get-FileHash -LiteralPath $config).Hash
Run-Case 'install upgrade fixture' 'Install' 0
[IO.File]::SetAttributes($config,[IO.FileAttributes]::Normal)
[IO.File]::WriteAllText($config,";latest settings`r`n[SystemSettings]`r`nr.Test=9`r`n[Other]`r`nPreserve=2`r`n")
$recordPath=Join-Path $state 'installation.json'
$record=Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
$record.PSObject.Properties.Remove('configProtected')
$record.PSObject.Properties.Remove('originalConfigAttributes')
[IO.File]::WriteAllText($recordPath,($record | ConvertTo-Json),(New-Object Text.UTF8Encoding($true)))
Run-Case 'detect regenerated config' 'Check' 1
Run-Case 'repair legacy regenerated config' 'Repair' 0
Run-Case 'check repaired protection and values' 'Check' 0
$repairedHash=(Get-FileHash -LiteralPath $config).Hash
Run-Case 'repair intact config again' 'Repair' 0
if ((Get-FileHash -LiteralPath $config).Hash -ne $repairedHash) { throw 'Repair is not idempotent.' }
Run-Case 'restore latest preferences after repair' 'Uninstall' 0
if ((Get-FileHash -LiteralPath $config).Hash -ne $latestHash) { throw 'Latest unrelated settings were lost.' }

Run-Case 'install before deleted config' 'Install' 0
[IO.File]::SetAttributes($config,[IO.FileAttributes]::Normal)
Remove-Item -LiteralPath $config
Run-Case 'repair deleted config' 'Repair' 0
Run-Case 'check repaired missing config' 'Check' 0
Run-Case 'uninstall repaired missing config' 'Uninstall' 0
if (Test-Path -LiteralPath $config) { throw 'Missing-config baseline was not restored.' }

# Original read-only files and BOM bytes survive installation and uninstall.
[IO.File]::WriteAllText($config,"[SystemSettings]`r`nr.Test=7",(New-Object Text.UTF8Encoding($true)))
[IO.File]::SetAttributes($config,[IO.FileAttributes]::ReadOnly)
$readOnlyHash=(Get-FileHash -LiteralPath $config).Hash
Run-Case 'install with original read-only config and no final newline' 'Install' 0
Run-Case 'check no-final-newline section' 'Check' 0
Run-Case 'repair original read-only BOM config' 'Repair' 0
Run-Case 'repair original read-only BOM config repeatedly' 'Repair' 0
Run-Case 'restore original read-only config' 'Uninstall' 0
if ((Get-FileHash -LiteralPath $config).Hash -ne $readOnlyHash -or -not ([IO.File]::GetAttributes($config) -band [IO.FileAttributes]::ReadOnly)) { throw 'Original bytes or attributes changed.' }
[IO.File]::SetAttributes($config,[IO.FileAttributes]::Normal)

Run-Case 'install validation fixture' 'Install' 0
[IO.File]::SetAttributes($config,[IO.FileAttributes]::Normal)
[IO.File]::WriteAllText($config,"[Other]`r`nwp.Runtime.EnableServerStreaming=1`r`nwp.Runtime.EnableServerStreamingOut=1`r`n")
[IO.File]::SetAttributes($config,[IO.FileAttributes]::ReadOnly)
Run-Case 'reject values in wrong section' 'Check' 1
[IO.File]::SetAttributes($config,[IO.FileAttributes]::Normal)
[IO.File]::WriteAllText($config,"[SystemSettings]`r`nwp.Runtime.EnableServerStreaming=1`r`nwp.Runtime.EnableServerStreaming=0`r`nwp.Runtime.EnableServerStreamingOut=1`r`n")
[IO.File]::SetAttributes($config,[IO.FileAttributes]::ReadOnly)
Run-Case 'reject conflicting duplicate values' 'Check' 1
$conflictHash=(Get-FileHash -LiteralPath $config).Hash
Run-Case 'preserve custom streaming values during repair' 'Repair' 1
if ((Get-FileHash -LiteralPath $config).Hash -ne $conflictHash) { throw 'Custom config changed.' }
$record=Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
[IO.File]::SetAttributes($config,[IO.FileAttributes]::Normal)
Copy-Item -LiteralPath (Join-Path $record.backupDir 'Engine.installed.ini') -Destination $config -Force
[IO.File]::SetAttributes($config,[IO.FileAttributes]::ReadOnly)
$priorConfigHash=(Get-FileHash -LiteralPath $config).Hash
$priorStateHash=(Get-FileHash -LiteralPath $recordPath).Hash
Run-Case 'roll back failed repair state write' 'Repair' 1 0 1
if ((Get-FileHash -LiteralPath $config).Hash -ne $priorConfigHash -or (Get-FileHash -LiteralPath $recordPath).Hash -ne $priorStateHash -or -not ([IO.File]::GetAttributes($config) -band [IO.FileAttributes]::ReadOnly)) { throw 'Repair rollback changed config or record.' }
Run-Case 'uninstall rollback fixture' 'Uninstall' 0
$priorConfigHash=(Get-FileHash -LiteralPath $config).Hash
Run-Case 'roll back failed initial state write' 'Install' 1 0 1
if ((Get-FileHash -LiteralPath $config).Hash -ne $priorConfigHash -or (Test-Path -LiteralPath $dll) -or (Test-Path -LiteralPath $recordPath)) { throw 'Install rollback did not restore prior state.' }
if ((Get-FileHash -LiteralPath (Join-Path $save 'CharacterFixture.sav')).Hash -ne $saveHash) { throw 'Save was modified.' }
Write-Host 'All native installer fixture checks passed.'
exit 0
