param([string]$Compiler='C:\msys64\ucrt64\bin\g++.exe')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$source=Join-Path $root 'mods\NativeBridge'
$work=Join-Path $env:TEMP ('LanDirectOfflineGate-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
foreach($name in @('bridge.cpp','bridge.inc','host_guard.inc','experimental_offline_gate.inc','experimental_lan_guard.inc','experimental_loot_visibility.inc','forwarders.cpp','dwmapi.def')) {
    Copy-Item -LiteralPath (Join-Path $source $name) -Destination $work
}
$include=Join-Path $work 'bridge.inc'
$code=Get-Content -LiteralPath $include -Raw
$code=$code.Replace('#include "host_guard.inc"', "#include `"host_guard.inc`"`r`n#include `"experimental_offline_gate.inc`"`r`n#include `"experimental_lan_guard.inc`"`r`n#include `"experimental_loot_visibility.inc`"")
$code=$code.Replace('    ObserveNetwork(world,gi);', "    TryOfflineGateExperiment();`r`n    TryLanJoinGuard();`r`n    TryLootVisibilityExperiment();`r`n    ObserveNetwork(world,gi);")
$code=$code.Replace('; no code hooks','; offline gate experimental build')
[IO.File]::WriteAllText($include,$code)
$output=Join-Path $root 'artifacts\OfflineGate-experiment'
New-Item -ItemType Directory -Path $output -Force | Out-Null
& $Compiler -std=c++17 -O2 -shared -static -static-libgcc -static-libstdc++ -Wall -Wextra (Join-Path $work 'bridge.cpp') (Join-Path $work 'forwarders.cpp') (Join-Path $work 'dwmapi.def') -lbcrypt -o (Join-Path $work 'dwmapi.dll')
if($LASTEXITCODE -ne 0){throw 'Experimental build failed'}
Copy-Item -LiteralPath (Join-Path $work 'dwmapi.dll') -Destination $output -Force
Get-FileHash -LiteralPath (Join-Path $output 'dwmapi.dll')
