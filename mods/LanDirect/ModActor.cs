using NeoRune;
using UE.Engine;
using UE.Angelscript;
using UE.UMG;
using UE.CommonUI;
using UE.PlayerService;
using UE.SWPlayerState;

[ModSetting.Heading("局域网直连 · 实验原型")]
[ModSetting.Text("在主菜单选择离线角色，再使用本地开服或加入。多人同步和双方角色保存尚未验证。")]
[ModSetting.TextInput("Port", "开服端口", Default = "7777")]
[ModSetting.EventButton("Host", "从主菜单开服", ButtonText = "开服（实验）")]
[ModSetting.TextInput("Endpoint", "对方的 IPv4:端口", Default = "127.0.0.1:7777", Placeholder = "192.168.1.10:7777")]
[ModSetting.EventButton("Join", "加入指定地址", ButtonText = "加入（实验）")]
[ModSetting.EventButton("Diagnose", "记录当前地图和控制器", ButtonText = "记录诊断")]
public class ModActor : AActor, IModSettings
{
    string port = "7777";
    string endpoint = "127.0.0.1:7777";
    bool travelling;
    bool joining;
    LanPanel? panel;
    UAS_InitialLobbyScreen? menu;
    LanSessionState? session;
    int initializationPolls;

    protected override void ReceiveBeginPlay()
    {
        Log.Write("LanDirect 0.1.1 loaded; hosting and joining require the original Play flow.");
        session = GetSession();
        Diagnose();
        Timer.Start(this, nameof(AttachPanel), 0.5f, loop: true);
        if (World.LevelName(this) == "Menu_Spicewood")
        {
            if (session != null) { session.Stage = 0; session.Operation = 0; session.StartedFromOfflineLobby = false; session.CharacterId = null; }
        }
        else if (session != null && session.Stage == 1)
            Timer.Start(this, nameof(AfterNativePlay), 0.5f, loop: true);
        else if (session != null && session.Stage == 2)
        {
            Timer.Start(this, nameof(VerifyLanCharacter), 0.5f, loop: true);
        }
    }

    LanSessionState? GetSession()
    {
        var instance = UGameplayStatics.GetGameInstance(this);
        if (instance == null) return null;
        var retained = instance.ReferencedObjects;
        foreach (var obj in retained)
            if (obj is LanSessionState state) return state;
        var created = UGameplayStatics.SpawnObject(Unreal.ClassOf<LanSessionState>(), instance) as LanSessionState;
        if (created == null) return null;
        retained.Add(created);
        instance.ReferencedObjects = retained;
        return created;
    }

    bool IsOfflinePlayer()
    {
        var controller = World.PlayerController(this);
        if (controller == null) return false;
        var subsystem = USubsystemBlueprintLibrary.GetLocalPlayerSubSystemFromPlayerController(controller,
            Unreal.ClassOf<UPlayerServiceSubsystem>()) as UPlayerServiceSubsystem;
        return subsystem?.PlayerService?.PlayerServiceImpl is UOfflinePlayerServiceImpl;
    }

    void BeginNativePlay(int operation, string value)
    {
        if (session == null || menu?.PlayButton == null) { Feedback("原版开始游戏入口未就绪，请稍后重试。"); return; }
        if (!menu.PlayButton.GetIsEnabled()) { Feedback("请等待原版开始游戏按钮可用。"); return; }
        if (!IsOfflinePlayer()) { Feedback("请先在主菜单选择离线英雄。"); return; }
        session.Operation = operation;
        session.Value = value;
        session.Stage = 1;
        session.StartedFromOfflineLobby = true;
        travelling = true;
        panel?.Dismiss();
        Log.Write("Starting the original lobby Play handler; LAN travel waits for offline initialization.");
        Timer.Start(this, nameof(NativePlayTimedOut), 60f, loop: false);
        // Dispatch through CommonUI's native click handler. Direct calls into
        // AngelScript handlers are unsafe in NeoRune; this preserves the game's delegates.
        menu.PlayButton.HandleButtonClicked();
    }

    void NativePlayTimedOut()
    {
        if (World.LevelName(this) != "Menu_Spicewood" || session == null || session.Stage != 1) return;
        OnNativeStartCancelled(null);
        if (menu?.CancelButton != null && menu.CancelButton.GetIsEnabled())
            menu.CancelButton.HandleButtonClicked();
        Log.Write("Original Play did not leave the lobby within 60 seconds; LAN request cancelled.");
    }

