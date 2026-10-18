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
    bool ClickAt(FVector2D Point);
private:
    struct FButton { FName Name; FVector2D Pos,Size; };
    TArray<FButton> Buttons;
    void Button(FName Name,const FString& Text,float X,float Y,float W,float H,bool Circle=false);
    void Ring(float X,float Y,float Radius,FLinearColor Color,float Thickness=2);
    void Icon(FName Name,float X,float Y,float S);
    UPROPERTY() TObjectPtr<class UTexture2D> TitleTexture;
    UPROPERTY() TObjectPtr<class UTexture2D> PaperTexture;
};
