# NativeBridge 0.1.2 · LanDirect 原生前置

仅支持 Windows x64、Steam 构建 25754144（游戏 EXE SHA-256：`3a8703406fd50520f83c4f70a0212c000cb3b584ef28eb38032902230c01ebdd`）。这是本项目原创 MIT 模块，无需 UE4SS、MinHook 或 .NET 运行时。

完整解压后，退出游戏，双击 `Install.cmd`，输入 Steam 游戏根目录。安装器逐文件备份并校验最新存档和 Engine.ini，安装 `Dungeons/Binaries/Win64/dwmapi.dll`，在 `[SystemSettings]` 中加入两项服务器流送配置，并将 Engine.ini 设为只读，保留启动配置。安装记录保存原文件属性，停用时恢复。

已有安装出现配置缺失时，退出游戏并运行同包的 `Repair.cmd`。修复入口校验已安装 DLL，备份当前存档、配置和安装记录，恢复流送设置及只读保护，并保留其他配置。重复修复保持相同配置内容。修复后继续通过 Steam 启动。

Engine.ini 的只读保护会阻止该文件的自动写回；手动编辑前可取消只读，编辑后运行 `Repair.cmd` 重新保护。存档和 GameUserSettings.ini 使用各自的文件。

之后按 LanDirect 说明安装 Blueprint Loader 和同版蓝图包。两台电脑需使用相同的全部依赖。在主菜单点击“本地开服”建立大厅，成功后再点击原版“开始游戏”。加入端填主机局域网 IPv4:7777。先测试主世界加入，再测试地牢和双方保存。

`Check.cmd` 检查文件哈希、`[SystemSettings]` 中两项值和只读属性。`Uninstall.cmd` 移走本包 DLL，恢复安装或最近一次修复前的配置内容和文件属性。修复前的完整配置与安装记录另存于备份目录。

开服按钮读取游戏中的两项实际 CVar 值；两者均为 1 时创建大厅。值不正确时，弹窗显示退出游戏、运行 `Repair.cmd`、重新启动的操作步骤。在 Mod 设置中点击“记录诊断”可记录这两个运行值。

模块将 DWM 调用转发给 Windows 系统 DLL，仅在完整游戏哈希和函数签名匹配时启用桥接。通过游戏窗口所属线程调用原生 `EnableListenServer`，不做第二次地图重载。0.1.2 在该监听世界的 GameMode 实例调用 PreLogin 前检查重复本地身份，避免原生重连逻辑销毁房主；不同身份继续原生验证。仅替换该实例的虚函数表引用，不改写游戏 EXE 或可执行代码字节。日志位于游戏 Win64 目录的 `LanDirect-native.log`。

0.1.2 已实测菜单/主世界监听、两项流送值均为 1、同身份连接拒绝后房主仍可移动。加入端原生界面可能只显示错误 0015，详细原因在房主原生日志中。不同账号的成功加入、同步、共同过图和双方保存尚未验证。

源码：`mods/NativeBridge`。Windows 构建需 MinGW-w64 的 `g++`，运行 `tools/Build-NativeBridge.ps1` 和 `tools/Package-NativeBridge.ps1`。
