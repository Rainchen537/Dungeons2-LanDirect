# Steam 依赖与离线启动实验

本文按时间记录实验进展，文中的 DLL 哈希和部署状态属于各阶段快照。最新掉落实测及未解决事项见 [本地主机掉落显示实验](LOOT_VISIBILITY_EXPERIMENT.md)。构建当前源码后，启动脚本会要求隔离副本部署与新产物匹配；本文早期 Client 哈希不能视为当前统一部署版本。

2026-10-13，在本机隔离 Client 副本、构建 25754144 / 1.1.2.0 上测试；正式安装与正式存档未改动。

## 初始对照结果（后续进展见文末）

- 当前 EXE 存在 `nosteam` 参数处理分支，函数 RVA `0x4c05330`；也存在 `OnlineSubsystemNull` 模块名称。名称存在不代表完整离线启动可用。
- 使用原版 `Dungeons.exe` 启动器、隔离 UserDir 和已有离线存档，加 `-nosteam` 后能到标题画面。
- 按键进入游戏后，原生界面显示「未找到在线系统」「无法连接到 Steam。请启动 Steam 应用程序然后重试。」，错误代码 `0042`。当时 Steam 客户端正在运行。
- 这次测试没有进入英雄菜单或游戏世界，不能视为纯离线版成功启动，也没有证明禁用 Steam 后可以完成 LAN 握手。
- 测试后去掉 `-nosteam`，恢复原来的启动方式；没有修改 Steam API DLL 或游戏 EXE。

## 初始后续方向

分开处理启动依赖和 LAN 玩家身份：保持原生启动可用，为隔离测试副本建立专用离线英雄，并研究仅限 LAN 会话的独立网络身份。新建英雄改变角色存档 ID，不会自动改变连接握手中的网络 UniqueId。

