#include "WDPlayerController.h"
#include "Tests/WDGameplayProbe.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "Engine/World.h"

void AWDPlayerController::BeginPlay()
{
    Super::BeginPlay();
#if !UE_BUILD_SHIPPING
    if (IsLocalController() && GetNetMode()==NM_Client && FParse::Param(FCommandLine::Get(),TEXT("WDNetworkClient")))
        GetWorld()->SpawnActor<AWDGameplayProbe>();
#endif
}
AWDPlayerController::AWDPlayerController()
{
    bEnableTouchEvents = true;
    bEnableClickEvents = true;
    bShowMouseCursor = false;
}
