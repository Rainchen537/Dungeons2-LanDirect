# 本机双实例 LAN 测试

本机两份游戏副本可以分别作为房主和加入端，先测试 `127.0.0.1:7777` 的网络握手、离线角色初始化和复制。它不能替代不同电脑、Steam 身份、防火墙及真实网卡的双机测试。

2026-10-12 当前构建 25754144 已验证两份复制的游戏同时显示窗口。`-UserDir` 生效，写入各自的 `HostUser/Saved` 和 `ClientUser/Saved`，正式存档及配置哈希保持不变。房主菜单 UDP 7777 监听成功。尚未确认加入成功。

准备环境包括 `Host`、`Client` 两份游戏、各自的 UserDir，以及 `landirect-test.json` 标记。复制前先退出游戏并逐文件备份/校验最新正式存档和配置。只向测试目录复制存档，保留正式目录。两个实例最好选择不同离线英雄。

使用根目录的原版 `Dungeons.exe` 启动器，保留它传给 Shipping EXE 的 `Dungeons` 项目参数；直接运行 Shipping EXE 的初次实验出现 Steam 0042/初始化停滞。副本根目录和 Win64 目录放入只含 `1912410` 的 `steam_appid.txt`，使用现有已登录、拥有游戏的 Steam 客户端。该文件仅用于本地测试，不随 Mod 发布。参考 [Steamworks 初始化文档](https://partner.steamgames.com/doc/sdk/api)。

已准备环境可运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Start-LocalLanTest.ps1 -Role Host -TestRoot 'H:\LanDirectTests\20261012-220350'
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Start-LocalLanTest.ps1 -Role Client -TestRoot 'H:\LanDirectTests\20261012-220350'
```

先进入房主离线菜单，创建本地大厅，再点击原版开始游戏。加入端选择另一位离线英雄，输入 `127.0.0.1:7777`。按加入、双方角色身份、移动、战斗、地牢及保存顺序记录结果。Windows 安全/防火墙权限提示由用户手动处理。

原生桥接和 LanDirect 版本需一致。测试副本中的服务器流送设置放在各自 `UserDir/Saved/Config/Windows/Engine.ini`，可以用 `t.MaxFPS=30` 降低双开负载。正式目录、游戏本体及存档不上传 GitHub。
