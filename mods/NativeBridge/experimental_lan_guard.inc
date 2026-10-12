// Isolated Host experiment for build 25754144 only.
// Native PostLogin subscriber dereferences GetLocalPlayer() on remote PCs.
static void LanLocalPlayerPostLogin(uintptr_t subscriber,uintptr_t mode,uintptr_t controller) {
    using GetLocalFn=uintptr_t(*)(uintptr_t);
    if(controller && !reinterpret_cast<GetLocalFn>(imageBase+0x41a06b0)(controller)) {
        Log("LAN EXPERIMENT: skipped local-player-only PostLogin subscriber for remote controller.");
        return;
    }
    using Callback=void(*)(uintptr_t,uintptr_t,uintptr_t);
    reinterpret_cast<Callback>(imageBase+0x56b6fc0)(subscriber,mode,controller);
}
static void TryLanJoinGuard() {
    static bool checked=false,enabled=false;static ULONGLONG next=0;
    if(!checked) {
        checked=true;wchar_t path[MAX_PATH]{};GetModuleFileNameW(nullptr,path,MAX_PATH);
        enabled=wcsstr(GetCommandLineW(),L"-LanDirectJoinExperiment") &&
            wcsstr(path,L"\\LanDirectTests\\") && wcsstr(path,L"\\Host\\");
    }
    if(!enabled || GetTickCount64()<next)return;
    next=GetTickCount64()+1000;
    uintptr_t array=0;int count=0;
    if(!Read(reinterpret_cast<void*>(imageBase+0xbb53b68),array) || !array ||
       !Read(reinterpret_cast<void*>(imageBase+0xbb53b70),count) || count<1 || count>128)return;
    for(int i=0;i<count;i++) {
        uintptr_t delegate=0,table=0,execute=0,callback=0;int size=0;
        if(!Read(reinterpret_cast<void*>(array+i*16),delegate) || !delegate ||
           !Read(reinterpret_cast<void*>(array+i*16+8),size) || size<=0 ||
           !Read(reinterpret_cast<void*>(delegate),table) || !table ||
           !Read(reinterpret_cast<void*>(table+0x60),execute) || execute!=imageBase+0x52bd5c0 ||
           !Read(reinterpret_cast<void*>(delegate+0x20),callback) || callback!=imageBase+0x56b6fc0)continue;
        *reinterpret_cast<uintptr_t*>(delegate+0x20)=reinterpret_cast<uintptr_t>(LanLocalPlayerPostLogin);
        Log("LAN EXPERIMENT: guarded native PostLogin subscriber; remote LocalPlayer null is expected.");
    }
}
