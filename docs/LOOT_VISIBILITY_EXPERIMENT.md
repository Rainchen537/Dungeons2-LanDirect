# 本地主机掉落显示实验

2026-10-13，针对构建 25754144 / 1.1.2.0 的隔离双实例测试。

## 问题与处理

主机能看到属于远端角色的个人掉落，但原生归属检查不允许主机拾取。
装备的 `FItemData.OwningPlayerID` 对应 `PlayerState.PlayerId`，不是 PlayerNumber。
现场剩余绿宝石代理及宝箱装备都确认属于远端角色；不能因为主机捡不了就删除它们或放宽拾取权限。

`experimental_loot_visibility.inc` 仅在隔离 Host 路径和 `-LanDirectJoinExperiment` 参数同时满足时启用：

- 货币：在 SWWorldActor 实例的原生 Tick 之后，过滤远端个人货币的本机 ISM/Niagara 呈现，保留权威代理及模拟状态。
- 装备：将远端个人装备的 PrimitiveComponent 设为 OnlyOwnerSee，不修改可复制的 Actor.bHidden 或装备归属。零及负归属 ID 的共享物品不参与过滤。
- 正常 Release 构建不包含实验代码。地址及布局只适用于通过现有 EXE 哈希检查的构建。

## 构建与部署边界

`tools/Build-OfflineGateExperiment.ps1` 构建包含离线流程、加入保护和掉落显示实验的桥接 DLL。
`tools/Build-LootVisibilityExperiment.ps1` 构建独立诊断 DLL；不要与已包含相同功能的桥接 DLL 同时加载。
构建脚本只输出 artifacts，不部署或重启游戏。部署前须退出对应测试进程并备份当前测试存档及 DLL。
启动脚本要求已安装 DLL 与当前构建产物哈希一致；重新构建后，旧 Client 部署可能需要同步，不能直接沿用历史部署说明。

## 已完成的实测

- 本机回环加入、独立 Pawn/PlayerState 和双向移动复制已验证，见 OFFLINE_STARTUP.md。
- 主机运行掉落显示实验后，用户确认新罐子掉落能正常吸入。
- 只读核对两端货币：主机由 24485 增至 24517，客户端由 0 增至 11。两端都有原生拾取入账。
- 新掉落中的远端代理仍保留原归属。

这些余额差值覆盖多次操作，不代表同一个罐子的两份掉落数量应当相等，也不能证明绝无重复发放。

## 尚未完成

- 宝箱装备的两端显示和拾取回归。
- 退出、重载后的存档持久化，以及跨电脑回归。
- 装备过滤仍每 500 毫秒遍历 UObject，需要后续评估运行开销。
- 客户端出现过 0020。实时错误表将它映射为 `SW.UI.Dialog.Alert.Unknown.Error`；关闭后连接和移动同步仍正常，未立即复现。
- 原生 `GA_TeleportLocalPlayers` 虚表槽 0x458（RVA 0x5a91b80）含直接显示该错误的分支（0x5a920b0），但尚未证明这次弹窗来自此分支。用户不记得手动传送，自动传送及加入流程仍需追踪。未屏蔽提示，未宣称修复。

这是实验性检查点，不是完整回归通过的正式发布。
