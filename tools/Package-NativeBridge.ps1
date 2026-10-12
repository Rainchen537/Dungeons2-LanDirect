$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$version=([xml](Get-Content -LiteralPath (Join-Path $root 'mods\LanDirect\LanDirect.csproj') -Raw)).Project.PropertyGroup.Version
$stage=Join-Path $root ('artifacts\native-staging-'+[guid]::NewGuid().ToString('N'))
foreach ($dir in @('native','scripts')) { New-Item -ItemType Directory -Path (Join-Path $stage $dir) -Force | Out-Null }
Copy-Item -LiteralPath (Join-Path $root "artifacts\NativeBridge-$version\dwmapi.dll"),(Join-Path $root "artifacts\NativeBridge-$version\manifest.json") -Destination (Join-Path $stage 'native')
Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination $stage
Copy-Item -LiteralPath (Join-Path $root 'docs\NATIVE_BRIDGE.md') -Destination (Join-Path $stage 'README.md')
$script=[IO.File]::ReadAllText((Join-Path $root 'scripts\Manage-NativeBridge.ps1'))
[IO.File]::WriteAllText((Join-Path $stage 'scripts\Manage-NativeBridge.ps1'),$script,(New-Object Text.UTF8Encoding($true)))
foreach ($action in @('Install','Repair','Uninstall','Check')) {
    $cmd='@echo off'+"`r`n"+'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Manage-NativeBridge.ps1" -Action '+$action+"`r`n"+'set "result=%errorlevel%"'+"`r`n"+'pause'+"`r`n"+'exit /b %result%'+"`r`n"
    [IO.File]::WriteAllText((Join-Path $stage ($action+'.cmd')),$cmd)
}
$zip=Join-Path $root "artifacts\NativeBridge-$version-windows.zip"
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
$sum=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()+'  '+[IO.Path]::GetFileName($zip)+"`n"
[IO.File]::AppendAllText((Join-Path $root 'artifacts\SHA256SUMS.txt'),$sum,(New-Object Text.UTF8Encoding($false)))
Write-Host "Packaged native prerequisite: $zip"
