param(
    [ValidateSet('Install','Uninstall','Check')][string]$Action='Check',
    [string]$GameRoot,
    [string]$PackageRoot=(Join-Path (Split-Path -Parent $PSScriptRoot) 'native'),
    [string]$StateRoot=(Join-Path $env:LOCALAPPDATA 'Dungeons2LanDirect\native'),
    [switch]$NonInteractive
)
$ErrorActionPreference='Stop'
$expectedExe='3a8703406fd50520f83c4f70a0212c000cb3b584ef28eb38032902230c01ebdd'
$statePath=Join-Path $StateRoot 'installation.json'
function Assert-Closed {
    if (Get-Process -Name 'Dungeons','Dungeons-Win64-Shipping' -ErrorAction SilentlyContinue) { throw '请先退出游戏。脚本不会关闭游戏。' }
}
function Hash($Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
try {
    if ($Action -eq 'Uninstall') {
        Assert-Closed
        $state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        $dll=Join-Path $state.gameRoot 'Dungeons\Binaries\Win64\dwmapi.dll'
        if ((Test-Path -LiteralPath $dll) -and (Hash $dll) -ne $state.dllSha256) { throw 'dwmapi.dll 已被修改，未移动文件或恢复配置。' }
        if ($state.configSha256 -and (Test-Path -LiteralPath $state.configPath) -and (Hash $state.configPath) -ne $state.configSha256) {
            throw 'Engine.ini 已有后续变更，未移动文件或恢复配置。请先保留当前配置并手动移除 LAN Direct 配置块。'
        }
        if ($state.configExisted -and (Hash (Join-Path $state.backupDir 'Engine.ini')) -ne $state.originalConfigSha256) { throw '原配置备份校验失败，未移动文件。' }
        $disabled=Join-Path $StateRoot ('disabled\'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
        New-Item -ItemType Directory -Path $disabled -Force | Out-Null
        if (Test-Path -LiteralPath $dll) { Move-Item -LiteralPath $dll -Destination (Join-Path $disabled 'dwmapi.dll') }
        if ($state.configSha256 -and (Test-Path -LiteralPath $state.configPath)) {
            Move-Item -LiteralPath $state.configPath -Destination (Join-Path $disabled 'Engine.ini')
        }
        if ($state.configExisted) {
            $original=Join-Path $state.backupDir 'Engine.ini'
            if ((Hash $original) -ne $state.originalConfigSha256) { throw '原配置备份校验失败。' }
            Copy-Item -LiteralPath $original -Destination $state.configPath
        }
        Move-Item -LiteralPath $statePath -Destination (Join-Path $disabled 'installation.json')
        Write-Host "原生桥接已停用，配置已恢复。存档未恢复。保留文件：$disabled"
        exit 0
    }
    $manifest=Get-Content -LiteralPath (Join-Path $PackageRoot 'manifest.json') -Raw | ConvertFrom-Json
    $source=Join-Path $PackageRoot 'dwmapi.dll'
    if ((Hash $source) -ne $manifest.sha256) { throw '原生桥接包校验失败。' }
    if (-not $GameRoot) {
        if ($NonInteractive) { throw '请传入 -GameRoot。' }
        $GameRoot=(Read-Host '请输入 Steam 游戏根目录（包含 Dungeons 文件夹）').Trim().Trim('"')
    }
    $GameRoot=(Resolve-Path -LiteralPath $GameRoot).Path
    $exe=Join-Path $GameRoot 'Dungeons\Binaries\Win64\Dungeons-Win64-Shipping.exe'
    if ((Hash $exe) -ne $expectedExe) { throw '游戏版本不匹配，仅支持 Steam 构建 25754144。' }
    $dll=Join-Path $GameRoot 'Dungeons\Binaries\Win64\dwmapi.dll'
    $config=Join-Path $env:LOCALAPPDATA 'Dungeons2\Saved\Config\Windows\Engine.ini'
    if ($Action -eq 'Check') {
        if (-not (Test-Path -LiteralPath $dll) -or (Hash $dll) -ne $manifest.sha256) { throw '原生桥接未安装或与本包不同。' }
        $ini=Get-Content -LiteralPath $config -Raw
        foreach ($key in @('wp.Runtime.EnableServerStreaming','wp.Runtime.EnableServerStreamingOut')) {
            if ($ini -notmatch ('(?m)^'+[regex]::Escape($key)+'=1\s*$')) { throw "缺少服务器流送设置：$key" }
        }
        Write-Host '原生桥接、游戏版本和服务器流送配置检查通过；双机行为仍需游戏内验证。'
        exit 0
    }
    Assert-Closed
    if ((Test-Path -LiteralPath $dll) -or (Test-Path -LiteralPath $statePath)) { throw '已有 dwmapi.dll 或原生桥接安装记录。不会覆盖其他加载器；请先停用对应安装。' }
    $save=Join-Path $env:LOCALAPPDATA 'Dungeons2\Saved\SaveGames'
    if (-not (Test-Path -LiteralPath $save)) { throw '请先创建离线英雄并退出游戏。' }
    $existed=Test-Path -LiteralPath $config
    $ini=''
    if ($existed) { $ini=[IO.File]::ReadAllText($config) }
    if ($ini -match '(?m)^\s*wp\.Runtime\.EnableServerStreaming(?:Out)?\s*=') {
        throw '已有服务器流送设置，请先保留配置并移除原设置，避免重复覆盖。'
    }
    $backup=Join-Path $StateRoot ('backups\'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Copy-Item -LiteralPath $save -Destination $backup -Recurse
    $hashes=@(foreach ($file in Get-ChildItem -LiteralPath $save -File -Recurse) {
        $relative=$file.FullName.Substring($save.Length).TrimStart('\')
        $hash=Hash $file.FullName
        if ((Hash (Join-Path (Join-Path $backup 'SaveGames') $relative)) -ne $hash) { throw '存档备份校验失败。' }
        [pscustomobject]@{relativePath=$relative;sha256=$hash}
    })
    $hashes | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $backup 'save-hashes.json') -Encoding UTF8
    $originalHash=''
    if ($existed) {
        Copy-Item -LiteralPath $config -Destination (Join-Path $backup 'Engine.ini')
        $originalHash=Hash $config
        if ((Hash (Join-Path $backup 'Engine.ini')) -ne $originalHash) { throw '配置备份校验失败。' }
    }
    # Insert into the existing SystemSettings section, without duplicating a section.
    $block="; BEGIN LAN Direct server streaming`r`nwp.Runtime.EnableServerStreaming=1`r`nwp.Runtime.EnableServerStreamingOut=1`r`n; END LAN Direct server streaming`r`n"
    $section=[regex]::Match($ini,'(?im)^\[SystemSettings\][^\r\n]*(?:\r?\n|$)')
    if ($section.Success) { $ini=$ini.Insert($section.Index+$section.Length,"`r`n"+$block) }
    else { $ini+="`r`n[SystemSettings]`r`n"+$block }
    $prepared=Join-Path $backup 'Engine.installed.ini'
    [IO.File]::WriteAllText($prepared,$ini,(New-Object Text.UTF8Encoding($false)))
    $record=[pscustomobject]@{gameRoot=$GameRoot;dllSha256=$manifest.sha256;configPath=$config;configExisted=$existed;originalConfigSha256=$originalHash;configSha256=(Hash $prepared);backupDir=$backup}
    $record | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8
    Copy-Item -LiteralPath $source -Destination $dll
    if ((Hash $dll) -ne $manifest.sha256) { throw '原生桥接写入校验失败。请运行停用脚本。' }
    New-Item -ItemType Directory -Path (Split-Path -Parent $config) -Force | Out-Null
    Copy-Item -LiteralPath $prepared -Destination $config
    if ((Hash $config) -ne $record.configSha256) { throw '配置写入校验失败。' }
    $record | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8
    Write-Host "原生桥接安装完成。存档和配置备份：$backup"
} catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
