#pragma once
#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "WDHUD.generated.h"
UCLASS()
class WAITINGFORDAWN_API AWDHUD : public AHUD
{
    GENERATED_BODY()
public:
    virtual void DrawHUD() override;
    virtual void NotifyHitBoxClick(FName BoxName) override;
};
