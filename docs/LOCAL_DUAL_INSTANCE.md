# 本机双实例 LAN 测试

本机两份游戏副本可以分别作为房主和加入端，先测试 `127.0.0.1:7777` 的网络握手、离线角色初始化和复制。它不能替代不同电脑、Steam 身份、防火墙及真实网卡的双机测试。

2026-10-12 当前构建 25754144 已验证两份复制的游戏同时显示窗口，并分别进入离线菜单。`-UserDir` 生效，写入各自的 `HostUser/Saved` 和 `ClientUser/Saved`，正式存档及配置哈希保持不变。房主使用 100 级英雄、加入端使用 1 级英雄的独立副本。房主菜单及主世界 UDP 7777 监听成功，清理后 NativeBridge 的这两项运行回归通过。

第一轮实际加入 `127.0.0.1:7777`：加入端进入带 SpicewoodNetDriver 的 Overworld，但没有 GameState，画面位于地图下方，没有正常可控角色。房主随后崩溃。其本地崩溃报告确认 PID 与房主匹配，异常为读取空地址的访问冲突，故障在游戏 EXE 的 RVA `0x6268ba2`。这不是成功联机；不能仅凭加入端有 NetDriver 推断完成握手或复制。双方使用同一 Steam 身份，身份冲突是否参与故障尚未确认。

测试 UserDir 中的 Engine.ini 在游戏运行后被改写/删除，日志中两项服务器流送 CVar 为 0；额外启动参数覆盖实验也未观察到生效，原因待查。故本轮不能证明包含服务器流送修正的完整链路已经回归。崩溃转储、身份信息和英雄文件仅保留本机，不上传 GitHub。

准备环境包括 `Host`、`Client` 两份游戏、各自的 UserDir，以及 `landirect-test.json` 标记。复制前先退出游戏并逐文件备份/校验最新正式存档和配置。只向测试目录复制存档，保留正式目录。两个实例最好选择不同离线英雄。

使用根目录的原版 `Dungeons.exe` 启动器，保留它传给 Shipping EXE 的 `Dungeons` 项目参数；直接运行 Shipping EXE 的初次实验出现 Steam 0042/初始化停滞。副本根目录和 Win64 目录放入只含 `1912410` 的 `steam_appid.txt`，使用现有已登录、拥有游戏的 Steam 客户端。该文件仅用于本地测试，不随 Mod 发布。参考 [Steamworks 初始化文档](https://partner.steamgames.com/doc/sdk/api)。

已准备环境可运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Start-LocalLanTest.ps1 -Role Host -TestRoot 'H:\LanDirectTests\20261012-220350'
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Start-LocalLanTest.ps1 -Role Client -TestRoot 'H:\LanDirectTests\20261012-220350'
```

先进入房主离线菜单，创建本地大厅，再点击原版开始游戏。加入端选择另一位离线英雄，输入 `127.0.0.1:7777`。按加入、双方角色身份、移动、战斗、地牢及保存顺序记录结果。Windows 安全/防火墙权限提示由用户手动处理。

原生桥接和 LanDirect 版本需一致。修改测试副本服务器流送或帧率配置后，必须核对游戏运行时实际值，不能仅凭配置文件存在宣称生效。正式目录、游戏本体及存档不上传 GitHub。
