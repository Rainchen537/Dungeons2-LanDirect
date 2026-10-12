// Minimal Unreal test doubles for the extracted production attachment methods.
// These tests verify menu lifecycle behavior, not rendering or game networking.
public class UWidget
{
    public bool Valid = true;
    public UVerticalBox? Parent;
    public UVerticalBox? GetParent() => Parent;
    public void RemoveFromParent() { Parent?.Children.Remove(this); Parent = null; }
}
public class UUserWidget : UWidget { }
public class UVerticalBox : UWidget
{
    public List<UWidget> Children = new();
    public List<UWidget> GetAllChildren() => Children.ToList();
    public void ClearChildren() { foreach (var child in Children) child.Parent = null; Children.Clear(); }
    public void AddChildToVerticalBox(UWidget child) { child.RemoveFromParent(); Children.Add(child); child.Parent = this; }
}
public class UCommonButtonBase : UUserWidget
{
    public event Action<UCommonButtonBase?>? OnButtonBaseClicked;
    public int HandlerCount => OnButtonBaseClicked?.GetInvocationList().Length ?? 0;
    public void Click() => OnButtonBaseClicked?.Invoke(this);
}
public class UAS_LobbySingleActionButton : UCommonButtonBase
{
    public string Text = "";
    public void SetShouldUseFallbackDefaultInputAction(bool value) { }
    public void SetHideInputAction(bool value) { }
    public void SetButtonText(string value) => Text = value;
    public void SetIsEnabled(bool value) { }
}
public class UAS_InitialLobbyScreen : UUserWidget
{
    public UVerticalBox? LobbyButtons = new();
    public UAS_LobbySingleActionButton? PlayButton = new();
    public UAS_LobbySingleActionButton? CancelButton = new();
    public object Owner = World.Controller;
    public bool Rendered = true;
    public object GetOwningPlayer() => Owner;
    public bool IsRendered() => Rendered;
}
public class UAS_InitialLobbyScreen_Activatable : UUserWidget
{
    public UAS_InitialLobbyScreen? LobbyScreen;
    public bool Active = true;
    public bool IsActivated() => Active;
}
public class LanPanel { public int Dismissals; public void Dismiss() => Dismissals++; }
public class LanSessionState { public int Stage; }
public static class World
{
    public static string Level = "Menu_Spicewood";
    public static object Controller = new();
    public static string LevelName(object context) => Level;
    public static object PlayerController(object context) => Controller;
}
public static class Timer
{
    public static bool Running = true;
    public static void Stop(object context, string method) => Running = false;
}
public static class Log { public static void Write(string message) { } }
public static class Unreal
{
    public static object ClassOf<T>() => typeof(T);
    public static object? LoadClass<T>(string path) => UWidgetBlueprintLibrary.CanCreate ? typeof(T) : null;
}
public static class UKismetSystemLibrary { public static bool IsValid(UWidget? widget) => widget != null && widget.Valid; }
public static class UWidgetBlueprintLibrary
{
    public static List<UWidget> Screens = new();
    public static bool CanCreate = true;
    public static void GetAllWidgetsOfClass(object context, out List<UWidget> result, object cls, bool topLevelOnly) => result = Screens.ToList();
    public static UUserWidget? Create(object context, object cls, object controller) => CanCreate ? new UAS_LobbySingleActionButton() : null;
}
public partial class ModActor
{
    public int HostClicks, JoinClicks, PlayClicks, CancelClicks;
    void OpenHost(UCommonButtonBase? button) => HostClicks++;
    void OpenJoin(UCommonButtonBase? button) => JoinClicks++;
    void OnLobbyPlayClicked(UCommonButtonBase? button) => PlayClicks++;
    void OnNativeStartCancelled(UCommonButtonBase? button) => CancelClicks++;
    public void Poll() => AttachPanel();
    public void SetListening() => session = new LanSessionState { Stage = 3 };
    public LanPanel SetDialog() => panel = new LanPanel();
}
public static class Program
{
    static void Assert(bool condition, string message) { if (!condition) throw new Exception(message); }
    static UAS_InitialLobbyScreen_Activatable Screen()
    {
        var lobby = new UAS_InitialLobbyScreen();
        lobby.LobbyButtons!.AddChildToVerticalBox(new UWidget());
        lobby.LobbyButtons.AddChildToVerticalBox(lobby.PlayButton!);
        lobby.LobbyButtons.AddChildToVerticalBox(lobby.CancelButton!);
        return new() { LobbyScreen = lobby };
    }
    static List<UAS_LobbySingleActionButton> LanButtons(UVerticalBox list) => list.Children.OfType<UAS_LobbySingleActionButton>().Where(b => b.Text.Length > 0).ToList();
    static void CheckMenu(UAS_InitialLobbyScreen lobby, string hostText = "本地开服")
    {
        var list = lobby.PlayButton!.Parent!;
        var buttons = LanButtons(list);
        Assert(buttons.Count == 2 && buttons[0].Text == hostText && buttons[1].Text == "加入本地游戏", "Exactly one LAN button pair expected");
        int play = list.Children.IndexOf(lobby.PlayButton);
        Assert(list.Children[play + 1] == buttons[0] && list.Children[play + 2] == buttons[1], "LAN buttons must follow Play");
        Assert(lobby.PlayButton.HandlerCount == 1 && lobby.CancelButton!.HandlerCount == 1, "Original buttons must have one mod delegate each");
        Assert(Timer.Running, "Menu polling must continue after attachment");
    }
    public static void Main()
    {
        var actor = new ModActor();
        actor.Poll();
        Assert(Timer.Running, "Wait for a ready menu");
        var screen = Screen();
        var lobby = screen.LobbyScreen!;
        var hidden = Screen(); hidden.Active = false;
        var foreign = Screen(); foreign.LobbyScreen!.Owner = new object();
        UWidgetBlueprintLibrary.Screens.AddRange(new[] { hidden, foreign, screen });
        actor.Poll(); CheckMenu(lobby);
        Assert(LanButtons(hidden.LobbyScreen!.LobbyButtons!).Count == 0 && LanButtons(foreign.LobbyScreen!.LobbyButtons!).Count == 0, "Ignore inactive and other-player menus");
        var pair = LanButtons(lobby.LobbyButtons!);
        for (int i = 0; i < 20; i++) actor.Poll();
        CheckMenu(lobby);
        Assert(LanButtons(lobby.LobbyButtons!)[0] == pair[0], "An intact pair must be retained");
        pair[0].Click(); pair[1].Click(); lobby.PlayButton!.Click(); lobby.CancelButton!.Click();
        Assert(actor.HostClicks == 1 && actor.JoinClicks == 1 && actor.PlayClicks == 1 && actor.CancelClicks == 1, "Clicks must dispatch once");
        Console.WriteLine("PASS: delayed menu, ownership filter, stable polling and single delegates");

        var originalPlay = lobby.PlayButton;
        var originalCancel = lobby.CancelButton;
        var dialog = actor.SetDialog();
        screen.Active = false;
        var replacement = Screen(); UWidgetBlueprintLibrary.Screens.Add(replacement);
        actor.Poll(); CheckMenu(replacement.LobbyScreen!);
        Assert(LanButtons(lobby.LobbyButtons!).Count == 0, "Old lobby must lose LAN buttons");
        Assert(originalPlay.HandlerCount == 0 && originalCancel.HandlerCount == 0, "Unbind replaced lobby delegates");
        Assert(dialog.Dismissals == 1, "Close the obsolete lobby dialog");
        lobby = replacement.LobbyScreen!;
        Console.WriteLine("PASS: hero switch replaces the lobby and dismisses obsolete UI");

        for (int i = 0; i < 5; i++)
        {
            lobby.LobbyButtons!.ClearChildren();
            lobby.LobbyButtons.AddChildToVerticalBox(lobby.PlayButton!);
            lobby.LobbyButtons.AddChildToVerticalBox(lobby.CancelButton!);
            actor.Poll(); CheckMenu(lobby);
        }
        Console.WriteLine("PASS: repeated hero changes rebuild the same menu without duplicate delegates");

        LanButtons(lobby.LobbyButtons!)[1].RemoveFromParent();
        actor.Poll(); CheckMenu(lobby);
        var destroyed = LanButtons(lobby.LobbyButtons!)[0]; destroyed.RemoveFromParent(); destroyed.Valid = false;
        actor.Poll(); CheckMenu(lobby);
        Console.WriteLine("PASS: partial removal and destroyed button recovery");

        var oldPlay = lobby.PlayButton; var oldCancel = lobby.CancelButton;
        lobby.LobbyButtons!.ClearChildren();
        lobby.PlayButton = new(); lobby.CancelButton = new();
        lobby.LobbyButtons.AddChildToVerticalBox(lobby.PlayButton); lobby.LobbyButtons.AddChildToVerticalBox(lobby.CancelButton);
        UWidgetBlueprintLibrary.CanCreate = false;
        actor.Poll(); Assert(Timer.Running, "Retry when button classes are not ready");
        UWidgetBlueprintLibrary.CanCreate = true;
        actor.SetListening(); actor.Poll(); CheckMenu(lobby, "关闭本地大厅");
        Assert(oldPlay!.HandlerCount == 0 && oldCancel!.HandlerCount == 0, "Rebind replaced Play/Cancel widgets");
        Console.WriteLine("PASS: replaced native controls, creation retry and listening label");

        World.Level = "Overworld"; actor.Poll(); Assert(!Timer.Running, "Stop polling outside the menu map");
        Console.WriteLine("PASS: no lobby polling in the game world");
    }
}