    void OnNativeStartCancelled(UCommonButtonBase? button)
    {
        if (session == null || session.Stage != 1) return;
        Timer.Stop(this, nameof(NativePlayTimedOut));
        session.Stage = 0;
        session.Operation = 0;
        session.StartedFromOfflineLobby = false;
        travelling = false;
    }

    void AfterNativePlay()
    {
        initializationPolls++;
        if (session == null || session.Stage != 1 || !session.StartedFromOfflineLobby)
        {
            Timer.Stop(this, nameof(AfterNativePlay));
            return;
        }
        // The in-world implementation can be OnlinePlayerServiceImpl even after
        // the original offline Play flow. Validate the selected mode in the lobby,
        // then wait for the original controller, pawn and character association.
        var state = World.PlayerController(this)?.PlayerState as ABasePlayerState;
        if (World.Player(this) == null || state == null || state.ActiveCharacterId.Length == 0 || initializationPolls < 10)
        {
            if (initializationPolls < 60) return;
            Timer.Stop(this, nameof(AfterNativePlay));
            if (session != null) { session.Stage = 0; session.Operation = 0; }
            Log.Write("LAN request cancelled: original player initialization did not complete. No listen/direct travel was performed.");
            return;
        }
        Timer.Stop(this, nameof(AfterNativePlay));
        if (session == null || session.Stage != 1) return;
        Log.Write("Original Play created a pawn and associated a character; continuing the requested LAN action.");
        session.CharacterId = state.ActiveCharacterId;
        session.Stage = 2; // Consume before travel, preventing reload loops.
        if (session.Operation == 1) { port = session.Value ?? ""; HostWorld(); }
        else if (session.Operation == 2) { endpoint = session.Value ?? ""; JoinWorld(); }
    }

    void VerifyLanCharacter()
    {
        initializationPolls++;
        var state = World.PlayerController(this)?.PlayerState as ABasePlayerState;
        if (World.Player(this) != null && state != null && state.ActiveCharacterId == session?.CharacterId)
        {
            Timer.Stop(this, nameof(VerifyLanCharacter));
            Log.Write("LAN travel retained the original Play character association. Dungeon and remote-client behavior still require verification.");
            if (session != null) { session.Stage = 0; session.Operation = 0; session.CharacterId = null; }
            return;
        }
        if (initializationPolls < 60) return;
        Timer.Stop(this, nameof(VerifyLanCharacter));
        Log.Write("LAN travel did not retain the original character association; returning to the menu.");
        UGameplayStatics.OpenLevel(this, "/Game/Spicewood/Maps/Menu/Menu_Spicewood", true, "");
    }

    void AttachPanel()
    {
        if (World.LevelName(this) != "Menu_Spicewood") { Timer.Stop(this, nameof(AttachPanel)); return; }
        UWidgetBlueprintLibrary.GetAllWidgetsOfClass(this, out var menus, Unreal.ClassOf<UAS_InitialLobbyScreen>(), false);
        foreach (var widget in menus)
        {
            var lobby = widget as UAS_InitialLobbyScreen;
            if (lobby == null || lobby.LobbyButtons == null || lobby.PlayButton == null) continue;
            var list = lobby.PlayButton.GetParent() as UVerticalBox;
            if (list == null) { Log.Write("Play button's parent is not a vertical menu."); continue; }
            menu = lobby;
            if (lobby.CancelButton != null) lobby.CancelButton.OnButtonBaseClicked += OnNativeStartCancelled;
            var host = NativeButton("本地开服");
            var join = NativeButton("加入本地游戏");
            if (host == null || join == null) return;
            host.OnButtonBaseClicked += OpenHost;
            join.OnButtonBaseClicked += OpenJoin;
            var children = list.GetAllChildren();
            list.ClearChildren();
            foreach (var child in children)
            {
                list.AddChildToVerticalBox(child);
                if (child == lobby.PlayButton)
                {
                    list.AddChildToVerticalBox(host);
                    list.AddChildToVerticalBox(join);
                }
            }
            Log.Write("Native LAN menu buttons attached.");
            Timer.Stop(this, nameof(AttachPanel));
            return;
        }
    }

    public UAS_LobbySingleActionButton? NativeButton(string text)
    {
        var cls = Unreal.LoadClass<UUserWidget>("/OreUI/UI/Button/Role/Text/W_LobbyButton.W_LobbyButton_C");
        if (cls == null) return null;
        var button = UWidgetBlueprintLibrary.Create(this, cls, World.PlayerController(this)) as UAS_LobbySingleActionButton;
        if (button == null) return null;
        button.SetShouldUseFallbackDefaultInputAction(false);
        button.SetHideInputAction(true);
        button.SetButtonText(text);
        button.SetIsEnabled(true);
        return button;
    }

