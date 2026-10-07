$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = ([xml](Get-Content -LiteralPath (Join-Path $root 'mods\LanDirect\LanDirect.csproj') -Raw)).Project.PropertyGroup.Version
$source = Join-Path $root "artifacts\LanDirect-$version"
$manifest = Get-Content -LiteralPath (Join-Path $source 'manifest.json') -Raw | ConvertFrom-Json
$stage = Join-Path $root ('artifacts\release-staging-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $stage 'package') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stage 'scripts') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stage 'docs') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stage 'licenses') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $stage 'vendor\blueprint-loader') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'vendor\blueprint-loader\README.md') -Destination (Join-Path $stage 'vendor\blueprint-loader')
Copy-Item -LiteralPath (Join-Path $root 'licenses\NeoRune-MIT.txt') -Destination (Join-Path $stage 'licenses')
foreach ($file in $manifest.files) {
    if ($file.name -notmatch '^LanDirect_P\.(pak|utoc|ucas)$') { throw 'Unexpected package filename.' }
    $path = Join-Path $source $file.name
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $file.sha256) { throw 'Package hash mismatch.' }
    Copy-Item -LiteralPath $path -Destination (Join-Path $stage 'package')
}
Copy-Item -LiteralPath (Join-Path $source 'manifest.json') -Destination (Join-Path $stage 'package')
foreach ($name in @('Install.cmd','Uninstall.cmd','Check.cmd','README.md','LICENSE','THIRD-PARTY-NOTICES.md','CHANGELOG.md')) {
    Copy-Item -LiteralPath (Join-Path $root $name) -Destination $stage
}
Copy-Item -LiteralPath (Join-Path $root 'docs\TESTING.md') -Destination (Join-Path $stage 'docs')
Copy-Item -LiteralPath (Join-Path $root 'docs\KNOWN_ISSUES.md') -Destination (Join-Path $stage 'docs')
$script = Join-Path $root 'scripts\Manage-LanDirect.ps1'
# Windows PowerShell 5.1 requires BOM to read Chinese source consistently.
[IO.File]::WriteAllText((Join-Path $stage 'scripts\Manage-LanDirect.ps1'), [IO.File]::ReadAllText($script), (New-Object Text.UTF8Encoding($true)))
$zip = Join-Path $root "artifacts\LanDirect-$version-windows.zip"
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($zip)
try {
    foreach ($file in $manifest.files) {
        $entry = $archive.Entries | Where-Object { $_.FullName.Replace('\','/') -eq ('package/' + $file.name) }
        if (-not $entry) { throw 'ZIP entry missing.' }
        $stream = $entry.Open()
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','') }
        finally { $stream.Dispose(); $sha.Dispose() }
        if ($hash -ne $file.sha256) { throw 'ZIP content hash mismatch.' }
    }
} finally { $archive.Dispose() }
$zipHash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $root 'artifacts\SHA256SUMS.txt'), "$zipHash  $([IO.Path]::GetFileName($zip))`n", (New-Object Text.UTF8Encoding($false)))
Write-Host "Verified release archive: $zip"
