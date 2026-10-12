#define WIN32_LEAN_AND_MEAN
#include <windows.h>
extern "C" { FARPROC forward_DllCanUnloadNow; }
extern "C" __attribute__((naked)) void DllCanUnloadNow() { __asm__("jmp *forward_DllCanUnloadNow(%rip)"); }
extern "C" { FARPROC forward_DllGetClassObject; }
extern "C" __attribute__((naked)) void DllGetClassObject() { __asm__("jmp *forward_DllGetClassObject(%rip)"); }
extern "C" { FARPROC forward_DwmAttachMilContent; }
extern "C" __attribute__((naked)) void DwmAttachMilContent() { __asm__("jmp *forward_DwmAttachMilContent(%rip)"); }
extern "C" { FARPROC forward_DwmDefWindowProc; }
extern "C" __attribute__((naked)) void DwmDefWindowProc() { __asm__("jmp *forward_DwmDefWindowProc(%rip)"); }
extern "C" { FARPROC forward_DwmDetachMilContent; }
extern "C" __attribute__((naked)) void DwmDetachMilContent() { __asm__("jmp *forward_DwmDetachMilContent(%rip)"); }
extern "C" { FARPROC forward_DwmEnableBlurBehindWindow; }
extern "C" __attribute__((naked)) void DwmEnableBlurBehindWindow() { __asm__("jmp *forward_DwmEnableBlurBehindWindow(%rip)"); }
extern "C" { FARPROC forward_DwmEnableComposition; }
extern "C" __attribute__((naked)) void DwmEnableComposition() { __asm__("jmp *forward_DwmEnableComposition(%rip)"); }
extern "C" { FARPROC forward_DwmEnableMMCSS; }
extern "C" __attribute__((naked)) void DwmEnableMMCSS() { __asm__("jmp *forward_DwmEnableMMCSS(%rip)"); }
extern "C" { FARPROC forward_DwmExtendFrameIntoClientArea; }
extern "C" __attribute__((naked)) void DwmExtendFrameIntoClientArea() { __asm__("jmp *forward_DwmExtendFrameIntoClientArea(%rip)"); }
extern "C" { FARPROC forward_DwmFlush; }
extern "C" __attribute__((naked)) void DwmFlush() { __asm__("jmp *forward_DwmFlush(%rip)"); }
extern "C" { FARPROC forward_DwmGetColorizationColor; }
extern "C" __attribute__((naked)) void DwmGetColorizationColor() { __asm__("jmp *forward_DwmGetColorizationColor(%rip)"); }
extern "C" { FARPROC forward_DwmGetCompositionTimingInfo; }
extern "C" __attribute__((naked)) void DwmGetCompositionTimingInfo() { __asm__("jmp *forward_DwmGetCompositionTimingInfo(%rip)"); }
extern "C" { FARPROC forward_DwmGetGraphicsStreamClient; }
extern "C" __attribute__((naked)) void DwmGetGraphicsStreamClient() { __asm__("jmp *forward_DwmGetGraphicsStreamClient(%rip)"); }
extern "C" { FARPROC forward_DwmGetGraphicsStreamTransformHint; }
extern "C" __attribute__((naked)) void DwmGetGraphicsStreamTransformHint() { __asm__("jmp *forward_DwmGetGraphicsStreamTransformHint(%rip)"); }
extern "C" { FARPROC forward_DwmGetTransportAttributes; }
extern "C" __attribute__((naked)) void DwmGetTransportAttributes() { __asm__("jmp *forward_DwmGetTransportAttributes(%rip)"); }
extern "C" { FARPROC forward_DwmGetUnmetTabRequirements; }
extern "C" __attribute__((naked)) void DwmGetUnmetTabRequirements() { __asm__("jmp *forward_DwmGetUnmetTabRequirements(%rip)"); }
extern "C" { FARPROC forward_DwmGetWindowAttribute; }
extern "C" __attribute__((naked)) void DwmGetWindowAttribute() { __asm__("jmp *forward_DwmGetWindowAttribute(%rip)"); }
extern "C" { FARPROC forward_DwmInvalidateIconicBitmaps; }
extern "C" __attribute__((naked)) void DwmInvalidateIconicBitmaps() { __asm__("jmp *forward_DwmInvalidateIconicBitmaps(%rip)"); }
extern "C" { FARPROC forward_DwmIsCompositionEnabled; }
extern "C" __attribute__((naked)) void DwmIsCompositionEnabled() { __asm__("jmp *forward_DwmIsCompositionEnabled(%rip)"); }
extern "C" { FARPROC forward_DwmModifyPreviousDxFrameDuration; }
extern "C" __attribute__((naked)) void DwmModifyPreviousDxFrameDuration() { __asm__("jmp *forward_DwmModifyPreviousDxFrameDuration(%rip)"); }
extern "C" { FARPROC forward_DwmQueryThumbnailSourceSize; }
extern "C" __attribute__((naked)) void DwmQueryThumbnailSourceSize() { __asm__("jmp *forward_DwmQueryThumbnailSourceSize(%rip)"); }
extern "C" { FARPROC forward_DwmRegisterThumbnail; }
extern "C" __attribute__((naked)) void DwmRegisterThumbnail() { __asm__("jmp *forward_DwmRegisterThumbnail(%rip)"); }
extern "C" { FARPROC forward_DwmRenderGesture; }
extern "C" __attribute__((naked)) void DwmRenderGesture() { __asm__("jmp *forward_DwmRenderGesture(%rip)"); }
extern "C" { FARPROC forward_DwmSetDxFrameDuration; }
extern "C" __attribute__((naked)) void DwmSetDxFrameDuration() { __asm__("jmp *forward_DwmSetDxFrameDuration(%rip)"); }
extern "C" { FARPROC forward_DwmSetIconicLivePreviewBitmap; }
extern "C" __attribute__((naked)) void DwmSetIconicLivePreviewBitmap() { __asm__("jmp *forward_DwmSetIconicLivePreviewBitmap(%rip)"); }
extern "C" { FARPROC forward_DwmSetIconicThumbnail; }
extern "C" __attribute__((naked)) void DwmSetIconicThumbnail() { __asm__("jmp *forward_DwmSetIconicThumbnail(%rip)"); }
extern "C" { FARPROC forward_DwmSetPresentParameters; }
extern "C" __attribute__((naked)) void DwmSetPresentParameters() { __asm__("jmp *forward_DwmSetPresentParameters(%rip)"); }
extern "C" { FARPROC forward_DwmSetWindowAttribute; }
extern "C" __attribute__((naked)) void DwmSetWindowAttribute() { __asm__("jmp *forward_DwmSetWindowAttribute(%rip)"); }
extern "C" { FARPROC forward_DwmShowContact; }
extern "C" __attribute__((naked)) void DwmShowContact() { __asm__("jmp *forward_DwmShowContact(%rip)"); }
extern "C" { FARPROC forward_DwmTetherContact; }
extern "C" __attribute__((naked)) void DwmTetherContact() { __asm__("jmp *forward_DwmTetherContact(%rip)"); }
extern "C" { FARPROC forward_DwmTetherTextContact; }
extern "C" __attribute__((naked)) void DwmTetherTextContact() { __asm__("jmp *forward_DwmTetherTextContact(%rip)"); }
extern "C" { FARPROC forward_DwmTransitionOwnedWindow; }
extern "C" __attribute__((naked)) void DwmTransitionOwnedWindow() { __asm__("jmp *forward_DwmTransitionOwnedWindow(%rip)"); }
extern "C" { FARPROC forward_DwmUnregisterThumbnail; }
extern "C" __attribute__((naked)) void DwmUnregisterThumbnail() { __asm__("jmp *forward_DwmUnregisterThumbnail(%rip)"); }
extern "C" { FARPROC forward_DwmUpdateThumbnailProperties; }
extern "C" __attribute__((naked)) void DwmUpdateThumbnailProperties() { __asm__("jmp *forward_DwmUpdateThumbnailProperties(%rip)"); }
extern "C" { FARPROC forward_DwmpAllocateSecurityDescriptor; }
extern "C" __attribute__((naked)) void DwmpAllocateSecurityDescriptor() { __asm__("jmp *forward_DwmpAllocateSecurityDescriptor(%rip)"); }
extern "C" { FARPROC forward_DwmpDxGetWindowSharedSurface; }
extern "C" __attribute__((naked)) void DwmpDxGetWindowSharedSurface() { __asm__("jmp *forward_DwmpDxGetWindowSharedSurface(%rip)"); }
extern "C" { FARPROC forward_DwmpDxUpdateWindowSharedSurface; }
extern "C" __attribute__((naked)) void DwmpDxUpdateWindowSharedSurface() { __asm__("jmp *forward_DwmpDxUpdateWindowSharedSurface(%rip)"); }
extern "C" { FARPROC forward_DwmpDxgiIsThreadDesktopComposited; }
extern "C" __attribute__((naked)) void DwmpDxgiIsThreadDesktopComposited() { __asm__("jmp *forward_DwmpDxgiIsThreadDesktopComposited(%rip)"); }
extern "C" { FARPROC forward_DwmpEnableDDASupport; }
extern "C" __attribute__((naked)) void DwmpEnableDDASupport() { __asm__("jmp *forward_DwmpEnableDDASupport(%rip)"); }
extern "C" { FARPROC forward_DwmpFreeSecurityDescriptor; }
extern "C" __attribute__((naked)) void DwmpFreeSecurityDescriptor() { __asm__("jmp *forward_DwmpFreeSecurityDescriptor(%rip)"); }
extern "C" { FARPROC forward_DwmpGetColorizationParameters; }
extern "C" __attribute__((naked)) void DwmpGetColorizationParameters() { __asm__("jmp *forward_DwmpGetColorizationParameters(%rip)"); }
extern "C" { FARPROC forward_DwmpRenderFlick; }
extern "C" __attribute__((naked)) void DwmpRenderFlick() { __asm__("jmp *forward_DwmpRenderFlick(%rip)"); }
extern "C" { FARPROC forward_DwmpSetColorizationParameters; }
extern "C" __attribute__((naked)) void DwmpSetColorizationParameters() { __asm__("jmp *forward_DwmpSetColorizationParameters(%rip)"); }
extern "C" { FARPROC forward_DwmpUpdateProxyWindowForCapture; }
extern "C" __attribute__((naked)) void DwmpUpdateProxyWindowForCapture() { __asm__("jmp *forward_DwmpUpdateProxyWindowForCapture(%rip)"); }
extern "C" { FARPROC forward_Ordinal103; }
extern "C" __attribute__((naked)) void Ordinal103() { __asm__("jmp *forward_Ordinal103(%rip)"); }
extern "C" { FARPROC forward_Ordinal104; }
extern "C" __attribute__((naked)) void Ordinal104() { __asm__("jmp *forward_Ordinal104(%rip)"); }
extern "C" { FARPROC forward_Ordinal105; }
extern "C" __attribute__((naked)) void Ordinal105() { __asm__("jmp *forward_Ordinal105(%rip)"); }
extern "C" { FARPROC forward_Ordinal106; }
extern "C" __attribute__((naked)) void Ordinal106() { __asm__("jmp *forward_Ordinal106(%rip)"); }
extern "C" { FARPROC forward_Ordinal107; }
extern "C" __attribute__((naked)) void Ordinal107() { __asm__("jmp *forward_Ordinal107(%rip)"); }
extern "C" { FARPROC forward_Ordinal108; }
extern "C" __attribute__((naked)) void Ordinal108() { __asm__("jmp *forward_Ordinal108(%rip)"); }
extern "C" { FARPROC forward_Ordinal109; }
extern "C" __attribute__((naked)) void Ordinal109() { __asm__("jmp *forward_Ordinal109(%rip)"); }
extern "C" { FARPROC forward_Ordinal110; }
extern "C" __attribute__((naked)) void Ordinal110() { __asm__("jmp *forward_Ordinal110(%rip)"); }
extern "C" { FARPROC forward_Ordinal112; }
extern "C" __attribute__((naked)) void Ordinal112() { __asm__("jmp *forward_Ordinal112(%rip)"); }
extern "C" { FARPROC forward_Ordinal113; }
extern "C" __attribute__((naked)) void Ordinal113() { __asm__("jmp *forward_Ordinal113(%rip)"); }
extern "C" { FARPROC forward_Ordinal114; }
extern "C" __attribute__((naked)) void Ordinal114() { __asm__("jmp *forward_Ordinal114(%rip)"); }
extern "C" { FARPROC forward_Ordinal124; }
extern "C" __attribute__((naked)) void Ordinal124() { __asm__("jmp *forward_Ordinal124(%rip)"); }
extern "C" { FARPROC forward_Ordinal132; }
extern "C" __attribute__((naked)) void Ordinal132() { __asm__("jmp *forward_Ordinal132(%rip)"); }
extern "C" { FARPROC forward_Ordinal138; }
extern "C" __attribute__((naked)) void Ordinal138() { __asm__("jmp *forward_Ordinal138(%rip)"); }
extern "C" { FARPROC forward_Ordinal139; }
extern "C" __attribute__((naked)) void Ordinal139() { __asm__("jmp *forward_Ordinal139(%rip)"); }
extern "C" { FARPROC forward_Ordinal140; }
extern "C" __attribute__((naked)) void Ordinal140() { __asm__("jmp *forward_Ordinal140(%rip)"); }
extern "C" { FARPROC forward_Ordinal141; }
extern "C" __attribute__((naked)) void Ordinal141() { __asm__("jmp *forward_Ordinal141(%rip)"); }
extern "C" { FARPROC forward_Ordinal142; }
extern "C" __attribute__((naked)) void Ordinal142() { __asm__("jmp *forward_Ordinal142(%rip)"); }
extern "C" { FARPROC forward_Ordinal144; }
extern "C" __attribute__((naked)) void Ordinal144() { __asm__("jmp *forward_Ordinal144(%rip)"); }
extern "C" { FARPROC forward_Ordinal145; }
extern "C" __attribute__((naked)) void Ordinal145() { __asm__("jmp *forward_Ordinal145(%rip)"); }
extern "C" { FARPROC forward_Ordinal147; }
extern "C" __attribute__((naked)) void Ordinal147() { __asm__("jmp *forward_Ordinal147(%rip)"); }
extern "C" { FARPROC forward_Ordinal148; }
extern "C" __attribute__((naked)) void Ordinal148() { __asm__("jmp *forward_Ordinal148(%rip)"); }
extern "C" { FARPROC forward_Ordinal150; }
extern "C" __attribute__((naked)) void Ordinal150() { __asm__("jmp *forward_Ordinal150(%rip)"); }
extern "C" { FARPROC forward_Ordinal151; }
extern "C" __attribute__((naked)) void Ordinal151() { __asm__("jmp *forward_Ordinal151(%rip)"); }
extern "C" { FARPROC forward_Ordinal152; }
extern "C" __attribute__((naked)) void Ordinal152() { __asm__("jmp *forward_Ordinal152(%rip)"); }
extern "C" { FARPROC forward_Ordinal153; }
extern "C" __attribute__((naked)) void Ordinal153() { __asm__("jmp *forward_Ordinal153(%rip)"); }
extern "C" { FARPROC forward_Ordinal154; }
extern "C" __attribute__((naked)) void Ordinal154() { __asm__("jmp *forward_Ordinal154(%rip)"); }
extern "C" { FARPROC forward_Ordinal155; }
extern "C" __attribute__((naked)) void Ordinal155() { __asm__("jmp *forward_Ordinal155(%rip)"); }
extern "C" { FARPROC forward_Ordinal157; }
extern "C" __attribute__((naked)) void Ordinal157() { __asm__("jmp *forward_Ordinal157(%rip)"); }
extern "C" { FARPROC forward_Ordinal158; }
extern "C" __attribute__((naked)) void Ordinal158() { __asm__("jmp *forward_Ordinal158(%rip)"); }
extern "C" { FARPROC forward_Ordinal159; }
extern "C" __attribute__((naked)) void Ordinal159() { __asm__("jmp *forward_Ordinal159(%rip)"); }
extern "C" { FARPROC forward_Ordinal160; }
extern "C" __attribute__((naked)) void Ordinal160() { __asm__("jmp *forward_Ordinal160(%rip)"); }
extern "C" { FARPROC forward_Ordinal161; }
extern "C" __attribute__((naked)) void Ordinal161() { __asm__("jmp *forward_Ordinal161(%rip)"); }
extern "C" { FARPROC forward_Ordinal162; }
extern "C" __attribute__((naked)) void Ordinal162() { __asm__("jmp *forward_Ordinal162(%rip)"); }
extern "C" { FARPROC forward_Ordinal163; }
extern "C" __attribute__((naked)) void Ordinal163() { __asm__("jmp *forward_Ordinal163(%rip)"); }
extern "C" { FARPROC forward_Ordinal164; }
extern "C" __attribute__((naked)) void Ordinal164() { __asm__("jmp *forward_Ordinal164(%rip)"); }
extern "C" { FARPROC forward_Ordinal165; }
extern "C" __attribute__((naked)) void Ordinal165() { __asm__("jmp *forward_Ordinal165(%rip)"); }
extern "C" { FARPROC forward_Ordinal166; }
extern "C" __attribute__((naked)) void Ordinal166() { __asm__("jmp *forward_Ordinal166(%rip)"); }
extern "C" { FARPROC forward_Ordinal167; }
extern "C" __attribute__((naked)) void Ordinal167() { __asm__("jmp *forward_Ordinal167(%rip)"); }
extern "C" { FARPROC forward_Ordinal168; }
extern "C" __attribute__((naked)) void Ordinal168() { __asm__("jmp *forward_Ordinal168(%rip)"); }
extern "C" { FARPROC forward_Ordinal169; }
extern "C" __attribute__((naked)) void Ordinal169() { __asm__("jmp *forward_Ordinal169(%rip)"); }
extern "C" { FARPROC forward_Ordinal170; }
extern "C" __attribute__((naked)) void Ordinal170() { __asm__("jmp *forward_Ordinal170(%rip)"); }
extern "C" { FARPROC forward_Ordinal171; }
extern "C" __attribute__((naked)) void Ordinal171() { __asm__("jmp *forward_Ordinal171(%rip)"); }
extern "C" { FARPROC forward_Ordinal172; }
extern "C" __attribute__((naked)) void Ordinal172() { __asm__("jmp *forward_Ordinal172(%rip)"); }
extern "C" { FARPROC forward_Ordinal173; }
extern "C" __attribute__((naked)) void Ordinal173() { __asm__("jmp *forward_Ordinal173(%rip)"); }
extern "C" { FARPROC forward_Ordinal174; }
extern "C" __attribute__((naked)) void Ordinal174() { __asm__("jmp *forward_Ordinal174(%rip)"); }
extern "C" { FARPROC forward_Ordinal175; }
extern "C" __attribute__((naked)) void Ordinal175() { __asm__("jmp *forward_Ordinal175(%rip)"); }
extern "C" { FARPROC forward_Ordinal176; }
extern "C" __attribute__((naked)) void Ordinal176() { __asm__("jmp *forward_Ordinal176(%rip)"); }
extern "C" { FARPROC forward_Ordinal177; }
extern "C" __attribute__((naked)) void Ordinal177() { __asm__("jmp *forward_Ordinal177(%rip)"); }
extern "C" { FARPROC forward_Ordinal178; }
extern "C" __attribute__((naked)) void Ordinal178() { __asm__("jmp *forward_Ordinal178(%rip)"); }
extern "C" { FARPROC forward_Ordinal179; }
extern "C" __attribute__((naked)) void Ordinal179() { __asm__("jmp *forward_Ordinal179(%rip)"); }
extern "C" { FARPROC forward_Ordinal180; }
extern "C" __attribute__((naked)) void Ordinal180() { __asm__("jmp *forward_Ordinal180(%rip)"); }
extern "C" { FARPROC forward_Ordinal181; }
extern "C" __attribute__((naked)) void Ordinal181() { __asm__("jmp *forward_Ordinal181(%rip)"); }
extern "C" { FARPROC forward_Ordinal182; }
extern "C" __attribute__((naked)) void Ordinal182() { __asm__("jmp *forward_Ordinal182(%rip)"); }
extern "C" { FARPROC forward_Ordinal184; }
extern "C" __attribute__((naked)) void Ordinal184() { __asm__("jmp *forward_Ordinal184(%rip)"); }
extern "C" { FARPROC forward_Ordinal185; }
extern "C" __attribute__((naked)) void Ordinal185() { __asm__("jmp *forward_Ordinal185(%rip)"); }
extern "C" { FARPROC forward_Ordinal186; }
extern "C" __attribute__((naked)) void Ordinal186() { __asm__("jmp *forward_Ordinal186(%rip)"); }
extern "C" { FARPROC forward_Ordinal187; }
extern "C" __attribute__((naked)) void Ordinal187() { __asm__("jmp *forward_Ordinal187(%rip)"); }
extern "C" { FARPROC forward_Ordinal188; }
extern "C" __attribute__((naked)) void Ordinal188() { __asm__("jmp *forward_Ordinal188(%rip)"); }
extern "C" { FARPROC forward_Ordinal189; }
extern "C" __attribute__((naked)) void Ordinal189() { __asm__("jmp *forward_Ordinal189(%rip)"); }
extern "C" { FARPROC forward_Ordinal190; }
extern "C" __attribute__((naked)) void Ordinal190() { __asm__("jmp *forward_Ordinal190(%rip)"); }
extern "C" { FARPROC forward_Ordinal191; }
extern "C" __attribute__((naked)) void Ordinal191() { __asm__("jmp *forward_Ordinal191(%rip)"); }
extern "C" { FARPROC forward_Ordinal192; }
extern "C" __attribute__((naked)) void Ordinal192() { __asm__("jmp *forward_Ordinal192(%rip)"); }
extern "C" { FARPROC forward_Ordinal193; }
extern "C" __attribute__((naked)) void Ordinal193() { __asm__("jmp *forward_Ordinal193(%rip)"); }
extern "C" { FARPROC forward_Ordinal194; }
extern "C" __attribute__((naked)) void Ordinal194() { __asm__("jmp *forward_Ordinal194(%rip)"); }
extern "C" { FARPROC forward_Ordinal195; }
extern "C" __attribute__((naked)) void Ordinal195() { __asm__("jmp *forward_Ordinal195(%rip)"); }
extern "C" { FARPROC forward_Ordinal196; }
extern "C" __attribute__((naked)) void Ordinal196() { __asm__("jmp *forward_Ordinal196(%rip)"); }
extern "C" { FARPROC forward_Ordinal197; }
extern "C" __attribute__((naked)) void Ordinal197() { __asm__("jmp *forward_Ordinal197(%rip)"); }
extern "C" { FARPROC forward_Ordinal198; }
extern "C" __attribute__((naked)) void Ordinal198() { __asm__("jmp *forward_Ordinal198(%rip)"); }
extern "C" { FARPROC forward_Ordinal199; }
extern "C" __attribute__((naked)) void Ordinal199() { __asm__("jmp *forward_Ordinal199(%rip)"); }
extern "C" { FARPROC forward_Ordinal200; }
extern "C" __attribute__((naked)) void Ordinal200() { __asm__("jmp *forward_Ordinal200(%rip)"); }
extern "C" { FARPROC forward_Ordinal201; }
extern "C" __attribute__((naked)) void Ordinal201() { __asm__("jmp *forward_Ordinal201(%rip)"); }
extern "C" { FARPROC forward_Ordinal202; }
extern "C" __attribute__((naked)) void Ordinal202() { __asm__("jmp *forward_Ordinal202(%rip)"); }
extern "C" { FARPROC forward_Ordinal203; }
extern "C" __attribute__((naked)) void Ordinal203() { __asm__("jmp *forward_Ordinal203(%rip)"); }
extern "C" { FARPROC forward_Ordinal204; }
extern "C" __attribute__((naked)) void Ordinal204() { __asm__("jmp *forward_Ordinal204(%rip)"); }
bool InitializeDwmForwarding() {
wchar_t path[MAX_PATH];
UINT length=GetSystemDirectoryW(path,MAX_PATH);
if(!length || length+12>=MAX_PATH) return false;
wcscat(path,L"\\dwmapi.dll");
HMODULE system=LoadLibraryW(path);
if(!system) return false;
forward_DllCanUnloadNow=GetProcAddress(system,"DllCanUnloadNow"); if(!forward_DllCanUnloadNow) return false;
forward_DllGetClassObject=GetProcAddress(system,"DllGetClassObject"); if(!forward_DllGetClassObject) return false;
forward_DwmAttachMilContent=GetProcAddress(system,"DwmAttachMilContent"); if(!forward_DwmAttachMilContent) return false;
forward_DwmDefWindowProc=GetProcAddress(system,"DwmDefWindowProc"); if(!forward_DwmDefWindowProc) return false;
forward_DwmDetachMilContent=GetProcAddress(system,"DwmDetachMilContent"); if(!forward_DwmDetachMilContent) return false;
forward_DwmEnableBlurBehindWindow=GetProcAddress(system,"DwmEnableBlurBehindWindow"); if(!forward_DwmEnableBlurBehindWindow) return false;
forward_DwmEnableComposition=GetProcAddress(system,"DwmEnableComposition"); if(!forward_DwmEnableComposition) return false;
forward_DwmEnableMMCSS=GetProcAddress(system,"DwmEnableMMCSS"); if(!forward_DwmEnableMMCSS) return false;
forward_DwmExtendFrameIntoClientArea=GetProcAddress(system,"DwmExtendFrameIntoClientArea"); if(!forward_DwmExtendFrameIntoClientArea) return false;
forward_DwmFlush=GetProcAddress(system,"DwmFlush"); if(!forward_DwmFlush) return false;
forward_DwmGetColorizationColor=GetProcAddress(system,"DwmGetColorizationColor"); if(!forward_DwmGetColorizationColor) return false;
forward_DwmGetCompositionTimingInfo=GetProcAddress(system,"DwmGetCompositionTimingInfo"); if(!forward_DwmGetCompositionTimingInfo) return false;
forward_DwmGetGraphicsStreamClient=GetProcAddress(system,"DwmGetGraphicsStreamClient"); if(!forward_DwmGetGraphicsStreamClient) return false;
forward_DwmGetGraphicsStreamTransformHint=GetProcAddress(system,"DwmGetGraphicsStreamTransformHint"); if(!forward_DwmGetGraphicsStreamTransformHint) return false;
forward_DwmGetTransportAttributes=GetProcAddress(system,"DwmGetTransportAttributes"); if(!forward_DwmGetTransportAttributes) return false;
forward_DwmGetUnmetTabRequirements=GetProcAddress(system,"DwmGetUnmetTabRequirements"); if(!forward_DwmGetUnmetTabRequirements) return false;
forward_DwmGetWindowAttribute=GetProcAddress(system,"DwmGetWindowAttribute"); if(!forward_DwmGetWindowAttribute) return false;
forward_DwmInvalidateIconicBitmaps=GetProcAddress(system,"DwmInvalidateIconicBitmaps"); if(!forward_DwmInvalidateIconicBitmaps) return false;
forward_DwmIsCompositionEnabled=GetProcAddress(system,"DwmIsCompositionEnabled"); if(!forward_DwmIsCompositionEnabled) return false;
forward_DwmModifyPreviousDxFrameDuration=GetProcAddress(system,"DwmModifyPreviousDxFrameDuration"); if(!forward_DwmModifyPreviousDxFrameDuration) return false;
forward_DwmQueryThumbnailSourceSize=GetProcAddress(system,"DwmQueryThumbnailSourceSize"); if(!forward_DwmQueryThumbnailSourceSize) return false;
forward_DwmRegisterThumbnail=GetProcAddress(system,"DwmRegisterThumbnail"); if(!forward_DwmRegisterThumbnail) return false;
forward_DwmRenderGesture=GetProcAddress(system,"DwmRenderGesture"); if(!forward_DwmRenderGesture) return false;
forward_DwmSetDxFrameDuration=GetProcAddress(system,"DwmSetDxFrameDuration"); if(!forward_DwmSetDxFrameDuration) return false;
forward_DwmSetIconicLivePreviewBitmap=GetProcAddress(system,"DwmSetIconicLivePreviewBitmap"); if(!forward_DwmSetIconicLivePreviewBitmap) return false;
forward_DwmSetIconicThumbnail=GetProcAddress(system,"DwmSetIconicThumbnail"); if(!forward_DwmSetIconicThumbnail) return false;
forward_DwmSetPresentParameters=GetProcAddress(system,"DwmSetPresentParameters"); if(!forward_DwmSetPresentParameters) return false;
forward_DwmSetWindowAttribute=GetProcAddress(system,"DwmSetWindowAttribute"); if(!forward_DwmSetWindowAttribute) return false;
forward_DwmShowContact=GetProcAddress(system,"DwmShowContact"); if(!forward_DwmShowContact) return false;
forward_DwmTetherContact=GetProcAddress(system,"DwmTetherContact"); if(!forward_DwmTetherContact) return false;
forward_DwmTetherTextContact=GetProcAddress(system,"DwmTetherTextContact"); if(!forward_DwmTetherTextContact) return false;
forward_DwmTransitionOwnedWindow=GetProcAddress(system,"DwmTransitionOwnedWindow"); if(!forward_DwmTransitionOwnedWindow) return false;
forward_DwmUnregisterThumbnail=GetProcAddress(system,"DwmUnregisterThumbnail"); if(!forward_DwmUnregisterThumbnail) return false;
forward_DwmUpdateThumbnailProperties=GetProcAddress(system,"DwmUpdateThumbnailProperties"); if(!forward_DwmUpdateThumbnailProperties) return false;
forward_DwmpAllocateSecurityDescriptor=GetProcAddress(system,"DwmpAllocateSecurityDescriptor"); if(!forward_DwmpAllocateSecurityDescriptor) return false;
forward_DwmpDxGetWindowSharedSurface=GetProcAddress(system,"DwmpDxGetWindowSharedSurface"); if(!forward_DwmpDxGetWindowSharedSurface) return false;
forward_DwmpDxUpdateWindowSharedSurface=GetProcAddress(system,"DwmpDxUpdateWindowSharedSurface"); if(!forward_DwmpDxUpdateWindowSharedSurface) return false;
forward_DwmpDxgiIsThreadDesktopComposited=GetProcAddress(system,"DwmpDxgiIsThreadDesktopComposited"); if(!forward_DwmpDxgiIsThreadDesktopComposited) return false;
forward_DwmpEnableDDASupport=GetProcAddress(system,"DwmpEnableDDASupport"); if(!forward_DwmpEnableDDASupport) return false;
forward_DwmpFreeSecurityDescriptor=GetProcAddress(system,"DwmpFreeSecurityDescriptor"); if(!forward_DwmpFreeSecurityDescriptor) return false;
forward_DwmpGetColorizationParameters=GetProcAddress(system,"DwmpGetColorizationParameters"); if(!forward_DwmpGetColorizationParameters) return false;
forward_DwmpRenderFlick=GetProcAddress(system,"DwmpRenderFlick"); if(!forward_DwmpRenderFlick) return false;
forward_DwmpSetColorizationParameters=GetProcAddress(system,"DwmpSetColorizationParameters"); if(!forward_DwmpSetColorizationParameters) return false;
forward_DwmpUpdateProxyWindowForCapture=GetProcAddress(system,"DwmpUpdateProxyWindowForCapture"); if(!forward_DwmpUpdateProxyWindowForCapture) return false;
forward_Ordinal103=GetProcAddress(system,MAKEINTRESOURCEA(103)); if(!forward_Ordinal103) return false;
forward_Ordinal104=GetProcAddress(system,MAKEINTRESOURCEA(104)); if(!forward_Ordinal104) return false;
forward_Ordinal105=GetProcAddress(system,MAKEINTRESOURCEA(105)); if(!forward_Ordinal105) return false;
forward_Ordinal106=GetProcAddress(system,MAKEINTRESOURCEA(106)); if(!forward_Ordinal106) return false;
forward_Ordinal107=GetProcAddress(system,MAKEINTRESOURCEA(107)); if(!forward_Ordinal107) return false;
forward_Ordinal108=GetProcAddress(system,MAKEINTRESOURCEA(108)); if(!forward_Ordinal108) return false;
forward_Ordinal109=GetProcAddress(system,MAKEINTRESOURCEA(109)); if(!forward_Ordinal109) return false;
forward_Ordinal110=GetProcAddress(system,MAKEINTRESOURCEA(110)); if(!forward_Ordinal110) return false;
forward_Ordinal112=GetProcAddress(system,MAKEINTRESOURCEA(112)); if(!forward_Ordinal112) return false;
forward_Ordinal113=GetProcAddress(system,MAKEINTRESOURCEA(113)); if(!forward_Ordinal113) return false;
forward_Ordinal114=GetProcAddress(system,MAKEINTRESOURCEA(114)); if(!forward_Ordinal114) return false;
forward_Ordinal124=GetProcAddress(system,MAKEINTRESOURCEA(124)); if(!forward_Ordinal124) return false;
forward_Ordinal132=GetProcAddress(system,MAKEINTRESOURCEA(132)); if(!forward_Ordinal132) return false;
forward_Ordinal138=GetProcAddress(system,MAKEINTRESOURCEA(138)); if(!forward_Ordinal138) return false;
forward_Ordinal139=GetProcAddress(system,MAKEINTRESOURCEA(139)); if(!forward_Ordinal139) return false;
forward_Ordinal140=GetProcAddress(system,MAKEINTRESOURCEA(140)); if(!forward_Ordinal140) return false;
forward_Ordinal141=GetProcAddress(system,MAKEINTRESOURCEA(141)); if(!forward_Ordinal141) return false;
forward_Ordinal142=GetProcAddress(system,MAKEINTRESOURCEA(142)); if(!forward_Ordinal142) return false;
forward_Ordinal144=GetProcAddress(system,MAKEINTRESOURCEA(144)); if(!forward_Ordinal144) return false;
forward_Ordinal145=GetProcAddress(system,MAKEINTRESOURCEA(145)); if(!forward_Ordinal145) return false;
forward_Ordinal147=GetProcAddress(system,MAKEINTRESOURCEA(147)); if(!forward_Ordinal147) return false;
forward_Ordinal148=GetProcAddress(system,MAKEINTRESOURCEA(148)); if(!forward_Ordinal148) return false;
forward_Ordinal150=GetProcAddress(system,MAKEINTRESOURCEA(150)); if(!forward_Ordinal150) return false;
forward_Ordinal151=GetProcAddress(system,MAKEINTRESOURCEA(151)); if(!forward_Ordinal151) return false;
forward_Ordinal152=GetProcAddress(system,MAKEINTRESOURCEA(152)); if(!forward_Ordinal152) return false;
forward_Ordinal153=GetProcAddress(system,MAKEINTRESOURCEA(153)); if(!forward_Ordinal153) return false;
forward_Ordinal154=GetProcAddress(system,MAKEINTRESOURCEA(154)); if(!forward_Ordinal154) return false;
forward_Ordinal155=GetProcAddress(system,MAKEINTRESOURCEA(155)); if(!forward_Ordinal155) return false;
forward_Ordinal157=GetProcAddress(system,MAKEINTRESOURCEA(157)); if(!forward_Ordinal157) return false;
forward_Ordinal158=GetProcAddress(system,MAKEINTRESOURCEA(158)); if(!forward_Ordinal158) return false;
forward_Ordinal159=GetProcAddress(system,MAKEINTRESOURCEA(159)); if(!forward_Ordinal159) return false;
forward_Ordinal160=GetProcAddress(system,MAKEINTRESOURCEA(160)); if(!forward_Ordinal160) return false;
forward_Ordinal161=GetProcAddress(system,MAKEINTRESOURCEA(161)); if(!forward_Ordinal161) return false;
forward_Ordinal162=GetProcAddress(system,MAKEINTRESOURCEA(162)); if(!forward_Ordinal162) return false;
forward_Ordinal163=GetProcAddress(system,MAKEINTRESOURCEA(163)); if(!forward_Ordinal163) return false;
forward_Ordinal164=GetProcAddress(system,MAKEINTRESOURCEA(164)); if(!forward_Ordinal164) return false;
forward_Ordinal165=GetProcAddress(system,MAKEINTRESOURCEA(165)); if(!forward_Ordinal165) return false;
forward_Ordinal166=GetProcAddress(system,MAKEINTRESOURCEA(166)); if(!forward_Ordinal166) return false;
forward_Ordinal167=GetProcAddress(system,MAKEINTRESOURCEA(167)); if(!forward_Ordinal167) return false;
forward_Ordinal168=GetProcAddress(system,MAKEINTRESOURCEA(168)); if(!forward_Ordinal168) return false;
forward_Ordinal169=GetProcAddress(system,MAKEINTRESOURCEA(169)); if(!forward_Ordinal169) return false;
forward_Ordinal170=GetProcAddress(system,MAKEINTRESOURCEA(170)); if(!forward_Ordinal170) return false;
forward_Ordinal171=GetProcAddress(system,MAKEINTRESOURCEA(171)); if(!forward_Ordinal171) return false;
forward_Ordinal172=GetProcAddress(system,MAKEINTRESOURCEA(172)); if(!forward_Ordinal172) return false;
forward_Ordinal173=GetProcAddress(system,MAKEINTRESOURCEA(173)); if(!forward_Ordinal173) return false;
forward_Ordinal174=GetProcAddress(system,MAKEINTRESOURCEA(174)); if(!forward_Ordinal174) return false;
forward_Ordinal175=GetProcAddress(system,MAKEINTRESOURCEA(175)); if(!forward_Ordinal175) return false;
forward_Ordinal176=GetProcAddress(system,MAKEINTRESOURCEA(176)); if(!forward_Ordinal176) return false;
forward_Ordinal177=GetProcAddress(system,MAKEINTRESOURCEA(177)); if(!forward_Ordinal177) return false;
forward_Ordinal178=GetProcAddress(system,MAKEINTRESOURCEA(178)); if(!forward_Ordinal178) return false;
forward_Ordinal179=GetProcAddress(system,MAKEINTRESOURCEA(179)); if(!forward_Ordinal179) return false;
forward_Ordinal180=GetProcAddress(system,MAKEINTRESOURCEA(180)); if(!forward_Ordinal180) return false;
forward_Ordinal181=GetProcAddress(system,MAKEINTRESOURCEA(181)); if(!forward_Ordinal181) return false;
forward_Ordinal182=GetProcAddress(system,MAKEINTRESOURCEA(182)); if(!forward_Ordinal182) return false;
forward_Ordinal184=GetProcAddress(system,MAKEINTRESOURCEA(184)); if(!forward_Ordinal184) return false;
forward_Ordinal185=GetProcAddress(system,MAKEINTRESOURCEA(185)); if(!forward_Ordinal185) return false;
forward_Ordinal186=GetProcAddress(system,MAKEINTRESOURCEA(186)); if(!forward_Ordinal186) return false;
forward_Ordinal187=GetProcAddress(system,MAKEINTRESOURCEA(187)); if(!forward_Ordinal187) return false;
forward_Ordinal188=GetProcAddress(system,MAKEINTRESOURCEA(188)); if(!forward_Ordinal188) return false;
forward_Ordinal189=GetProcAddress(system,MAKEINTRESOURCEA(189)); if(!forward_Ordinal189) return false;
forward_Ordinal190=GetProcAddress(system,MAKEINTRESOURCEA(190)); if(!forward_Ordinal190) return false;
forward_Ordinal191=GetProcAddress(system,MAKEINTRESOURCEA(191)); if(!forward_Ordinal191) return false;
forward_Ordinal192=GetProcAddress(system,MAKEINTRESOURCEA(192)); if(!forward_Ordinal192) return false;
forward_Ordinal193=GetProcAddress(system,MAKEINTRESOURCEA(193)); if(!forward_Ordinal193) return false;
forward_Ordinal194=GetProcAddress(system,MAKEINTRESOURCEA(194)); if(!forward_Ordinal194) return false;
forward_Ordinal195=GetProcAddress(system,MAKEINTRESOURCEA(195)); if(!forward_Ordinal195) return false;
forward_Ordinal196=GetProcAddress(system,MAKEINTRESOURCEA(196)); if(!forward_Ordinal196) return false;
forward_Ordinal197=GetProcAddress(system,MAKEINTRESOURCEA(197)); if(!forward_Ordinal197) return false;
forward_Ordinal198=GetProcAddress(system,MAKEINTRESOURCEA(198)); if(!forward_Ordinal198) return false;
forward_Ordinal199=GetProcAddress(system,MAKEINTRESOURCEA(199)); if(!forward_Ordinal199) return false;
forward_Ordinal200=GetProcAddress(system,MAKEINTRESOURCEA(200)); if(!forward_Ordinal200) return false;
forward_Ordinal201=GetProcAddress(system,MAKEINTRESOURCEA(201)); if(!forward_Ordinal201) return false;
forward_Ordinal202=GetProcAddress(system,MAKEINTRESOURCEA(202)); if(!forward_Ordinal202) return false;
forward_Ordinal203=GetProcAddress(system,MAKEINTRESOURCEA(203)); if(!forward_Ordinal203) return false;
forward_Ordinal204=GetProcAddress(system,MAKEINTRESOURCEA(204)); if(!forward_Ordinal204) return false;
return true;
}