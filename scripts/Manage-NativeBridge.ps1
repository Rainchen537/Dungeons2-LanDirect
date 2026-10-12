param(
    [ValidateSet('Install','Repair','Uninstall','Check')][string]$Action='Check',
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
function Read-Config($Path) {
    if (Test-Path -LiteralPath $Path) { return [IO.File]::ReadAllText($Path) }
    return ''
}
function Original-Config($Ini) {
    # Remove only the exact block installed by this package; keep surrounding settings.
    $pattern='(?m)^; BEGIN LAN Direct server streaming\r?\nwp\.Runtime\.EnableServerStreaming=1\r?\nwp\.Runtime\.EnableServerStreamingOut=1\r?\n; END LAN Direct server streaming\r?\n?'
    $result=[regex]::Replace($Ini,$pattern,'')
    if ($result -match 'BEGIN LAN Direct server streaming|END LAN Direct server streaming') { throw 'LAN Direct 配置块已改动，请先核对该配置块。' }
    if ($result -match '(?m)^\s*wp\.Runtime\.EnableServerStreaming(?:Out)?\s*=') { throw '发现自定义服务器流送设置，请先核对现有配置。' }
    return $result
}
function Streaming-Config($Ini) {
    $block="; BEGIN LAN Direct server streaming`r`nwp.Runtime.EnableServerStreaming=1`r`nwp.Runtime.EnableServerStreamingOut=1`r`n; END LAN Direct server streaming`r`n"
    $section=[regex]::Match($Ini,'(?im)^\[SystemSettings\][^\r\n]*(?:\r?\n|$)')
    if ($section.Success) {
        $prefix=''
        if (-not $section.Value.EndsWith("`n")) { $prefix="`r`n" }
        return $Ini.Insert($section.Index+$section.Length,$prefix+$block)
    }
    return $Ini+"`r`n[SystemSettings]`r`n"+$block
}
function Unlock-Config($Path) {
    if (Test-Path -LiteralPath $Path) {
        $attributes=[IO.File]::GetAttributes($Path)
        [IO.File]::SetAttributes($Path,($attributes -band (-bnot [IO.FileAttributes]::ReadOnly)))
    }
}
function Check-StreamingConfig($Path) {
    $ini=Read-Config $Path
    $inSection=$false
    $values=@{'wp.Runtime.EnableServerStreaming'=@();'wp.Runtime.EnableServerStreamingOut'=@()}
    foreach ($line in ($ini -split '\r?\n')) {
        if ($line -match '^\s*\[([^\]]+)\]') { $inSection=$Matches[1] -eq 'SystemSettings'; continue }
        if ($inSection -and $line -match '^\s*(wp\.Runtime\.EnableServerStreaming(?:Out)?)\s*=\s*(.*?)\s*$') {
            $values[$Matches[1]]+=@($Matches[2])
        }
    }
    foreach ($key in $values.Keys) {
        if ($values[$key].Count -ne 1 -or $values[$key][0] -ne '1') { throw "服务器流送配置无效：$key；请运行 Repair.cmd。" }
    }
    if (-not ([IO.File]::GetAttributes($Path) -band [IO.FileAttributes]::ReadOnly)) { throw 'Engine.ini 写入保护未启用，请运行 Repair.cmd。' }
}
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
            Unlock-Config $state.configPath
            Move-Item -LiteralPath $state.configPath -Destination (Join-Path $disabled 'Engine.ini')
        }
        if ($state.configExisted) {
            $original=Join-Path $state.backupDir 'Engine.ini'
            if ((Hash $original) -ne $state.originalConfigSha256) { throw '原配置备份校验失败。' }
            Copy-Item -LiteralPath $original -Destination $state.configPath
            if ($null -ne $state.originalConfigAttributes) { [IO.File]::SetAttributes($state.configPath,[IO.FileAttributes]$state.originalConfigAttributes) }
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
        Check-StreamingConfig $config
        Write-Host '原生桥接、游戏版本、服务器流送配置和写入保护检查通过。'
        exit 0
    }
    Assert-Closed
    $previous=$null
    if ($Action -eq 'Repair') {
        $previous=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        if ($previous.gameRoot -ne $GameRoot -or $previous.configPath -ne $config -or $previous.dllSha256 -ne $manifest.sha256 -or (Hash $dll) -ne $manifest.sha256) { throw '安装记录或原生 DLL 与当前包不匹配。' }
    } elseif ((Test-Path -LiteralPath $dll) -or (Test-Path -LiteralPath $statePath)) { throw '已有 dwmapi.dll 或原生桥接安装记录；升级配置请运行 Repair.cmd。' }
    $save=Join-Path $env:LOCALAPPDATA 'Dungeons2\Saved\SaveGames'
    if (-not (Test-Path -LiteralPath $save)) { throw '请先创建离线英雄并退出游戏。' }
    $existed=Test-Path -LiteralPath $config
    $ini=''
    if ($existed) { $ini=[IO.File]::ReadAllText($config) }
    $baseline=Original-Config $ini
    $attributes=[IO.FileAttributes]::Normal
    if ($existed) { $attributes=[IO.File]::GetAttributes($config) }
    $originalAttributes=$attributes
    if ($previous -and $previous.configProtected) {
        $originalAttributes=$attributes -band (-bnot [IO.FileAttributes]::ReadOnly)
        if ($existed -and ($previous.originalConfigAttributes -band [IO.FileAttributes]::ReadOnly)) {
            $originalAttributes=$originalAttributes -bor [IO.FileAttributes]::ReadOnly
        }
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
        Copy-Item -LiteralPath $config -Destination (Join-Path $backup 'Engine.before-repair.ini')
        if ((Hash (Join-Path $backup 'Engine.before-repair.ini')) -ne (Hash $config)) { throw '配置备份校验失败。' }
        if ($previous -and (Hash $config) -eq $previous.configSha256 -and $previous.configExisted) {
            $original=Join-Path $previous.backupDir 'Engine.ini'
            if ((Hash $original) -ne $previous.originalConfigSha256) { throw '原配置备份校验失败。' }
            Copy-Item -LiteralPath $original -Destination (Join-Path $backup 'Engine.ini')
        }
        elseif ($baseline -ceq ([IO.File]::ReadAllText($config))) { Copy-Item -LiteralPath $config -Destination (Join-Path $backup 'Engine.ini') }
        else { [IO.File]::WriteAllText((Join-Path $backup 'Engine.ini'),$baseline,(New-Object Text.UTF8Encoding($false))) }
        $originalHash=Hash (Join-Path $backup 'Engine.ini')
    }
    if ($previous) { Copy-Item -LiteralPath $statePath -Destination (Join-Path $backup 'installation.before-repair.json') }
    $ini=Streaming-Config $baseline
    $prepared=Join-Path $backup 'Engine.installed.ini'
    [IO.File]::WriteAllText($prepared,$ini,(New-Object Text.UTF8Encoding($false)))
    $record=[pscustomobject]@{gameRoot=$GameRoot;dllSha256=$manifest.sha256;configPath=$config;configExisted=$existed;originalConfigAttributes=[int]$originalAttributes;configProtected=$true;originalConfigSha256=$originalHash;configSha256=(Hash $prepared);backupDir=$backup}
    try {
        if (-not $previous) { Copy-Item -LiteralPath $source -Destination $dll }
        if ((Hash $dll) -ne $manifest.sha256) { throw '原生桥接写入校验失败。' }
        New-Item -ItemType Directory -Path (Split-Path -Parent $config) -Force | Out-Null
        Unlock-Config $config
        Copy-Item -LiteralPath $prepared -Destination $config
        if ((Hash $config) -ne $record.configSha256) { throw '配置写入校验失败。' }
        [IO.File]::SetAttributes($config,($attributes -bor [IO.FileAttributes]::ReadOnly))
        Check-StreamingConfig $config
        $record | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8
    } catch {
        Unlock-Config $config
        if ($existed) {
            Copy-Item -LiteralPath (Join-Path $backup 'Engine.before-repair.ini') -Destination $config -Force
            [IO.File]::SetAttributes($config,$attributes)
        } elseif (Test-Path -LiteralPath $config) { Remove-Item -LiteralPath $config }
        if ($previous) { Copy-Item -LiteralPath (Join-Path $backup 'installation.before-repair.json') -Destination $statePath -Force }
        else {
            if (Test-Path -LiteralPath $dll) { Remove-Item -LiteralPath $dll }
            if (Test-Path -LiteralPath $statePath) { Remove-Item -LiteralPath $statePath }
        }
        throw
    }
    Write-Host "原生桥接安装完成。存档和配置备份：$backup"
} catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
