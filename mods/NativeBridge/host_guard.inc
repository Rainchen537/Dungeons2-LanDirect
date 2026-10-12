// Guard only the local listener's GameMode instance. The original PreLogin
// removes a matching existing player, which would delete the listen host.
#include <map>
#include <memory>
using PreLoginFn=void(*)(uintptr_t,const String*,const String*,uintptr_t,String*);
static void GuardedPreLogin(uintptr_t mode,const String* options,const String* address,uintptr_t uniqueId,String* error) {
    auto table=*reinterpret_cast<uintptr_t**>(mode);
    auto original=reinterpret_cast<PreLoginFn>(table[-2]);
    uintptr_t world=0,gi=0,players=0;int count=0;
    using GetWorldFn=uintptr_t(*)(uintptr_t);
    world=reinterpret_cast<GetWorldFn>(imageBase+0x3932e20)(mode);
    if(world && uniqueId && error && Read(reinterpret_cast<void*>(world+0x228),gi) && gi &&
       Read(reinterpret_cast<void*>(gi+0x38),players) && players &&
       Read(reinterpret_cast<void*>(gi+0x40),count) && count>0 && count<=4) {
        using SameIdentityFn=bool(*)(const uintptr_t*,uintptr_t);
        auto same=reinterpret_cast<SameIdentityFn>(imageBase+0x63714a0);
        for(int i=0;i<count;i++) {
            uintptr_t local=0,controller=0,state=0;
            if(!Read(reinterpret_cast<void*>(players+i*8),local) || !local ||
               !Read(reinterpret_cast<void*>(local+0x30),controller) || !controller ||
               !Read(reinterpret_cast<void*>(controller+0x2b0),state) || !state) continue;
            if(same(&uniqueId,controller)) {
                const wchar_t message[]=L"LanDirect: this network identity is already used by the host. Use a different Steam account for the joining player.";
                using AppendFn=String*(*)(String*,const wchar_t*,int);
                reinterpret_cast<AppendFn>(imageBase+0x12a0c20)(error,message,static_cast<int>(wcslen(message)));
                Log("Rejected duplicate local network identity before original PreLogin; host controller preserved.");
                return;
            }
        }
    }
    original(mode,options,address,uniqueId,error);
}
static bool InstallHostIdentityGuard(uintptr_t world) {
    uintptr_t mode=0,table=0,method=0;
    if(!Read(reinterpret_cast<void*>(world+0x1a8),mode) || !mode ||
       !Read(reinterpret_cast<void*>(mode),table) || !table ||
       !Read(reinterpret_cast<void*>(table+0x860),method)) return false;
    if(method==reinterpret_cast<uintptr_t>(GuardedPreLogin)) return true;
    if(method!=imageBase+0x638f330) {Log("PreLogin implementation differs; duplicate identity guard refused.");return false;}
    const unsigned char matchSignature[]={0x48,0x89,0x5c,0x24,0x08,0x48,0x89,0x6c,0x24,0x10,0x48,0x89,0x74,0x24,0x18,0x57};
    unsigned char bytes[sizeof(matchSignature)]{};
    if(!Read(reinterpret_cast<void*>(imageBase+0x63714a0),bytes) || memcmp(bytes,matchSignature,sizeof(bytes))) return false;
    // Cache by original vtable so map/session changes cannot invalidate older
    // objects waiting for GC. Keep the original RTTI slot and original method.
    static std::map<uintptr_t,std::unique_ptr<uintptr_t[]>> tables;
    auto it=tables.find(table);
    if(it==tables.end()) {
        auto copy=std::make_unique<uintptr_t[]>(1026);SIZE_T received=0;
        if(!ReadProcessMemory(GetCurrentProcess(),reinterpret_cast<void*>(table-8),copy.get()+1,1025*sizeof(uintptr_t),&received) || received!=1025*sizeof(uintptr_t)) return false;
        copy[0]=method;copy[2+0x860/8]=reinterpret_cast<uintptr_t>(GuardedPreLogin);
        it=tables.emplace(table,std::move(copy)).first;
    }
    *reinterpret_cast<uintptr_t*>(mode)=reinterpret_cast<uintptr_t>(it->second.get()+2);
    Log("Host duplicate-identity guard installed; different identities retain original PreLogin validation.");
    return true;
}
