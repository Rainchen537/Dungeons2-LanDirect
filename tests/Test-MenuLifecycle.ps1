param([string]$Dotnet = 'dotnet', [string]$SourcePath)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $SourcePath) { $SourcePath = Join-Path $root 'mods\LanDirect\ModActor.cs' }
$fixture = Join-Path $root 'artifacts\menu-lifecycle-test'
New-Item -ItemType Directory -Path $fixture -Force | Out-Null
$source = [IO.File]::ReadAllText($SourcePath)
# Execute the production attachment methods, rather than a copy of the algorithm.
# Engine objects are simulated; the NeoRune build separately checks real bindings.
$start = $source.IndexOf('    void AttachPanel()')
$end = $source.IndexOf('    void OnLobbyPlayClicked(')
$fieldsStart = $source.IndexOf('{', $source.IndexOf('public class ModActor')) + 1
$fieldsEnd = $source.IndexOf('    protected override void ReceiveBeginPlay()')
if ($start -lt 0 -or $end -le $start -or $fieldsEnd -le $fieldsStart) { throw 'Production source layout changed; update the harness extraction.' }
$methods = $source.Substring($start, $end - $start)
$fields = $source.Substring($fieldsStart, $fieldsEnd - $fieldsStart)
$generated = "public partial class ModActor {`n$fields`n$methods`n}"
[IO.File]::WriteAllText((Join-Path $fixture 'Attachment.cs'), $generated)
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'MenuLifecycleHarness.cs') -Destination (Join-Path $fixture 'Program.cs') -Force
$project = @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <NoWarn>CS0169;CS0414;CS0649</NoWarn>
  </PropertyGroup>
</Project>
'@
[IO.File]::WriteAllText((Join-Path $fixture 'MenuLifecycle.csproj'), $project)
& $Dotnet run --project (Join-Path $fixture 'MenuLifecycle.csproj') --verbosity quiet
if ($LASTEXITCODE -ne 0) { throw 'Menu lifecycle regression test failed.' }
