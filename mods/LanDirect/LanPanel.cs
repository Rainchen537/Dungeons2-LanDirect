using NeoRune;
using UE.CoreUObject;
using UE.Engine;
using UE.Minimap;
using UE.Slate;
using UE.SlateCore;
using UE.UMG;
using UE.CommonUI;
using UE.Angelscript;

// Native dialog artwork and buttons are loaded from the installed game.
public class LanPanel : UCommonActivatableWidget
{
    public ModActor? Mod;
    UEditableTextBox? input;
    UTextBlock? status;
    bool hosting;

    public static LanPanel? Open(ModActor actor, bool host)
    {
        var widget = UWidgetBlueprintLibrary.Create(actor, Unreal.ClassOf<LanPanel>(), World.PlayerController(actor)) as LanPanel;
        if (widget == null) return null;
        widget.Mod = actor;
        widget.hosting = host;
        if (!widget.Build()) return null;
        widget.SetOwningPlayer(World.PlayerController(actor));
        widget.AddToViewport(10000);
        widget.bIsModal = true;
        widget.bIsBackHandler = false;
        widget.ActivateWidget();
        return widget;
    }

    bool Build()
    {
        var tree = UGameplayStatics.SpawnObject(Unreal.ClassOf<UWidgetTree>(), this) as UWidgetTree;
        if (tree == null || Mod == null) return false;
        WidgetTree = tree;
        var overlay = UGameplayStatics.SpawnObject(Unreal.ClassOf<UOverlay>(), tree) as UOverlay;
        var scrim = UGameplayStatics.SpawnObject(Unreal.ClassOf<UBorder>(), tree) as UBorder;
        var column = UGameplayStatics.SpawnObject(Unreal.ClassOf<UVerticalBox>(), tree) as UVerticalBox;
        var buttons = UGameplayStatics.SpawnObject(Unreal.ClassOf<UHorizontalBox>(), tree) as UHorizontalBox;
        var size = UGameplayStatics.SpawnObject(Unreal.ClassOf<USizeBox>(), tree) as USizeBox;
        var frame = NativeWidget("/SpicewoodUI/Spicewood/UI/Widget/Dialog/Widget/W_DialogFrame_GenericDesign.W_DialogFrame_GenericDesign_C") as UAS_DialogFrameGenericDesign;
        var heading = NativeWidget("/SpicewoodUI/Spicewood/UI/Widget/Dialog/Widget/W_DialogHeading.W_DialogHeading_C") as UAS_DialogHeading;
        input = UGameplayStatics.SpawnObject(Unreal.ClassOf<UAS_SpicewoodEditableTextBox>(), tree) as UEditableTextBox;
        var confirm = ActionButton(hosting ? "开服并进入" : "加入并进入");
        var cancel = ActionButton("取消");
        if (overlay == null || scrim == null || column == null || buttons == null || size == null || frame == null || heading == null || input == null || confirm == null || cancel == null) return false;
        var body = FindSlot(frame.WidgetTree?.RootWidget, "BodyContent");
        var footer = FindSlot(frame.WidgetTree?.RootWidget, "FooterContent");
        if (body == null || footer == null) { Log.Write("Native dialog slots were not found."); return false; }
        frame.WidgetSwitcher_Header?.SetActiveWidgetIndex(0);
        heading.TitleText = hosting ? "本地开服" : "加入本地游戏";
        heading.TitleTextBlock?.SetText(heading.TitleText);
        confirm.OnButtonBaseClicked += Confirm;
        cancel.OnButtonBaseClicked += Close;
        input.SetText(hosting ? "7777" : "192.168.1.10:7777");
        input.SelectAllTextWhenFocused = true;
        var style = input.WidgetStyle;
        var font = UMinimapHelpersLibrary.GetDefaultFont();
        font.Size = 32;
        style.TextStyle.Font = font;
        style.Padding = new FMargin { Left = 12, Right = 12, Top = 10, Bottom = 10 };
        input.WidgetStyle = style;
        input.SetForegroundColor(new FLinearColor { R = .06f, G = .06f, B = .06f, A = 1 });
        column.AddChildToVerticalBox(heading);
        column.AddChildToVerticalBox(Label(tree, hosting ? "使用当前选择的离线英雄创建游戏" : "使用当前离线英雄加入对方的游戏"));
        column.AddChildToVerticalBox(Label(tree, hosting ? "开服端口" : "对方的 IP:端口"));
        column.AddChildToVerticalBox(input);
        status = Label(tree, "");
        column.AddChildToVerticalBox(status);
        body.AddChild(column);
        var cancelSlot = buttons.AddChildToHorizontalBox(cancel);
        var confirmSlot = buttons.AddChildToHorizontalBox(confirm);
        if (cancelSlot == null || confirmSlot == null) return false;
        cancelSlot.SetSize(new FSlateChildSize { Value = 1, SizeRule = ESlateSizeRule.Fill });
        confirmSlot.SetSize(new FSlateChildSize { Value = 1, SizeRule = ESlateSizeRule.Fill });
        cancelSlot.SetPadding(new FMargin { Right = 16 });
        confirmSlot.SetPadding(new FMargin { Left = 16 });
        footer.AddChild(buttons);
        size.SetWidthOverride(1400);
        size.SetHeightOverride(740);
        size.AddChild(frame);
        scrim.SetBrushColor(new FLinearColor { R = 0, G = 0, B = 0, A = .65f });
        var shade = overlay.AddChildToOverlay(scrim);
        shade?.SetHorizontalAlignment(EHorizontalAlignment.HAlign_Fill);
        shade?.SetVerticalAlignment(EVerticalAlignment.VAlign_Fill);
        var centered = overlay.AddChildToOverlay(size);
        if (centered == null) return false;
        centered.SetHorizontalAlignment(EHorizontalAlignment.HAlign_Center);
        centered.SetVerticalAlignment(EVerticalAlignment.VAlign_Center);
        tree.RootWidget = overlay;
        SetDesiredFocusWidget(input);
        return true;
    }

