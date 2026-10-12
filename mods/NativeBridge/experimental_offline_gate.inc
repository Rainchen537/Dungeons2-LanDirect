// Experimental isolated Client build only; absent from release builds.
using PrerequisiteFn=void(*)(uintptr_t);
static uintptr_t offlinePlatform=0;
static void SetTestPlatformDisconnected() {
    uintptr_t data=0;int count=0;
    if(!offlinePlatform || !Read(reinterpret_cast<void*>(offlinePlatform+0x88),data) || !data ||
       !Read(reinterpret_cast<void*>(offlinePlatform+0x90),count) || count!=1)return;
    uintptr_t text=0;int length=0;wchar_t key[9]{};
    if(!Read(reinterpret_cast<void*>(data),text) || !text ||
       !Read(reinterpret_cast<void*>(data+8),length) || length!=9 ||
       !ReadProcessMemory(GetCurrentProcess(),reinterpret_cast<void*>(text),key,sizeof(key),nullptr) ||
       wcscmp(key,L"PLATFORM")!=0)return;
    *reinterpret_cast<unsigned char*>(data+16)=1;
}
static void OfflinePrerequisite(uintptr_t state) {
    auto original=reinterpret_cast<PrerequisiteFn>(imageBase+0x62135e0);
    uintptr_t handler=0,config=0,crossplay=0,cls=0,list=0,data=0;
    int count=0;
    bool filtered=false;
    if(Read(reinterpret_cast<void*>(state+0x28),handler) && handler &&
       Read(reinterpret_cast<void*>(handler+0x170),config) && config &&
       Read(reinterpret_cast<void*>(config+0x50),crossplay) && crossplay &&
       Read(reinterpret_cast<void*>(crossplay+0x10),cls) && cls &&
       Name(reinterpret_cast<void*>(cls+0x18))=="CrossplayOSSImplementation" &&
       Read(reinterpret_cast<void*>(crossplay+0x28),list) && list &&
       Read(reinterpret_cast<void*>(list),data) && data &&
       Read(reinterpret_cast<void*>(list+8),count) && count>0 && count<=8) {
        auto entry=reinterpret_cast<unsigned char*>(data+24*(count-1));
        unsigned char kind=0;uintptr_t cached=0;
        if(Read(entry,kind) && kind==4 && Name(entry+4)=="STEAM" &&
           Read(entry+16,cached) && !cached) {
            *reinterpret_cast<int*>(list+8)=count-1;
            filtered=true;
            Log("EXPERIMENT: checking prerequisites without the missing STEAM entry.");
        }
    }
    original(state);
    if(filtered) {
        // The list's storage was never replaced or freed. Restore visibility
        // after the original check returns; keep Steam configuration elsewhere.
        if(*reinterpret_cast<uintptr_t*>(list)==data &&
           *reinterpret_cast<int*>(list+8)==count-1)
            *reinterpret_cast<int*>(list+8)=count;
        Log("EXPERIMENT: original prerequisite call returned; STEAM descriptor restored.");
    }
}
static void OfflineStaticCheck(uintptr_t state) {
    uintptr_t handler=0;
    if(!Read(reinterpret_cast<void*>(state+0x28),handler) || !handler)return;
    Log("EXPERIMENT: isolated no-Steam static gate disabled; advancing native offline flow.");
    using AdvanceFn=void(*)(uintptr_t,uintptr_t);
    reinterpret_cast<AdvanceFn>(imageBase+0x620e9a0)(handler,state+0x30);
}
static void WrapPrerequisite(uintptr_t state) {
    uintptr_t cls=0,table=0,method=0;
    if(!state || !Read(reinterpret_cast<void*>(state+0x10),cls) || !cls ||
       !Read(reinterpret_cast<void*>(state),table) || !table ||
       !Read(reinterpret_cast<void*>(table+0x2b0),method))return;
    auto name=Name(reinterpret_cast<void*>(cls+0x18));
    uintptr_t replacement=0;
    if(name=="CheckPrerequisitesLoginState" && method==imageBase+0x62135e0)
        replacement=reinterpret_cast<uintptr_t>(OfflinePrerequisite);
    else if(name=="NoInternetCheckStaticEntitlementState" && method==imageBase+0x62232d0 &&
            wcsstr(GetCommandLineW(),L"-nosteam"))
        replacement=reinterpret_cast<uintptr_t>(OfflineStaticCheck);
    else return;
    static std::map<uintptr_t,std::unique_ptr<uintptr_t[]>> tables;
    auto it=tables.find(table);
    if(it==tables.end()) {
        auto copy=std::make_unique<uintptr_t[]>(89);SIZE_T received=0;
        if(!ReadProcessMemory(GetCurrentProcess(),reinterpret_cast<void*>(table-8),copy.get(),89*8,&received) || received!=89*8)return;
        copy[1+0x2b0/8]=replacement;
        it=tables.emplace(table,std::move(copy)).first;
    }
    *reinterpret_cast<uintptr_t*>(state)=reinterpret_cast<uintptr_t>(it->second.get()+1);
    Log("EXPERIMENT: pending prerequisite instance wrapped before first entry.");
}
static void OfflineLoginTick(uintptr_t tickable,float delta) {
    SetTestPlatformDisconnected();
    uintptr_t handler=tickable-0x28,pending=0;int mode=-1;
    if(Read(reinterpret_cast<void*>(handler+0xf0),mode) && mode==0 &&
       Read(reinterpret_cast<void*>(handler+0xf8),pending) && pending) {
        WrapPrerequisite(pending);
        uintptr_t cls=0;
        if(Read(reinterpret_cast<void*>(pending+0x10),cls)&&cls) {
            auto name=Name(reinterpret_cast<void*>(cls+0x18));
            static std::string previous;
            if(name!=previous){previous=name;Log(("Login transition: "+name).c_str());}
        }
    }
    using TickFn=void(*)(uintptr_t,float);
    reinterpret_cast<TickFn>(imageBase+0x52bc7b0)(tickable,delta);
    // StatePerTick already queues transitions while a state is executing.
    // Queue requests made between ticks as well, so new states can be wrapped.
    if(mode==0)*reinterpret_cast<unsigned char*>(handler+0xf4)=1;
}
static void TryOfflineGateExperiment() {
    static bool checked=false,enabled=false,done=false;static ULONGLONG next=0;
    if(!checked) {
        checked=true;wchar_t path[MAX_PATH]{};GetModuleFileNameW(nullptr,path,MAX_PATH);
        enabled=wcsstr(GetCommandLineW(),L"-LanDirectOfflineGateExperiment") &&
            (wcsstr(GetCommandLineW(),L"-nosteam") || wcsstr(GetCommandLineW(),L"-LanDirectOfflineFlowControl")) &&
            wcsstr(path,L"\\LanDirectTests\\") && wcsstr(path,L"\\Client\\");
    }
    if(!enabled || done || GetTickCount64()<next)return;
    next=GetTickCount64()+2000;
    uintptr_t chunks=0;int count=0;
    if(!Read(reinterpret_cast<void*>(imageBase+0xbf55b00),chunks) || !chunks ||
       !Read(reinterpret_cast<void*>(imageBase+0xbf55b14),count) || count<1 || count>1000000)return;
    for(int i=0;i<count;i++) {
        uintptr_t platformChunk=0,platformObject=0,platformClass=0;
        if(Read(reinterpret_cast<void*>(chunks+8*(i/65536)),platformChunk) && platformChunk &&
           Read(reinterpret_cast<void*>(platformChunk+24*(i%65536)),platformObject) && platformObject &&
           Read(reinterpret_cast<void*>(platformObject+0x10),platformClass) && platformClass &&
           Name(reinterpret_cast<void*>(platformClass+0x18))=="PlatformServiceConnection" &&
           Name(reinterpret_cast<void*>(platformObject+0x18)).find("Default__")!=0)offlinePlatform=platformObject;
    }
    SetTestPlatformDisconnected();
    for(int i=0;i<count;i++) {
        uintptr_t chunk=0,object=0,cls=0,table=0,method=0;int mode=-1;
        if(!Read(reinterpret_cast<void*>(chunks+8*(i/65536)),chunk) || !chunk ||
           !Read(reinterpret_cast<void*>(chunk+24*(i%65536)),object) || !object ||
           !Read(reinterpret_cast<void*>(object+0x10),cls) || !cls ||
           Name(reinterpret_cast<void*>(cls+0x18))!="LoginHandler" ||
           Name(reinterpret_cast<void*>(object+0x18)).find("Default__")==0 ||
           !Read(reinterpret_cast<void*>(object+0xf0),mode) || mode!=0 ||
           !Read(reinterpret_cast<void*>(object+0x28),table) || !table ||
           !Read(reinterpret_cast<void*>(table),method) || method!=imageBase+0x52bc7b0)continue;
        static std::unique_ptr<uintptr_t[]> shadow;
        auto copy=std::make_unique<uintptr_t[]>(10);SIZE_T received=0;
        if(!ReadProcessMemory(GetCurrentProcess(),reinterpret_cast<void*>(table-8),copy.get(),80,&received) || received!=80)return;
        copy[1]=reinterpret_cast<uintptr_t>(OfflineLoginTick);shadow=std::move(copy);
        *reinterpret_cast<uintptr_t*>(object+0x28)=reinterpret_cast<uintptr_t>(shadow.get()+1);
        *reinterpret_cast<unsigned char*>(object+0xf4)=1;
        done=true;
        Log("EXPERIMENT: isolated LoginHandler tick wrapped; game code and global vtables untouched.");
        return;
    }
}
