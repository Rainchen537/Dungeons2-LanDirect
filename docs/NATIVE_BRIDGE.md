# NativeBridge 0.1.1 · LanDirect 原生前置

仅支持 Windows x64、Steam 构建 25754144（游戏 EXE SHA-256：`3a8703406fd50520f83c4f70a0212c000cb3b584ef28eb38032902230c01ebdd`）。这是本项目原创 MIT 模块，无需 UE4SS、MinHook 或 .NET 运行时。

完整解压后，退出游戏，双击 `Install.cmd`，输入 Steam 游戏根目录。安装器先逐文件备份并校验最新存档，再备份 Engine.ini，安装 `Dungeons/Binaries/Win64/dwmapi.dll` 并加入两项服务器流送配置。不会覆盖已有同名 DLL、流送设置或其他加载器。已手动安装旧候选的电脑应先备份并移走旧 DLL、保留配置后移除原两项设置，再运行安装。

之后按 LanDirect 说明安装 Blueprint Loader 和同版蓝图包。两台电脑需使用相同的全部依赖。在主菜单点击“本地开服”建立大厅，成功后再点击原版“开始游戏”。加入端填主机局域网 IPv4:7777。先测试主世界加入，再测试地牢和双方保存。

`Check.cmd` 检查文件和配置；`Uninstall.cmd` 移走本包 DLL、恢复原 Engine.ini，不恢复存档。如果配置已有后续变更，停用脚本会拒绝覆盖，需手动保留现有配置、移除带 BEGIN/END 注释的 LAN Direct 配置块并移走本包 DLL。

模块将 DWM 调用转发给 Windows 系统 DLL，仅在完整游戏哈希和函数签名匹配时启用桥接。通过游戏窗口所属线程调用原生 `EnableListenServer`，不安装代码钩子，不做第二次地图重载。日志位于游戏 Win64 目录的 `LanDirect-native.log`。

本地旧候选曾确认菜单与世界监听，并成功进入一次地牢；本包为清理后重新编译版本，尚未完成运行回归。远端加入、离线身份、同步、共同过图和双方保存均未验证。

源码：`mods/NativeBridge`。Windows 构建需 MinGW-w64 的 `g++`，运行 `tools/Build-NativeBridge.ps1` 和 `tools/Package-NativeBridge.ps1`。