    UUserWidget? NativeWidget(string path)
    {
        var cls = Unreal.LoadClass<UUserWidget>(path);
        return cls == null ? null : UWidgetBlueprintLibrary.Create(this, cls, World.PlayerController(this));
    }

    UAS_SpicewoodButtonGlobalAction? ActionButton(string text)
    {
        var button = NativeWidget("/OreUI/UI/Button/W_SpicewoodGlobalActionButton.W_SpicewoodGlobalActionButton_C") as UAS_SpicewoodButtonGlobalAction;
        if (button == null) return null;
        button.SetShouldUseFallbackDefaultInputAction(false);
        button.SetHideInputAction(true);
        button.SetButtonText(text);
        return button;
    }

    UNamedSlot? FindSlot(UWidget? widget, string name)
    {
        if (widget == null) return null;
        if (widget is UNamedSlot slot && UKismetSystemLibrary.GetObjectName(slot) == name) return slot;
        if (widget is UPanelWidget panel)
            foreach (var child in panel.GetAllChildren())
            {
                var match = FindSlot(child, name);
                if (match != null) return match;
            }
        return null;
    }

    void Confirm(UCommonButtonBase? button)
    {
        if (Mod == null || input == null) return;
        Mod.OnSettingChanged(hosting ? "Port" : "Endpoint", UKismetTextLibrary.Conv_TextToString(input.GetText()));
        Mod.OnButtonPressed(hosting ? "Host" : "Join");
    }

    void Close(UCommonButtonBase? button) { Mod?.CancelJoin(); Dismiss(); }
    public void SetStatus(string text) { status?.SetText(text); }
    public void Dismiss() { DeactivateWidget(); RemoveFromParent(); }

    static UTextBlock Label(UObject outer, string text)
    {
        var label = UGameplayStatics.SpawnObject(Unreal.ClassOf<UTextBlock>(), outer) as UTextBlock;
        label!.SetText(text);
        var font = UMinimapHelpersLibrary.GetDefaultFont();
        font.Size = 32;
        label.SetFont(font);
        label.SetJustification(ETextJustify.Center);
        return label;
    }
}