    void OpenHost(UCommonButtonBase? button) { panel?.Dismiss(); panel = LanPanel.Open(this, true); }
    void OpenJoin(UCommonButtonBase? button) { panel?.Dismiss(); panel = LanPanel.Open(this, false); }

    public void OnSettingChanged(string id, string value)
    {
        if (id == "Port") port = value;
        if (id == "Endpoint") endpoint = value;
    }

    public void OnSettingsReset()
    {
        port = "7777";
        endpoint = "127.0.0.1:7777";
    }

    public void OnButtonPressed(string id)
    {
        if (id == "Diagnose") { Diagnose(); return; }
        if (travelling) { Feedback("正在连接，请等待。"); return; }
        if (World.PlayerController(this) == null)
        {
            Feedback("主菜单尚未就绪，请稍后重试。");
            return;
        }
        if (id == "Host") Host();
        if (id == "Join") Join();
    }

    void Feedback(string text) { Log.Write(text); panel?.SetStatus(text); }

    public void CancelJoin()
    {
        if (!joining) return;
        joining = false;
        Timer.Stop(this, nameof(JoinTimedOut));
        UGameplayStatics.OpenLevel(this, "/Game/Spicewood/Maps/Menu/Menu_Spicewood", true, "");
    }

    void JoinTimedOut()
    {
        if (!joining) return;
        Log.Write("Direct join timed out; returning to the main menu.");
        CancelJoin();
    }

    void Diagnose()
    {
        var player = World.Player(this);
        var controller = World.PlayerController(this);
        var mode = UGameplayStatics.GetGameMode(this);
        Log.Write($"Level={World.LevelName(this)}; Pawn={player != null}; Controller={controller != null}; GameMode={mode != null}; ActorAuthority={HasAuthority()}; OfflineService={IsOfflinePlayer()}");
        // Authority is also true in single player. It is not proof of a listening socket.
    }

    void Host()
    {
        if (!Number(port, 1, 65535)) { Feedback("端口须为 1–65535 之间的数字。"); return; }
        if (World.LevelName(this) == "Menu_Spicewood") { BeginNativePlay(1, port); return; }
        Feedback("请返回主菜单，选择离线英雄后使用本地开服。");
    }

    void HostWorld()
    {
        var mode = UGameplayStatics.GetGameMode(this);
        if (mode == null) { Log.Write("No local authoritative GameMode; do not host from a remote client."); return; }
        var level = World.LevelName(this);
        if (level.Length == 0) { Log.Write("Current level name is empty."); return; }
        Log.Write($"Requesting listen travel: level={level}; port={port}. Socket and session initialization still require verification.");
        travelling = true;
        panel?.SetStatus("正在创建本地游戏……");
        UGameplayStatics.OpenLevel(this, level, true, $"listen?Port={port}");
    }

    void Join()
    {
        if (!Endpoint(endpoint)) { Feedback("请输入 IPv4:端口，例如 192.168.1.10:7777。"); return; }
        if (World.LevelName(this) == "Menu_Spicewood") { BeginNativePlay(2, endpoint); return; }
        Feedback("请返回主菜单，选择离线英雄后加入本地游戏。");
    }

    void JoinWorld()
    {
        Log.Write($"Requesting direct travel to {endpoint}. Connection and offline character initialization are unverified.");
        travelling = true;
        joining = true;
        panel?.SetStatus("正在加入本地游戏……");
        Timer.Start(this, nameof(JoinTimedOut), 35f, loop: false);
        UGameplayStatics.OpenLevel(this, endpoint, true, "");
    }

    static bool Endpoint(string value)
    {
        var pair = UKismetStringLibrary.ParseIntoArray(value, ":", false);
        if (pair.Count != 2 || !Number(pair[1], 1, 65535)) return false;
        var octets = UKismetStringLibrary.ParseIntoArray(pair[0], ".", false);
        if (octets.Count != 4) return false;
        for (int i = 0; i < octets.Count; i++)
            if (!Number(octets[i], 0, 255)) return false;
        return true;
    }

    static bool Number(string value, int min, int max)
    {
        if (value.Length == 0 || value.Length > 5) return false;
        for (int i = 0; i < value.Length; i++)
            if (UKismetStringLibrary.FindSubstring("0123456789", UKismetStringLibrary.GetSubstring(value, i, 1), false, false, 0) < 0) return false;
        int number = UKismetStringLibrary.Conv_StringToInt(value);
        return number >= min && number <= max;
    }
}
