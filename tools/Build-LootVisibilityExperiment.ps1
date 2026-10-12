param([string]$Compiler='C:\msys64\ucrt64\bin\g++.exe')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$source=Join-Path $root 'mods\NativeBridge'
$work=Join-Path $env:TEMP ('LanDirectLoot-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
Copy-Item -LiteralPath (Join-Path $source 'experimental_loot_visibility.inc') -Destination $work
# Reuse the existing checked reader, FName decoder and exact EXE SHA-256 gate.
$common=(Get-Content -LiteralPath (Join-Path $source 'bridge.cpp') -Raw).Split('#include "bridge.inc"')[0]
$names=(Get-Content -LiteralPath (Join-Path $source 'bridge.inc') -Raw).Split('static int Field(')[0]
$entry=@'
#include "experimental_loot_visibility.inc"
static void CALLBACK LootTimer(HWND,UINT,UINT_PTR,DWORD) {
    static bool inside=false;if(inside)return;inside=true;
    LootVisibility::Poll();inside=false;
}
static BOOL CALLBACK LootWindow(HWND window,LPARAM result) {
    DWORD pid=0;GetWindowThreadProcessId(window,&pid);
    if(pid==GetCurrentProcessId() && IsWindowVisible(window) && !GetWindow(window,GW_OWNER)) {
        *reinterpret_cast<HWND*>(result)=window;return FALSE;
    }
    return TRUE;
}
static DWORD WINAPI StartLoot(void*) {
    wchar_t path[MAX_PATH]{};GetModuleFileNameW(nullptr,path,MAX_PATH);
    if(!wcsstr(path,L"\\LanDirectTests\\") || !wcsstr(path,L"\\Host\\") || !SupportedBuild()) {
        Log("LOOT VISIBILITY: refused unsupported executable or non-isolated Host.");return 0;
    }
    imageBase=reinterpret_cast<uintptr_t>(GetModuleHandleW(nullptr));
    // Validate render setter before it can be called.
    const unsigned char expected[]={0x44,0x0f,0xb6,0x81,0x6d,0x02,0x00,0x00};
    unsigned char bytes[sizeof(expected)]{};SIZE_T n=0;
    if(!ReadProcessMemory(GetCurrentProcess(),reinterpret_cast<void*>(imageBase+0x3bcb790),bytes,sizeof(bytes),&n) || n!=sizeof(bytes) || memcmp(bytes,expected,sizeof(bytes))) {
        Log("LOOT VISIBILITY: render setter signature differs; inactive.");return 0;
    }
    for(int i=0;i<600;++i) {
        HWND window=nullptr;EnumWindows(LootWindow,reinterpret_cast<LPARAM>(&window));
        if(window && SetTimer(window,0x4c4f4f54,100,LootTimer)) {
            Log("LOOT VISIBILITY: experimental render-only filter loaded on game-window thread.");return 0;
        }
        Sleep(100);
    }
    Log("LOOT VISIBILITY: game window unavailable; inactive.");return 0;
}
BOOL WINAPI DllMain(HINSTANCE instance,DWORD reason,LPVOID) {
    if(reason==DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(instance);GetModuleFileNameW(instance,logPath,MAX_PATH);
        wchar_t* slash=wcsrchr(logPath,L'\\');if(!slash)return FALSE;
        wcscpy(slash+1,L"LanDirect-loot.log");
        HANDLE thread=CreateThread(nullptr,0,StartLoot,nullptr,0,nullptr);
        if(thread)CloseHandle(thread);
    }
    return TRUE;
}
'@
[IO.File]::WriteAllText((Join-Path $work 'loot.cpp'),$common+$names+$entry)
$output=Join-Path $root 'artifacts\LootVisibility-experiment'
New-Item -ItemType Directory -Path $output -Force | Out-Null
& $Compiler -std=c++17 -O2 -shared -static -static-libgcc -static-libstdc++ -Wall -Wextra (Join-Path $work 'loot.cpp') -lbcrypt -o (Join-Path $work 'LanDirectLootVisibility.dll')
if($LASTEXITCODE -ne 0){throw 'Loot visibility experiment build failed'}
Copy-Item -LiteralPath (Join-Path $work 'LanDirectLootVisibility.dll') -Destination $output -Force
Get-FileHash -LiteralPath (Join-Path $output 'LanDirectLootVisibility.dll')
