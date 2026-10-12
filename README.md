# LanDirect · 地下城 II 局域网直连实验

让两台 Windows 电脑通过 IPv4:端口测试离线英雄联机，保留原版“开始游戏”流程与游戏 UI。当前版本 **0.1.1**，支持 Steam 构建 **25754144 / 1.1.2.0**；0.1.0 是针对旧构建的历史实验。

旧原生候选已在本机建立菜单和主世界监听，并在开启服务器流送后成功进入一次地牢。0.1.1 包含清理后重新编译的原生桥接，尚待运行回归。**第二台电脑加入、离线角色身份、同步、共同过图和双方保存都未验证。** 首次测试请使用测试英雄。

## 两台电脑都要安装

从 [0.1.1 Release](https://github.com/Rainchen537/Dungeons2-LanDirect/releases/tag/v0.1.1) 下载两个 ZIP，分别完整解压：

1. `NativeBridge-0.1.1-windows.zip`：本项目原创原生前置，不需要 UE4SS、MinHook 或 .NET。退出游戏后双击其 `Install.cmd`，输入 Steam 游戏根目录。它备份最新存档和 Engine.ini，安装原生桥接并启用地牢所需服务器流送设置。
2. **Blueprint Loader**：从 [作者官方下载页](https://www.nexusmods.com/minecraftdungeons2/mods/2?tab=files) 下载，按包内说明安装。旧本机验证用 2.3，2026-10-12 作者页最新版是 2.5；2.5 与本项目尚未回归验证。双方必须使用相同版本。作者明确禁止站外转载，因此 GitHub 不附其原包；历史原包校验见 [依赖记录](vendor/blueprint-loader/README.md)。
3. `LanDirect-0.1.1-windows.zip`：双击其 `Install.cmd` 安装蓝图 Mod。安装器检查游戏、原生前置和 Blueprint Loader，再备份存档并安装。不要只下载 Source code。

已手动安装旧候选的电脑：先备份、移走旧 LanDirect 三个资源和旧 `dwmapi.dll`；保留 Engine.ini 后移除原有两项服务器流送设置，再安装新包。脚本拒绝覆盖已有 DLL、Mod 或流送设置，不会主动关闭游戏。无需安装 UE4SS 或额外 Native Loader。

## 同一局域网测试

双方选择离线英雄。主机点击“本地开服”，默认端口 `7777`；大厅建立后点击原版“开始游戏”。用 `ipconfig` 找正在使用的无线/以太网 IPv4，例如 `192.168.1.10`。

朋友在主菜单点击“加入本地游戏”，输入 `192.168.1.10:7777`。`127.0.0.1` 指自己，不能加入朋友。Windows 防火墙提示时允许专用网络通信；安装器不改防火墙。

按顺序确认加入、双方移动与战斗、拾取、共同进入和离开地牢，最后分别正常退出重进检查角色保存。某一步失败就记录双方版本、提示和日志，不能把监听端口当作联机成功。完整步骤见 [测试指南](docs/TESTING.md) 和 [已知问题](docs/KNOWN_ISSUES.md)。

## 检查与停用

两个解压包各有 `Check.cmd` 与 `Uninstall.cmd`。先停用 LanDirect 蓝图，再停用 NativeBridge。不会恢复旧存档。原生包会恢复安装前的 Engine.ini；如有后续配置修改，会拒绝覆盖，手动处理方法见 [原生桥接说明](docs/NATIVE_BRIDGE.md)。

备份位置：`%LOCALAPPDATA%\Dungeons2LanDirect`，安装窗口会显示具体路径。原生日志：游戏 `Dungeons\Binaries\Win64\LanDirect-native.log`。提交 [Issue](https://github.com/Rainchen537/Dungeons2-LanDirect/issues) 时提供操作步骤和提示，分享日志前去除私人信息，勿上传存档或崩溃转储。

## 源码构建

需要 .NET 10 SDK 与 MinGW-w64 的 `g++`。NeoRune SDK 固定为 `0.4.2`。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Build-NativeBridge.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Build-LanDirect.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Package-LanDirect.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Package-NativeBridge.ps1
```

原生源码在 `mods/NativeBridge`，菜单和角色检查在 `mods/LanDirect`。游戏 EXE SHA-256 固定为 `3a8703406fd50520f83c4f70a0212c000cb3b584ef28eb38032902230c01ebdd`；不适用其他构建。

本仓库原创代码使用 [MIT](LICENSE)，第三方说明见 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。不包含游戏本体、玩家存档或 Blueprint Loader 原包。非官方项目。