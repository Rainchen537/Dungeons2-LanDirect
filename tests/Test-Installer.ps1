# File-system integration tests. Never use a real game or real save directory.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$fixture = Join-Path $root ('artifacts\installer-test-' + [guid]::NewGuid().ToString('N'))
$game = Join-Path $fixture 'Fake Steam Game'
$local = Join-Path $fixture 'LocalAppData'
$state = Join-Path $fixture 'State'
$package = Join-Path $fixture 'package'
$save = Join-Path $local 'Dungeons2\Saved\SaveGames'
$mods = Join-Path $game 'Dungeons\Content\Paks\~mods'
$exe = Join-Path $game 'Dungeons\Binaries\Win64\Dungeons-Win64-Shipping.exe'
foreach ($path in @((Split-Path -Parent $exe),$mods,$package,$save)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
[IO.File]::WriteAllText($exe, 'fixture-executable')
[IO.File]::WriteAllText((Join-Path $mods 'BlueprintLoader-test.pak'), 'fixture-loader')
[IO.File]::WriteAllText((Join-Path $save 'CharacterFixture.sav'), 'fixture-save')
$saveHash = (Get-FileHash -LiteralPath (Join-Path $save 'CharacterFixture.sav')).Hash
Copy-Item -Path (Join-Path $root 'artifacts\LanDirect-0.1.0\LanDirect_P.*') -Destination $package
Copy-Item -LiteralPath (Join-Path $root 'artifacts\LanDirect-0.1.0\manifest.json') -Destination $package
$script = Join-Path $fixture 'InstallerUnderTest.ps1'
$source = [IO.File]::ReadAllText((Join-Path $root 'scripts\Manage-LanDirect.ps1'))
# Substitute only the fixture executable hash; the production version remains pinned.
$source = $source.Replace('231147bd0c655a4ae73f90873675d42917f2bfb3a9ee164fc64f217d6d6bd4ef', (Get-FileHash -LiteralPath $exe).Hash)
[IO.File]::WriteAllText($script, $source, (New-Object Text.UTF8Encoding($true)))
$harness = Join-Path $fixture 'Harness.ps1'
$harnessSource = @'
param($ScriptPath,$Action,$GameRoot,$PackageRoot,$StateRoot,$LocalRoot,[int]$Running)
$env:LOCALAPPDATA = $LocalRoot
function Get-Process {
    param($Name,$ErrorAction)
    if ($Running -eq 1) { [pscustomobject]@{ HasExited=$false } }
}
& $ScriptPath -Action $Action -GameRoot $GameRoot -PackageRoot $PackageRoot -StateRoot $StateRoot -NonInteractive
exit $LASTEXITCODE
'@
[IO.File]::WriteAllText($harness, $harnessSource)
function Run-Case($Label,$Action,$Expected,[int]$Running=0) {
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $harness -ScriptPath $script -Action $Action -GameRoot $game -PackageRoot $package -StateRoot $state -LocalRoot $local -Running $Running 2>&1
    if ($LASTEXITCODE -ne $Expected) { throw "$Label failed: expected $Expected; got $LASTEXITCODE. $output" }
    Write-Host "PASS: $Label"
}
Run-Case 'check valid package and game' 'Check' 0
Run-Case 'reject install while game runs' 'Install' 1 1
Run-Case 'install with verified save backup' 'Install' 0
$record = Get-Content -LiteralPath (Join-Path $state 'installation.json') -Raw | ConvertFrom-Json
if ((Get-FileHash -LiteralPath (Join-Path $record.backupDir 'SaveGames\CharacterFixture.sav')).Hash -ne $saveHash) { throw 'Backup did not match save.' }
Run-Case 'check installed content' 'Check' 0
Run-Case 'refuse duplicate install' 'Install' 1
Run-Case 'reject uninstall while game runs' 'Uninstall' 1 1
$installed = Join-Path $mods 'LanDirect\LanDirect_P.pak'
[IO.File]::AppendAllText($installed,'changed')
Run-Case 'refuse uninstall of changed file' 'Uninstall' 1
Copy-Item -LiteralPath (Join-Path $package 'LanDirect_P.pak') -Destination $installed -Force
Run-Case 'uninstall exact owned files' 'Uninstall' 0
foreach ($name in @('pak','utoc','ucas')) {
    if (Test-Path -LiteralPath (Join-Path $mods "LanDirect\LanDirect_P.$name")) { throw 'Uninstall left a resource behind.' }
}
if (-not (Test-Path -LiteralPath (Join-Path $mods 'BlueprintLoader-test.pak'))) { throw 'Loader was removed.' }
if ((Get-FileHash -LiteralPath (Join-Path $save 'CharacterFixture.sav')).Hash -ne $saveHash) { throw 'Save was modified.' }
[IO.File]::AppendAllText((Join-Path $package 'LanDirect_P.pak'),'tampered')
Run-Case 'reject tampered package' 'Install' 1
Copy-Item -LiteralPath (Join-Path $root 'artifacts\LanDirect-0.1.0\LanDirect_P.pak') -Destination $package -Force
[IO.File]::AppendAllText($exe,'different-build')
Run-Case 'reject unsupported game build' 'Install' 1
Write-Host 'All isolated installer checks passed. No real game or save files were touched.'
# The final expected rejection exits 1; reset it for GitHub's dot-sourced wrapper.
exit 0
