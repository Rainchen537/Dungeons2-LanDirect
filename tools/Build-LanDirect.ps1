$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskDotnet = Join-Path $taskRoot 'dependencies\dotnet\dotnet.exe'
if (-not (Test-Path -LiteralPath $taskDotnet)) { $taskDotnet = (Get-Command dotnet -ErrorAction Stop).Source }
$env:PATH = (Split-Path -Parent $taskDotnet) + ';' + $env:PATH
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
& $taskDotnet build (Join-Path $taskRoot 'mods\LanDirect\LanDirect.csproj') --nologo
if ($LASTEXITCODE -ne 0) { throw "Build failed: $LASTEXITCODE" }
$taskPackage = Join-Path $taskRoot 'artifacts\LanDirect-0.1.0'
New-Item -ItemType Directory -Path $taskPackage -Force | Out-Null
$taskHashes = @()
foreach ($taskExtension in @('pak', 'utoc', 'ucas')) {
    $taskName = "LanDirect_P.$taskExtension"
    $taskSource = Join-Path $taskRoot "mods\LanDirect\bin\NeoRune\Pak\$taskName"
    $taskTarget = Join-Path $taskPackage $taskName
    Copy-Item -LiteralPath $taskSource -Destination $taskTarget -Force
    $taskHash = (Get-FileHash -LiteralPath $taskSource -Algorithm SHA256).Hash
    if ((Get-FileHash -LiteralPath $taskTarget -Algorithm SHA256).Hash -ne $taskHash) { throw 'Package copy hash mismatch.' }
    $taskHashes += [pscustomobject]@{ name=$taskName; sha256=$taskHash; length=(Get-Item -LiteralPath $taskTarget).Length }
}
[pscustomobject]@{ version='0.1.0'; gameBuild='25647713'; sdk='NeoRune.Sdk/0.4.2'; runtimeVerified=$false; files=$taskHashes } |
    ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $taskPackage 'manifest.json') -Encoding UTF8
Write-Host "Experimental package: $taskPackage"