引擎提供 [OnlineSubsystemNull](https://dev.epicgames.com/documentation/unreal-engine/API/PluginIndex/OnlineSubsystemNull)，但本游戏是否完整打包、是否允许切换、切换后角色服务能否初始化，均需另外验证。

## 原生代码定位（2026-10-13）

以下地址均为构建 25754144 EXE 的 RVA。通过正在运行的隔离测试进程只读反汇编，并用 UE 类默认对象的虚表确认所属类；不是游戏源码中的原始函数名。

1. **禁用入口：`0x4c05330`。** `0x4c05341` 引用 `nosteam` 字符串，参数检查后在 `0x4c0534f` 条件跳转至 `0x4c053f1` 返回，跳过后面的模块加载/注册逻辑。这解释了参数为何能禁用对应子系统，却不能让上层登录流程自动适配。
2. **登录前置状态：`USteamPrimaryUserLoginFlow` 虚表偏移 `0x2b8` 指向 `0x6222070`。** 非特定模式分支调用 `0x620adc0` 获取 `CheckPrerequisitesLoginState` 类，再通过 `0x620e9a0` 推进状态。另一个模式进入 `LoadSettingsState`；尚未给该模式值推定语义。
3. **强制要求所在：`UCheckPrerequisitesLoginState` 虚表偏移 `0x2b0` 指向 `0x62135e0`。** 在 `0x6213610` 调用 `0x52af140` 枚举未取得实例的在线子系统。后者通过 `0x52ae700` 按子系统名称请求实例，返回空的项目进入缺失列表。
4. **STEAM 缺失分支：`0x621364a` / `0x621364d`。** 比较缺失名称与全局 FName `0xc199318`；运行时只读解码确认它是 `STEAM`，相等则转到 `0x62138ee`。另一全局 FName `0xc199310` 是 `NativeXboxLive`，检查对它采用不同处理，不能将所有子系统缺失一概而论。
5. **弹窗与中止：`0x621393f` 至 `0x6213956`。** 从全局 `0xbb8b8d8` 引用的对象读取弹窗键，运行时解码为 `SW.UI.Dialog.Alert.Failed.Steam.Not.Loaded`，调用 `0x5658050` 显示提示。该分支之后走清理返回；正常推进下一状态的调用位于 `0x62139b0` 至 `0x62139b8`，不在 STEAM 缺失路径上。该弹窗键与上一轮界面显示的 0042 对应；尚未单独追到本地化表中数字编码的映射。

本次运行还读到 `CrossplayOSSImplementation` 配置包含 `Offline`、`NativeXboxLive` 和 `STEAM` 三项。游戏同时存在 `UOfflineIdentityLoginState`、`UNoInternetPrimaryLoginFlow` 等类，但这些类的存在并不自动消除上述 Steam 登录前置条件。

结论：当前已找到一个明确的 **游戏原生登录层** Steam 硬依赖。它发生在角色菜单和 LAN 握手之前。仓库启动脚本要求 Steam 进程存在只是额外的本地测试检查；即使删除脚本检查，原生检查仍然会执行。此分析不代表只跳过一处检查就能完成离线启动：后续身份、角色服务和授权状态的依赖尚未完整验证。本次未修改任何游戏代码或条件跳转。

## 经授权移除要求的实验

在上面的只读分析之后，用户授权先移除复制版的 Steam 要求。实验仅部署到 `H:\LanDirectTests\20261012-220350\Client`，部署前退出测试进程，备份并逐文件 SHA-256 核对 65 个测试 Saved 文件及原 DLL。

- 第一种实现只在进程内将 Steam 缺失分支改为继续枚举下一项，不改磁盘 EXE。日志确认指令写入并校验；进程随后退出，未验证进入角色菜单。该实现已撤下。
- 第二种实现保留所有 EXE 指令，仅从 `CrossplayOSSImplementation` 的子系统描述列表移除尚未初始化的 `STEAM` 项，保留其他项目。重复扫描版和单次处理版均记录移除成功，但启动期间退出；后两轮 Windows Application 事件记录异常 `0xc0000409`，故障模块 unknown。不能据此断定具体原因或宣称纯离线启动成功。
- 第三种实现只替换前置检查的虚表入口，执行原检查期间暂时排除列表末尾的缺失 STEAM 描述，原检查返回后恢复。日志确认入口替换完成，但未出现进入包装函数的日志，进程已退出。因此未证明第三种实现实际越过了登录检查，也不能把本轮退出直接归因于后续角色服务。
- 上一轮保留的实验源为第三种实现：`mods/NativeBridge/experimental_offline_gate.inc`，通过 `tools/Build-OfflineGateExperiment.ps1` 单独构建。正常 `Build-NativeBridge.ps1` 不包含它。实验要求 Client 测试目录及 `-nosteam -LanDirectOfflineGateExperiment` 两个参数同时满足。
- 上一轮结束时撤下实验 DLL，恢复部署前 DLL 并校验哈希。保存实验源便于继续定位，不作为可用 Release 发布。
- 对照测试：恢复部署前 DLL、保留 `-nosteam`，能够进入标题并复现原生 0042 弹窗；完成对照后恢复无 `-nosteam` 的常规测试启动参数。当前不能确认实验退出的根因，也不能将其称为可用的纯离线版本。

## 继续实测：2026-10-13 03:38 至 03:40

当前实验已在 `-nosteam` 下进入角色菜单、加载 Overworld，并通过点击地面实测角色移动。未证明关闭 Steam 客户端后仍能启动，也未证明两个无 Steam 实例能够联机。

本轮定位与修改：
- 原先仅跳过 0042 会停在 `NativeIdentityLoginState`。改用游戏自带 `NoInternetPrimaryLoginFlow`。
- 平台连接查询是 `UPlatformServiceConnection.GetConnectionStatus(PLATFORM=7)`，不是 FeatureToggle。选择函数 RVA `0x622a930` 在 DISCONNECTED 时返回离线流程类型 4。
- 仅测试 Client 的平台连接实例设为断开；为 LoginHandler 的 tick 接口建立实例专用虚表，追踪每次原生状态切换。
- 首轮无 Steam 离线流程完成 LoadSettings、NoInternetLoadTables、LoadSave 后，在 `NoInternetCheckStaticEntitlementState`（RVA `0x62232d0`）显示 0059。
- 保留 Steam 的对照运行通过原有静态检查并进入离线角色菜单。
- 最终无 Steam 实验只在该状态实例替换入口，推进其原有下一状态；这是实验性关闭静态授权检查，不能描述成原检查通过。动态授权、装备检查和其余原生流程继续执行。
- 03:38:29 日志记录 `SuccessfulLoginState`；03:38:56 进入 `Overworld`，Pawn、Camera、GameState 均存在，网络 driver=0。
- 界面实测角色移动。测试游戏 PID 为 17128，启动参数确有 `-nosteam`。进程仍加载 `steam_api64.dll`，所以当前证据是禁用 Steam 子系统后可玩，不能声称已完全去除所有 Steam DLL 依赖。

实验源：`mods/NativeBridge/experimental_offline_gate.inc`。单独构建 `tools/Build-OfflineGateExperiment.ps1`，正常 Release 构建不包含它。当前 DLL SHA256：`3053920BF9016F6286BCA5B7AFCA25E3510C017FB9150262D208ABCD69019582`。

已部署于隔离 Client，未恢复旧 DLL。下次退出测试 Client 后可运行：

```powershell
.\tools\Start-OfflineGateExperiment.ps1 -TestRoot 'H:\LanDirectTests\20261012-220350'
```

增加 `-KeepSteamForControl` 可进行保留 Steam 的离线流程对照。脚本验证测试目录标记、固定 EXE 哈希、已部署实验 DLL 和独立存档；不会自行关闭游戏。恢复路径为 `backups\before-offline-gate-20261013-025501\dwmapi.dll`，恢复前必须退出测试副本全部进程。

正式 Saved 的 13 个文件与备份清单再次逐项核对，全部不变。测试使用已有 1 级角色；尚未创建全新的角色 2。后续仍需：关闭 Steam 客户端条件下复测、独立本地网络身份、双实例加入与存档回归。

先前退出的 dump 有 `0xc0000409 / FAST_FAIL_GUARD_ICALL_CHECK_FAILURE`，栈含 UIAutomationCore；不能将每次退出直接归因于实验 DLL。0042 对话框的确认操作会以退出码 0 结束游戏，不会重试登录。

## 本机联机实测（2026-10-13）

第一轮：Host 正常 Steam 启动，Client 使用无 Steam 实验。Host 100 级、Client 已有 1 级英雄，隔离 UserDir。05:05 主机 Overworld 建立 UDP 7777 监听；05:06 客户端直连 127.0.0.1:7777 后主机 peers=1，未触发重复本地身份拒绝。随后主机崩溃，客户端停在 PendingJoinPlayerController，Pawn/GameState 均为空，不能称为联机成功。

崩溃证据：Host CrashContext `UECC-Windows-E18CD6AD4E0BA0D2C6E5FDAE8D34997D_0000`，GameThread 读取地址 0x100。栈顶 RVA 0x56b703f，调用链经过 0x52bd66e、0x3da9f73、0x638e921。RVA 0x41a06b0 从 PlayerController.Player 取 LocalPlayer；远端控制器返回空，调用者随后无检查地读取 LocalPlayer+0x100。

第二轮实验修复：`experimental_lan_guard.inc` 仅在 LanDirectTests 的 Host 且显式 `-LanDirectJoinExperiment` 时启用。检查全局 PostLogin 委托中原方法 0x56b6fc0 与执行器 0x52bd5c0，只替换该委托的方法指针；远端无 LocalPlayer 时跳过本地专用回调，本地玩家仍调用原方法。尚待第二轮运行结果。

第二轮实测结果：05:11:31 Host peers=1；05:11:34 本地专用 PostLogin 回调对远端执行了空值保护，主机未崩溃。Host 的本地和远端控制器均具有独立 Pawn/PlayerState；Client 从 PendingJoinPlayerController 切换到 BP_GameplayPlayerController_C，Pawn、Camera、GameState 完整。界面实际进入同一 Overworld 城镇。

双方移动复制验证：客户端位置从 (15131.39,83109.58) 移至 (15744.90,82874.13)，再移至 (15390.81,82832.06)，各次主机远端角色读数与客户端一致。主机位置从 (14950,83150) 移至 (14996.267,83052.327)，客户端复制角色为 (14996,83052)，符合网络位置量化。两边 PlayerArray 均有两个 Pawn。部分移动来自用户现场操作；内存快照为只读独立核验。

当前证明范围：同机回环加入、双方独立角色存在、双向位置复制、短时保持连接。尚未验证跨电脑、战斗伤害/掉落、一起换关、退出重连及存档一致性。保留两个游戏窗口供用户操作，没有为了断线测试打断当前联机。

本轮实验 DLL SHA256：63F91737232D415F80F1212DDD0EA000DD2066D3D2042EC27B9A0FF2CF87201E。已部署到 Host 和 Client；Host 旧 DLL 备份为 backups/host-before-postlogin-guard.dll，Client 初始 DLL 备份仍在 before-offline-gate-20261013-025501。本轮双方 Saved 另有 before-lan-retest / before-client-lan 时间戳备份，并逐文件校验。

关闭测试副本后，重复运行：
```powershell
.\tools\Start-LocalLanTest.ps1 -Role Host -TestRoot 'H:\LanDirectTests\20261012-220350' -JoinExperiment
.\tools\Start-OfflineGateExperiment.ps1 -TestRoot 'H:\LanDirectTests\20261012-220350'
```
主机依次“本地开服→创建大厅→开始游戏”，客户端“加入本地游戏→127.0.0.1:7777”。普通 Release 构建不包含该实验；这不是已完成全面回归的正式版本。当前仍使用已有 1 级离线英雄，没有伪称已新建角色 2。
