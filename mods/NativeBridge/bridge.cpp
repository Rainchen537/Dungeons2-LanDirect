#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <bcrypt.h>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>



extern bool InitializeDwmForwarding();
static wchar_t logPath[MAX_PATH];
static SRWLOCK logLock = SRWLOCK_INIT;
static uintptr_t imageBase;
static bool quietDebugOutput;
static void Log(const char* message) {
    AcquireSRWLockExclusive(&logLock);
    HANDLE file=CreateFileW(logPath, FILE_APPEND_DATA, FILE_SHARE_READ|FILE_SHARE_WRITE,
        nullptr, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if(file!=INVALID_HANDLE_VALUE) {
        SYSTEMTIME time; GetLocalTime(&time);
        char prefix[64]; int count=snprintf(prefix,sizeof(prefix),"%02u:%02u:%02u.%03u [%lu] ",
            time.wHour,time.wMinute,time.wSecond,time.wMilliseconds,GetCurrentThreadId());
        DWORD written; WriteFile(file,prefix,count,&written,nullptr);
        WriteFile(file,message,static_cast<DWORD>(strlen(message)),&written,nullptr);
        WriteFile(file,"\r\n",2,&written,nullptr); CloseHandle(file);
    }
    ReleaseSRWLockExclusive(&logLock);
}
template<class T> static bool Read(const void* p,T& value) {
    SIZE_T count=0; return p && ReadProcessMemory(GetCurrentProcess(),p,&value,sizeof(value),&count) && count==sizeof(value);
}
struct String { const wchar_t* data; int count; int capacity; };
struct Options { const String* data; int count; int capacity; };
static std::wstring ReadString(const String& value) {
    if(value.count<=1 || value.count>2048 || !value.data) return L"";
    std::wstring result(value.count,L'\0'); SIZE_T count=0;
    auto bytes=static_cast<SIZE_T>(value.count)*2;
    if(!ReadProcessMemory(GetCurrentProcess(),value.data,result.data(),bytes,&count) || count!=bytes) return L"";
    result.resize(value.count-1); return result;
}
static bool SupportedBuild() {
    wchar_t executable[MAX_PATH]; GetModuleFileNameW(nullptr,executable,MAX_PATH);
    HANDLE file=CreateFileW(executable,GENERIC_READ,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,
        nullptr,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,nullptr);
    if(file==INVALID_HANDLE_VALUE) return false;
    BCRYPT_ALG_HANDLE algorithm=nullptr; BCRYPT_HASH_HANDLE hash=nullptr;
    bool ok=BCryptOpenAlgorithmProvider(&algorithm,BCRYPT_SHA256_ALGORITHM,nullptr,0)>=0;
    if(ok) ok=BCryptCreateHash(algorithm,&hash,nullptr,0,nullptr,0,0)>=0;
    unsigned char buffer[65536],digest[32]{}; DWORD count;
    while(ok) {
        if(!ReadFile(file,buffer,sizeof(buffer),&count,nullptr)) { ok=false; break; }
        if(!count) break;
        ok=BCryptHashData(hash,buffer,count,0)>=0;
    }
    if(ok) ok=BCryptFinishHash(hash,digest,sizeof(digest),0)>=0;
    if(hash) BCryptDestroyHash(hash);
    if(algorithm) BCryptCloseAlgorithmProvider(algorithm,0);
    CloseHandle(file);
    char hex[65]; for(int i=0;i<32;i++) snprintf(hex+i*2,3,"%02X",digest[i]);
    return ok && strcmp(hex,"3A8703406FD50520F83C4F70A0212C000CB3B584EF28EB38032902230C01EBDD")==0;
}
#include "bridge.inc"
static LONG CALLBACK DebugNotification(EXCEPTION_POINTERS* error) {
    if(error && quietDebugOutput &&
       (error->ExceptionRecord->ExceptionCode==0x40010006 || error->ExceptionRecord->ExceptionCode==0x4001000a))
        return EXCEPTION_CONTINUE_EXECUTION;
    return EXCEPTION_CONTINUE_SEARCH;
}
static DWORD WINAPI Initialize(void*) {
    Log("LanDirect NativeBridge 0.1.2; in-place listen with duplicate local identity rejection.");
    if(!SupportedBuild()) { Log("Unsupported executable hash; hook not installed."); return 0; }
    imageBase=reinterpret_cast<uintptr_t>(GetModuleHandleW(nullptr));
    quietDebugOutput=wcsstr(GetCommandLineW(),L"-LanDirectQuietDebug")!=nullptr;
    if(quietDebugOutput) Log("Local-test debug-print notifications suppressed; native file logging remains enabled.");
    const unsigned char expected[]={0x48,0x89,0x5c,0x24,0x08,0x48,0x89,0x6c,0x24,0x10,0x48,0x89,0x74,0x24,0x18,0x57};
    unsigned char bytes[sizeof(expected)]; SIZE_T received;
    if(!ReadProcessMemory(GetCurrentProcess(),reinterpret_cast<void*>(imageBase+0x3d517a0),bytes,sizeof(bytes),&received) || received!=sizeof(bytes) || memcmp(bytes,expected,sizeof(bytes))!=0) {
        Log("EnableListenServer signature differs; bridge inactive.");return 0;
    }
    if(quietDebugOutput && !AddVectoredExceptionHandler(1,DebugNotification)) Log("Debug-print handler installation failed.");
    StartBridgeTimer();
    return 0;

}
BOOL WINAPI DllMain(HINSTANCE instance,DWORD reason,LPVOID) {
    if(reason==DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(instance);
        if(!InitializeDwmForwarding()) return FALSE;
        GetModuleFileNameW(instance,logPath,MAX_PATH);
        wchar_t* slash=wcsrchr(logPath,L'\\'); if(!slash) return FALSE;
        wcscpy(slash+1,L"LanDirect-native.log");
        HANDLE worker=CreateThread(nullptr,0,Initialize,nullptr,0,nullptr);
        if(worker) CloseHandle(worker);
    }
    return TRUE;
}
