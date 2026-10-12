# 类似实现检索（2026-10-12）

本轮搜索使用 Minecraft Dungeons II / Minecraft Dungeons 2 与 LAN、offline multiplayer mod、listen server、direct connect、Blueprint Loader 等组合，并搜索 GitHub 仓库和 Nexus Mods。

目前没有找到公开、可验证、可直接复用的“两台 Windows PC 的离线英雄通过 IP:端口加入本地 listen server”实现。这是本轮检索结果，不能证明全网不存在。

- [Couch Co-op - Keyboard and Gamepad](https://www.nexusmods.com/minecraftdungeons2/mods/109)：作者说明是同一屏幕的键鼠加手柄本地合作，调用原版第二玩家选择流程；不是两台电脑直连。
- [Dungeons-II-Mod-Kit](https://github.com/Dokucraft/Dungeons-II-Mod-Kit)：蓝图 Mod 开发工具，可参考加载/打包约定，没有发现 LAN 直连实现。
- [Blueprint Loader](https://www.nexusmods.com/minecraftdungeons2/mods/2?tab=description)：作者页最新版 2.5，属于蓝图加载前置。页面明确禁止上传到其他网站，因此未将其文件重传 GitHub。
- GitHub 仓库关键词检索 `minecraft dungeons 2 lan` 仅返回本项目，未找到另一项可复用实现。

据此继续本项目的原生 EnableListenServer 桥接与双机测试路线。下一项关键验证是加入端能否完成网络握手并保留自己选择的离线英雄身份，之后再检查复制、地牢流送和保存。
