param(
    [ValidateSet('Install','Uninstall','Check')][string]$Action = 'Check',
    [string]$GameRoot,
    [string]$PackageRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'package'),
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'Dungeons2LanDirect'),
    [switch]$NonInteractive
)
$ErrorActionPreference = 'Stop'
$expectedExe = '3a8703406fd50520f83c4f70a0212c000cb3b584ef28eb38032902230c01ebdd'
$names = @('LanDirect_P.pak','LanDirect_P.utoc','LanDirect_P.ucas')
$statePath = Join-Path $StateRoot 'installation.json'
function Find-Game {
    $roots = @()
    foreach ($key in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')) {
        $entry = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
        if ($entry.SteamPath) { $roots += $entry.SteamPath }
        if ($entry.InstallPath) { $roots += $entry.InstallPath }
    }
    $libraries = @($roots)
    foreach ($root in $roots) {
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            $content = Get-Content -LiteralPath $vdf -Raw
            foreach ($match in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
                $libraries += $match.Groups[1].Value.Replace('\\','\')
            }
        }
    }
    $found = @($libraries | Select-Object -Unique | ForEach-Object {
        $candidate = Join-Path $_ 'steamapps\common\Minecraft Dungeons II'
        if (Test-Path -LiteralPath (Join-Path $candidate 'Dungeons\Binaries\Win64\Dungeons-Win64-Shipping.exe')) { $candidate }
    })
    if ($found.Count -eq 1) { return $found[0] }
    if ($NonInteractive) { throw '无法唯一确定游戏目录，请传入 -GameRoot。' }
    return (Read-Host '请输入 Steam 游戏根目录（包含 Dungeons 文件夹）').Trim().Trim('"')
}
function Assert-Closed {
    if (Get-Process -Name 'Dungeons','Dungeons-Win64-Shipping' -ErrorAction SilentlyContinue | Where-Object { -not $_.HasExited }) {
        throw '请先退出游戏，再运行此操作。脚本不会关闭游戏。'
    }
}
function Read-Package {
    $manifest = Get-Content -LiteralPath (Join-Path $PackageRoot 'manifest.json') -Raw | ConvertFrom-Json
    if (@($manifest.files).Count -ne 3) { throw '安装包必须包含三个资源文件。' }
    if (@($manifest.files.name | Select-Object -Unique).Count -ne 3) { throw '安装包存在重复文件。' }
    foreach ($file in $manifest.files) {
        if ($file.name -cnotin $names) { throw '安装包文件名不正确。' }
        $path = Join-Path $PackageRoot $file.name
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $file.sha256) { throw "安装包校验失败：$($file.name)" }
    }
    return $manifest
}
try {
    if ($Action -eq 'Uninstall') {
        Assert-Closed
        $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        $target = Join-Path $state.gameRoot 'Dungeons\Content\Paks\~mods\LanDirect'
        if (@($state.files).Count -ne 3 -or @($state.files.name | Select-Object -Unique).Count -ne 3) { throw '安装记录无效。' }
        foreach ($file in $state.files) {
            if ($file.name -cnotin $names) { throw '安装记录文件名无效。' }
            $path = Join-Path $target $file.name
            if ((Test-Path -LiteralPath $path) -and (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $file.sha256) {
                throw "文件已被修改，未卸载：$($file.name)"
            }
        }
        $disabled = Join-Path $StateRoot ('disabled\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
        New-Item -ItemType Directory -Path $disabled -Force | Out-Null
        foreach ($file in $state.files) {
            $path = Join-Path $target $file.name
            if (Test-Path -LiteralPath $path) { Move-Item -LiteralPath $path -Destination (Join-Path $disabled $file.name) }
        }
        Write-Host "已停用 LanDirect，资源保存在：$disabled"
        Write-Host '存档没有被恢复或覆盖。'
        exit 0
    }
    $manifest = Read-Package
    if (-not $GameRoot) { $GameRoot = Find-Game }
    $GameRoot = (Resolve-Path -LiteralPath $GameRoot).Path
    $exe = Join-Path $GameRoot 'Dungeons\Binaries\Win64\Dungeons-Win64-Shipping.exe'
    if ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne $expectedExe) { throw '游戏版本不匹配；本版仅验证 Steam 构建 25647713。' }
    $mods = Join-Path $GameRoot 'Dungeons\Content\Paks\~mods'
    if (-not (Get-ChildItem -LiteralPath $mods -Filter '*BlueprintLoader*.pak' -Recurse -File -ErrorAction SilentlyContinue)) {
        throw '请先安装 Blueprint Loader 2.3：https://www.nexusmods.com/minecraftdungeons2/mods/2'
    }
    $target = Join-Path $mods 'LanDirect'
    if ($Action -eq 'Check') {
        Write-Host "安装包、游戏版本和加载器检查通过。游戏目录：$GameRoot"
        foreach ($file in $manifest.files) {
            $path = Join-Path $target $file.name
            $result = '未安装'
            if (Test-Path -LiteralPath $path) {
                $result = '内容不同'
                if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $file.sha256) { $result = '匹配当前安装包' }
            }
            Write-Host "$($file.name)：$result"
        }
        exit 0
    }
    Assert-Closed
    if (Test-Path -LiteralPath $statePath) {
        $old = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        if ($old.gameRoot -ne $GameRoot) { throw '已有另一游戏目录的安装记录，请先卸载旧安装。' }
    }
    foreach ($name in $names) {
        if (Test-Path -LiteralPath (Join-Path $target $name)) { throw '已有 LanDirect 资源，请先使用对应版本卸载。不会覆盖现有文件。' }
    }
    $save = Join-Path $env:LOCALAPPDATA 'Dungeons2\Saved\SaveGames'
    if (-not (Test-Path -LiteralPath $save)) { throw '没有找到存档。请先正常启动游戏并创建离线英雄，再退出游戏。' }
    $backup = Join-Path $StateRoot ('backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Copy-Item -LiteralPath $save -Destination $backup -Recurse
    $hashes = @(foreach ($file in Get-ChildItem -LiteralPath $save -Recurse -File) {
        $relative = $file.FullName.Substring($save.Length).TrimStart('\')
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        $copy = Join-Path (Join-Path $backup 'SaveGames') $relative
        if ((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -ne $hash) { throw '存档备份校验失败，未安装。' }
        [pscustomobject]@{ relativePath=$relative; sha256=$hash }
    })
    $hashes | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $backup 'save-hashes.json') -Encoding UTF8
    # Persist the exact target list before copying, allowing partial installs to be disabled.
    [pscustomobject]@{ version=$manifest.version; gameRoot=$GameRoot; backupDir=$backup; files=$manifest.files } |
        ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statePath -Encoding UTF8
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    foreach ($file in $manifest.files) {
        $path = Join-Path $target $file.name
        Copy-Item -LiteralPath (Join-Path $PackageRoot $file.name) -Destination $path
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $file.sha256) { throw "安装校验失败：$($file.name)，请运行卸载脚本。" }
    }
    Write-Host "安装完成。存档备份：$backup"
    Write-Host '通过 Steam 启动，选择离线英雄后使用主菜单的本地开服或加入本地游戏。'
    Write-Host '这是实验版：双机加入、同步和双方保存尚未验证。'
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
