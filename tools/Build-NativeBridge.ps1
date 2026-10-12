param([string]$Compiler = 'g++')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'mods\NativeBridge'
$work = Join-Path $env:TEMP ('LanDirectNative-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
foreach ($name in @('bridge.cpp','bridge.inc','forwarders.cpp','dwmapi.def')) {
    Copy-Item -LiteralPath (Join-Path $source $name) -Destination $work
}
$output = Join-Path $root 'artifacts\NativeBridge-0.1.1'
New-Item -ItemType Directory -Path $output -Force | Out-Null
& $Compiler -std=c++17 -O2 -shared -static -static-libgcc -static-libstdc++ -Wall -Wextra (Join-Path $work 'bridge.cpp') (Join-Path $work 'forwarders.cpp') (Join-Path $work 'dwmapi.def') -lbcrypt -o (Join-Path $work 'dwmapi.dll')
if ($LASTEXITCODE -ne 0) { throw 'Native bridge build failed.' }
Copy-Item -LiteralPath (Join-Path $work 'dwmapi.dll') -Destination $output -Force
$dll = Join-Path $output 'dwmapi.dll'
[pscustomobject]@{
    version='0.1.1'; gameBuild='25754144'
    gameExeSha256='3a8703406fd50520f83c4f70a0212c000cb3b584ef28eb38032902230c01ebdd'
    sha256=(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'manifest.json') -Encoding UTF8
Write-Host "Built native bridge: $dll"
