param([string]$Dotnet='dotnet', [string]$SourcePath)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
if (-not $SourcePath) { $SourcePath=Join-Path $root 'mods\LanDirect\ModActor.cs' }
$fixture=Join-Path $root 'artifacts\host-streaming-test'
New-Item -ItemType Directory -Path $fixture -Force | Out-Null
$source=[IO.File]::ReadAllText($SourcePath)
$start=$source.IndexOf('    void Host()')
$end=$source.IndexOf('    void VerifyLobbyListener()')
if ($start -lt 0 -or $end -le $start) { throw 'Host source boundaries changed.' }
$method=$source.Substring($start,$end-$start)
# Execute the production Host method with simulated CVar reads and timer dispatch.
$harness=@'
using System;
public class Session { public int Stage,Operation,NativeListenStatus; public string Value="",CharacterId=""; public bool StartedFromOfflineLobby; }
public class Panel { public void SetStatus(string text) {} }
public static class World { public static string LevelName(object actor) => "Menu_Spicewood"; }
public static class Log { public static void Write(string text) {} }
public static class Timer { public static int Starts; public static void Start(object actor,string method,float seconds,bool loop) { Starts++; } }
public static class UKismetSystemLibrary {
    public static int Streaming,StreamingOut;
    public static int GetConsoleVariableIntValue(string name) => name.EndsWith("Out") ? StreamingOut : Streaming;
}
public partial class ModActor {
    string port="7777"; Session session=new(); bool travelling; int initializationPolls; Panel panel=new();
    public string Message="";
    static bool Number(string text,int min,int max) => true;
    string SelectedOfflineCharacterId() => "offline-hero";
    void Feedback(string text) => Message=text;
    void VerifyLobbyListener() {}
    public void Run() => Host();
    public int Stage => session.Stage;
}
public static class Program {
    public static void Main() {
        foreach (var values in new[] { (0,0),(0,1),(1,0),(-1,1),(1,2) }) {
            UKismetSystemLibrary.Streaming=values.Item1; UKismetSystemLibrary.StreamingOut=values.Item2; Timer.Starts=0;
            var actor=new ModActor(); actor.Run();
            if (actor.Stage!=0 || Timer.Starts!=0 || !actor.Message.Contains("Repair.cmd")) throw new Exception("Host started with inactive startup streaming values");
        }
        Console.WriteLine("PASS: inactive streaming values leave the session idle and show the repair action");
        UKismetSystemLibrary.Streaming=1; UKismetSystemLibrary.StreamingOut=1; Timer.Starts=0;
        var ready=new ModActor(); ready.Run();
        if (ready.Stage!=3 || Timer.Starts!=1 || ready.Message.Length!=0) throw new Exception("Ready streaming values did not request one lobby listener");
        Console.WriteLine("PASS: both startup values enabled request one listener");
    }
}
'@
[IO.File]::WriteAllText((Join-Path $fixture 'Program.cs'),$harness+"`npublic partial class ModActor {`n"+$method+"`n}")
$project='<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net10.0</TargetFramework><NoWarn>CS0169;CS0414;CS0649</NoWarn></PropertyGroup></Project>'
[IO.File]::WriteAllText((Join-Path $fixture 'HostStreaming.csproj'),$project)
& $Dotnet run --project (Join-Path $fixture 'HostStreaming.csproj') --verbosity quiet
if ($LASTEXITCODE -ne 0) { throw 'Host streaming regression failed.' }
