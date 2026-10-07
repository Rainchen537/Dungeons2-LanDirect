using UE.CoreUObject;

// Retained by GameInstance only. Never saved to disk and never survives a restart.
public class LanSessionState : UObject
{
    public int Operation;
    public string? Value;
    public int Stage;
    public bool StartedFromOfflineLobby;
    public string? CharacterId;
}
