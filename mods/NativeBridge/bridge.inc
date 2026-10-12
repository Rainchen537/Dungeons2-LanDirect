// Narrow bridge for the exact verified executable. No executable code hooks.
static std::string Name(const void* address) {
    uint32_t index=0; if(!Read(address,index) || (index>>16)>8191) return "";
    uintptr_t block=0;
    if(!Read(reinterpret_cast<void*>(imageBase+0xbe71f40+0x10+8*(index>>16)),block) || !block) return "";
    uintptr_t entry=block+2*(index&0xffff); uint16_t header=0;
    if(!Read(reinterpret_cast<void*>(entry),header)) return "";
    unsigned length=header>>6; if(!length || length>128 || (header&1)) return "";
    std::string value(length,'\0'); SIZE_T count;
    if(!ReadProcessMemory(GetCurrentProcess(),reinterpret_cast<void*>(entry+2),value.data(),length,&count) || count!=length) return "";
    return value;
}
static int Field(uintptr_t object,const char* key) {
    uintptr_t cls=0; if(!Read(reinterpret_cast<void*>(object+0x10),cls)) return -1;
    uintptr_t prop=0; if(!Read(reinterpret_cast<void*>(cls+0x50),prop)) return -1;
    for(int i=0;prop && i<32;i++) {
        if(Name(reinterpret_cast<void*>(prop+0x20))==key) {
            int offset=-1; if(!Read(reinterpret_cast<void*>(prop+0x48),offset) || offset<0x28 || offset>0x200) return -1;
            return offset;
        }
        if(!Read(reinterpret_cast<void*>(prop+0x18),prop)) return -1;
    }
    return -1;
}
static uintptr_t Session(uintptr_t gi) {
    uintptr_t array=0; int count=0;
    if(!Read(reinterpret_cast<void*>(gi+0x50),array) || !Read(reinterpret_cast<void*>(gi+0x58),count) || count<0 || count>256) return 0;
    for(int i=0;i<count;i++) {
        uintptr_t object=0,cls=0;
        if(!Read(reinterpret_cast<void*>(array+i*8),object) || !object || !Read(reinterpret_cast<void*>(object+0x10),cls)) continue;
        if(Name(reinterpret_cast<void*>(cls+0x18))=="LanSessionState_C") return object;
    }
    return 0;
}
static void ObserveNetwork(uintptr_t world,uintptr_t gi) {
    uintptr_t players=0,controller=0,pawn=0,camera=0,state=0,driver=0,server=0,cls=0;
    int playerCount=0,peers=0;
    Read(reinterpret_cast<void*>(gi+0x38),players);
    Read(reinterpret_cast<void*>(gi+0x40),playerCount);
    if(playerCount>0 && playerCount<5 && players) {
        uintptr_t local=0;Read(reinterpret_cast<void*>(players),local);
        if(local) Read(reinterpret_cast<void*>(local+0x30),controller);
    }
    if(controller) {
        Read(reinterpret_cast<void*>(controller+0x10),cls);
        Read(reinterpret_cast<void*>(controller+0x2e8),pawn);
        Read(reinterpret_cast<void*>(controller+0x360),camera);
    }
    Read(reinterpret_cast<void*>(world+0x1b0),state);
    Read(reinterpret_cast<void*>(world+0x38),driver);
    if(driver) {
        Read(reinterpret_cast<void*>(driver+0xf0),server);
        Read(reinterpret_cast<void*>(driver+0x100),peers);
    }
    char text[300];
    snprintf(text,sizeof(text),"Network state world=%s controller=%s pawn=%d camera=%d gameState=%d driver=%d serverConnection=%d peers=%d",
        Name(reinterpret_cast<void*>(world+0x18)).c_str(),cls?Name(reinterpret_cast<void*>(cls+0x18)).c_str():"none",
        pawn!=0,camera!=0,state!=0,driver!=0,server!=0,peers);
    static std::string previous;
    if(previous!=text) { previous=text;Log(text); }
}
#include "host_guard.inc"
static void CALLBACK BridgeTick(HWND,UINT,UINT_PTR,DWORD) {
    static bool inside=false; if(inside) return;
    uintptr_t engine=0,contexts=0; int count=0;
    if(!Read(reinterpret_cast<void*>(imageBase+0xc0e7110),engine) || !engine ||
       !Read(reinterpret_cast<void*>(engine+0x1148),contexts) || !Read(reinterpret_cast<void*>(engine+0x1150),count) || count!=1) return;
    uintptr_t ctx=0,world=0,gi=0;
    if(!Read(reinterpret_cast<void*>(contexts),ctx) || !Read(reinterpret_cast<void*>(ctx+0x2c0),world) || !world ||
       !Read(reinterpret_cast<void*>(world+0x228),gi) || !gi) return;
    ObserveNetwork(world,gi);
    uintptr_t session=Session(gi); if(!session) return;
    int stageOffset=Field(session,"Stage"),operationOffset=Field(session,"Operation"),statusOffset=Field(session,"NativeListenStatus"),valueOffset=Field(session,"Value");
    if(stageOffset<0 || operationOffset<0 || statusOffset<0 || valueOffset<0) return;
    int stage=0,operation=0,status=0;
    if(!Read(reinterpret_cast<void*>(session+stageOffset),stage) || !Read(reinterpret_cast<void*>(session+operationOffset),operation) ||
       !Read(reinterpret_cast<void*>(session+statusOffset),status) || operation!=1 || status!=0 || (stage!=2 && stage!=3)) return;
    auto map=Name(reinterpret_cast<void*>(world+0x18));
    if((stage==3 && map!="Menu_Spicewood") || (stage==2 && map!="Overworld")) return;
    String value{}; if(!Read(reinterpret_cast<void*>(session+valueOffset),value)) return;
    auto text=ReadString(value); int port=0;
    if(text.empty() || text.size()>5) return;
    for(wchar_t ch:text) { if(ch<L'0' || ch>L'9') return; port=port*10+(ch-L'0'); }
    if(port<1 || port>65535) return;
    // Independently verify startup settings before creating the listener.
    // The installer protects Engine.ini; do not mutate read-only CVars here.
    if(stage==3) {
        int streaming=0;unsigned char streamingOut=0;
        if(!Read(reinterpret_cast<void*>(imageBase+0xc0e6020),streaming) ||
           !Read(reinterpret_cast<void*>(imageBase+0xc0e6024),streamingOut) || streaming!=1 || streamingOut!=1) {
            *reinterpret_cast<int*>(session+statusOffset)=-1;
            Log("Server streaming references differ; hosting refused.");return;
        }
        Log("Server streaming startup values verified: load=1 unload=1.");
    }
    uintptr_t vtable=0,function=0;
    if(!Read(reinterpret_cast<void*>(gi),vtable) || !Read(reinterpret_cast<void*>(vtable+0x380),function) || function!=imageBase+0x3d517a0) {
        *reinterpret_cast<int*>(session+statusOffset)=-1;
        Log("GameInstance EnableListenServer implementation differs; request refused."); return;
    }
    if(stage==2 && !InstallHostIdentityGuard(world)) {
        *reinterpret_cast<int*>(session+statusOffset)=-1;
        Log("Host identity protection unavailable; listener not started.");return;
    }
    inside=true;
    char message[180]; snprintf(message,sizeof(message),"EnableListenServer request: map=%s port=%d stage=%d game thread=%lu",map.c_str(),port,stage,GetCurrentThreadId()); Log(message);
    using Enable=bool (*)(void*,bool,int);
    bool enabled=reinterpret_cast<Enable>(function)(reinterpret_cast<void*>(gi),true,port);
    uintptr_t driver=0; Read(reinterpret_cast<void*>(world+0x38),driver);
    *reinterpret_cast<int*>(session+statusOffset)=enabled && driver ? 1 : -1;
    snprintf(message,sizeof(message),"EnableListenServer returned=%d netDriver=%d; no map travel",enabled,driver!=0); Log(message);

    inside=false;
}
static BOOL CALLBACK FindGameWindow(HWND window,LPARAM parameter) {
    DWORD process=0; GetWindowThreadProcessId(window,&process);
    if(process==GetCurrentProcessId() && IsWindowVisible(window) && !GetWindow(window,GW_OWNER)) {
        *reinterpret_cast<HWND*>(parameter)=window; return FALSE;
    }
    return TRUE;
}
static void StartBridgeTimer() {
    // Steam/first-run startup can take minutes. Keep the worker alive until
    // a game window exists instead of silently disabling the bridge at 30 s.
    for(unsigned attempt=0;;attempt++) {
        HWND window=nullptr; EnumWindows(FindGameWindow,reinterpret_cast<LPARAM>(&window));
        if(window) {
            DWORD thread=GetWindowThreadProcessId(window,nullptr);
            if(SetTimer(window,0x4c414e44,100,BridgeTick)) {
                char message[120];snprintf(message,sizeof(message),"Native bridge timer installed on owning game window thread=%lu; no code hooks",thread);Log(message);return;
            }
        }
        if(attempt && attempt%600==0) Log("Still waiting for the game window; bridge initialization will retry.");
        Sleep(100);
    }
}
