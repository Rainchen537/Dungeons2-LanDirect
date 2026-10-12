// Build 25754144 only. Listen-host presentation repair. Never remove loot,
// change ownership, alter currency simulation, or relax pickup checks.
#include <array>
#include <vector>
#include <unordered_set>
#include <unordered_map>
namespace LootVisibility {
static uintptr_t Q(uintptr_t p) { uintptr_t v=0;Read(reinterpret_cast<void*>(p),v);return v; }
static int I(uintptr_t p) { int v=0;Read(reinterpret_cast<void*>(p),v);return v; }
static bool IsA(uintptr_t object,const char* name) {
    for(uintptr_t c=Q(object+0x10),n=0;c && n<32;c=Q(c+0x40),++n)
        if(Name(reinterpret_cast<void*>(c+0x18))==name)return true;
    return false;
}
static bool Valid(uintptr_t object) {
    if(!object)return false;
    unsigned flags=0;return Read(reinterpret_cast<void*>(object+8),flags) && !(flags&0xc0000000);
}
static uintptr_t World() {
    uintptr_t e=Q(imageBase+0xc0e7110);
    if(!e || I(e+0x1150)!=1)return 0;
    return Q(Q(Q(e+0x1148))+0x2c0);
}
static uintptr_t LocalPawn(uintptr_t world) {
    uintptr_t driver=Q(world+0x38),gi=Q(world+0x228);
    if(!driver || Q(driver+0xf0) || !gi || I(gi+0x40)!=1)return 0;
    uintptr_t pc=Q(Q(Q(gi+0x38))+0x30);
    return pc?Q(pc+0x2e8):0;
}
static uintptr_t Resolve(uintptr_t weak) {
    return reinterpret_cast<uintptr_t(*)(uintptr_t)>(imageBase+0x16bd2a0)(weak);
}
static uintptr_t Subsystem(uintptr_t world,uintptr_t rva) {
    return reinterpret_cast<uintptr_t(*)(uintptr_t)>(imageBase+rva)(world);
}
static bool SparseUsed(uintptr_t map,int index) {
    int bits=I(map+0x28);if(index<0 || index>=bits)return false;
    uintptr_t words=Q(map+0x20);if(!words)words=map+0x10;
    unsigned word=0;return Read(reinterpret_cast<void*>(words+(index/32)*4),word) && (word&(1u<<(index%32)));
}
static std::unordered_set<uint64_t> loggedCurrency;
static void FilterCurrency(uintptr_t actor) {
    uintptr_t world=World(),local=world?LocalPawn(world):0;
    if(!Valid(local))return;
    uintptr_t currency=Subsystem(world,0x5b59a60),channel=Subsystem(world,0x5b0b660);
    if(!Valid(currency))return;
    uintptr_t proxies=Q(actor+0x850),states=Q(currency+0x80);
    int count=I(actor+0x858),slots=I(currency+0x88);
    if(!proxies || count<0 || count>4096 || !states || slots<0 || slots>8192)return;
    for(int i=0;i<count;++i) {
        uintptr_t proxy=proxies+i*0x90,owner=Resolve(proxy+0x70);
        if(!Valid(owner) || owner==local || !IsA(owner,"Pawn"))continue;
        uint64_t uid=Q(proxy+0x10);if(!uid)continue;
        // Hide only the local ISM instance, retaining the authoritative proxy.
        alignas(16) double transform[12]{};
        SIZE_T read=0;
        if(!ReadProcessMemory(GetCurrentProcess(),reinterpret_cast<void*>(proxy+0x40),transform,32,&read) || read!=32)continue;
        transform[6]=-100000000.0; // render translation only; scale remains zero
        reinterpret_cast<void(*)(uintptr_t,const uint64_t*,const void*)>(imageBase+0x5b8d970)(actor,&uid,transform);
        // Submit a separate presentation copy to Niagara. The simulation map's
        // position, speed, lifetime, color and pickup flag remain untouched.
        if(Valid(channel))for(int j=0;j<slots;++j) {
            if(!SparseUsed(currency+0x80,j))continue;
            uintptr_t entry=states+j*0x58;if(Q(entry)!=uid)continue;
            alignas(16) unsigned char copy[0x48]{};
            if(!ReadProcessMemory(GetCurrentProcess(),reinterpret_cast<void*>(entry+8),copy,sizeof(copy),&read) || read!=sizeof(copy))break;
            double hiddenZ=-100000000.0;memcpy(copy+0x20,&hiddenZ,sizeof(hiddenZ));
            memset(copy+0x2c,0,16);
            reinterpret_cast<void(*)(uintptr_t,const void*)>(imageBase+0x5b556e0)(channel,copy);
            break;
        }
        if(loggedCurrency.insert(uid).second) {
            char line[160];snprintf(line,sizeof(line),"LOOT VISIBILITY: remote currency uid=%llu local presentation filtered; authoritative proxy retained.",static_cast<unsigned long long>(uid));Log(line);
        }
    }
}
static void Tick(uintptr_t actor,float delta) {
    reinterpret_cast<void(*)(uintptr_t,float)>(imageBase+0x5b89430)(actor,delta);
    FilterCurrency(actor);
}
static std::vector<std::array<uintptr_t,513>*> tables;
static void InstallCurrencyTick(uintptr_t world) {
    uintptr_t sub=Subsystem(world,0x5b59ae0),actor=sub?Q(sub+0x58):0;
    if(!Valid(actor) || !IsA(actor,"SWWorldActor"))return;
    uintptr_t table=Q(actor),tick=Q(table+0x518);
    if(tick==reinterpret_cast<uintptr_t>(Tick))return;
    if(tick!=imageBase+0x5b89430)return;
    auto* shadow=new std::array<uintptr_t,513>;
    SIZE_T copied=0;
    if(!ReadProcessMemory(GetCurrentProcess(),reinterpret_cast<void*>(table-8),shadow->data(),sizeof(*shadow),&copied) || copied!=sizeof(*shadow)) {delete shadow;return;}
    (*shadow)[1+0x518/8]=reinterpret_cast<uintptr_t>(Tick);
    tables.push_back(shadow); // vtables must outlive actors, including teardown
    *reinterpret_cast<uintptr_t*>(actor)=reinterpret_cast<uintptr_t>(shadow->data()+1);
    Log("LOOT VISIBILITY: installed per-world currency presentation tick; no executable patch.");
}
static void FilterGear(uintptr_t local) {
    uintptr_t ps=Q(local+0x2c8); // APawn::PlayerState, validated by reflection
    if(!ps)return;
    int playerId=I(ps+0x2ac);
    uintptr_t chunks=Q(imageBase+0xbf55b00);int count=I(imageBase+0xbf55b00+0x14);
    if(!chunks || count<=0 || count>1000000)return;
    int changed=0;
    static std::unordered_map<uintptr_t,bool> primitiveClasses;
    for(int i=0;i<count;++i) {
        uintptr_t chunk=Q(chunks+(i/65536)*8),component=chunk?Q(chunk+(i%65536)*24):0;
        if(!Valid(component))continue;
        uintptr_t cls=Q(component+0x10);
        auto known=primitiveClasses.find(cls);
        bool primitive=known==primitiveClasses.end()?IsA(component,"PrimitiveComponent"):known->second;
        if(known==primitiveClasses.end())primitiveClasses[cls]=primitive;
        if(!primitive)continue;
        // Owner is at +0xa0 for ActorComponents. Check its class before doing
        // a full component hierarchy walk, keeping the scan inexpensive.
        uintptr_t owner=Q(component+0xa0);
        if(!Valid(owner) || Name(reinterpret_cast<void*>(Q(owner+0x10)+0x18))!="SWItemActor")continue;
        uintptr_t item=Q(owner+0x460);
        if(!Valid(item))continue;
        int lootId=I(item+0x100);
        // Zero/negative IDs (e.g. shared TNT) are not personal equipment.
        if(lootId<=0 || lootId==playerId)continue;
        // OwningPlayerID remains meaningful after the remote pawn disconnects;
        // orphaned personal loot must not become visible to the host again.
        unsigned char flags=0;Read(reinterpret_cast<void*>(component+0x26d),flags);
        if(flags&2)continue;
        // Engine render-only flag + MarkRenderStateDirty. Do not use replicated
        // Actor.bHidden, which could also hide the item from its actual owner.
        reinterpret_cast<void(*)(uintptr_t,bool)>(imageBase+0x3bcb790)(component,true);
        ++changed;
    }
    if(changed) {char line[120];snprintf(line,sizeof(line),"LOOT VISIBILITY: %d remote equipment render components set OnlyOwnerSee; ownership unchanged.",changed);Log(line);}
}
static void Poll() {
    static ULONGLONG next=0;
    uintptr_t world=World(),local=world?LocalPawn(world):0;
    if(!Valid(local))return;
    InstallCurrencyTick(world);
    if(GetTickCount64()<next)return;
    next=GetTickCount64()+500;
    FilterGear(local);
}
}
static void TryLootVisibilityExperiment() {
    static int enabled=-1;
    if(enabled<0) {
        wchar_t path[MAX_PATH]{};GetModuleFileNameW(nullptr,path,MAX_PATH);
        enabled=wcsstr(GetCommandLineW(),L"-LanDirectJoinExperiment") &&
            wcsstr(path,L"\\LanDirectTests\\") && wcsstr(path,L"\\Host\\");
    }
    if(enabled)LootVisibility::Poll();
}
