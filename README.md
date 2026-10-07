# LanDirect · 地下城 II 局域网直连

让离线英雄在**主菜单**点击“本地开服”，另一台电脑输入 **IPv4:端口** 加入。按钮、弹窗边框、标题和确认按钮引用游戏原版 UI，普通“开始游戏”入口仍保留。

**当前为 0.1.0 实验版，尚不能保证双机联机成功。** 已在单台 Windows PC 验证从主菜单开服、进入世界及 UDP 监听；第二台电脑加入、角色身份初始化、多人同步和双方保存仍需验证。

**兼容性更新（2026-10-07）：本机 Steam 已更新到构建 25754144，本发布不支持该构建。** 0.1.0 保留此前 25647713 的验证结果；新版需要重新生成/确认绑定并运行验证，安装器会拒绝未知版本。若朋友已更新，请等待适配版。

**已收到进入地牢/切换维度一直加载的报告，尚未完成复现和修复。** 当前只验证过主世界开服，请先不要用本地开服推进正式角色。定位进展见 [已知问题](docs/KNOWN_ISSUES.md)。

## 给朋友的安装步骤

1. 在两台电脑上安装相同版本的 Steam 游戏。本版仅支持构建 **25647713**（1.1.1.0）；游戏更新后安装程序会拒绝安装。
2. 从 [Blueprint Loader 作者页](https://www.nexusmods.com/minecraftdungeons2/mods/2) 下载并安装 **Blueprint Loader 2.3**，按作者说明放置资源。加载器不包含在本项目安装包中。
3. 打开 [Releases](https://github.com/Rainchen537/Dungeons2-LanDirect/releases)，下载 `LanDirect-0.1.0-windows.zip`，**完整解压**。不要只下载 GitHub 自动生成的 Source code。
4. 先正常启动游戏并创建或选好离线英雄，然后退出游戏。
5. 双击解压目录里的 `Install.cmd`。程序自动查找 Steam 游戏目录；找不到或存在多个目录时会提示输入路径。
6. 显示“安装完成”后，通过 Steam 启动游戏。

安装前会逐文件备份并校验 `%LOCALAPPDATA%\Dungeons2\Saved\SaveGames`。备份位于 `%LOCALAPPDATA%\Dungeons2LanDirect\backups`，安装窗口会显示具体路径。安装程序不需要 .NET、不自动下载加载器、不自动关闭游戏。

## 两台电脑怎么操作

两台电脑先连接同一局域网，安装同一个 Release，并各自选择离线英雄。

**开服电脑：** 点击主菜单“本地开服”，端口保持 `7777`，点击“开服并进入”。进入世界后保持游戏运行。用 Windows 的 `ipconfig` 查看正在使用的无线网卡或以太网卡的 IPv4，例如 `192.168.1.10`。

**加入电脑：** 点击主菜单“加入本地游戏”，填入开服电脑的地址，例如 `192.168.1.10:7777`，点击“加入并进入”。`127.0.0.1` 指向自己的电脑，不能用于加入朋友。

Windows 防火墙若出现提示，允许游戏在**专用网络**通信。若仍无法连接，检查开服端的 UDP 7777 入站权限。安装程序不会改动防火墙。本版没有公网穿透、房间列表、域名输入或 IPv6 支持。

连接取消与 35 秒超时返回已经实现，但尚未完成运行验证。连接无响应时，先记录现象；必要时正常退出游戏再启动。具体双机验证步骤见 [联机测试指南](docs/TESTING.md)。

## 停用与排查

- 退出游戏，双击 `Uninstall.cmd`：仅移走安装记录中的三个 LanDirect 资源；不恢复旧存档、不改动其他 Mod 或加载器。
- 双击 `Check.cmd`：检查安装包、游戏 EXE、加载器及已安装文件是否匹配。不等同于网络联机测试。
- “游戏版本不匹配”：暂时停用 Mod，等重新验证新版，不要绕过版本校验。
- “已有 LanDirect 资源”：先使用原安装对应的卸载程序，不会自动覆盖未知文件。
- 没有安装记录的手动安装：退出游戏，将 `Dungeons\Content\Paks\~mods\LanDirect` 内的 `LanDirect_P.pak`、`.utoc`、`.ucas` 移出 `~mods`。保留其他文件。

错误报告可提交到 [Issues](https://github.com/Rainchen537/Dungeons2-LanDirect/issues)。**不要上传完整存档、账号信息或整个崩溃转储。** 记录双方游戏版本、加载器版本、操作步骤与屏幕提示即可。

## 当前验证范围

| 内容 | 状态 |
| --- | --- |
| NeoRune 编译和资源打包 | 已通过 |
| 主菜单原版按钮、鼠标点击和悬停 | 已验证 |
| 原版弹窗资源与开服确认按钮 | 已验证 |
| 主菜单直接开服进入 Overworld | 已验证 |
| SpicewoodNetDriver 与 UDP `0.0.0.0:7777` | 已验证，同一游戏进程 |
| 最新标题与遮罩微调、输入错误提示、连接取消和超时 | 待运行验证 |
| 第二台电脑加入、移动、战斗、掉落、过图 | 待双机验证 |
| 双方退出重进后的角色保存 | 待双机验证 |

验证记录日期：2026-10-07。角色和网络检查仅证明本机开服链路成立；还没有解决或验证远端认证和离线角色身份适配。使用前保留备份，首次测试建议使用双方的测试英雄。

## 源码构建

Windows 上安装 [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0)，然后运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Build-LanDirect.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Package-LanDirect.ps1
```

SDK 使用 NuGet 上固定版本 `NeoRune.Sdk/0.4.2`，构建不会自动安装进游戏。输出为 `artifacts\LanDirect-0.1.0-windows.zip`。构建工具会优先使用本地 `dependencies\dotnet`（如果存在），否则使用 PATH 上的 .NET SDK。GitHub Actions 同样在 Windows 构建并上传安装包。

源码主要位于 [ModActor.cs](mods/LanDirect/ModActor.cs)（主菜单与 listen/travel）和 [LanPanel.cs](mods/LanDirect/LanPanel.cs)（原版控件弹窗）。游戏 EXE 校验值为：

```text
231147bd0c655a4ae73f90873675d42917f2bfb3a9ee164fc64f217d6d6bd4ef
```

本仓库不包含存档、游戏原版资源、加载器、私有工具依赖或本机研究转储。原创代码采用 [MIT](LICENSE) 许可，依赖说明见 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。非官方项目，与游戏发行方无关联。
