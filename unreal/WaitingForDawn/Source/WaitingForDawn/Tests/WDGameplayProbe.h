#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "WDGameplayProbe.generated.h"

class AWDCharacter;
class AWDGhost;
class AWDInteractable;

// Opt-in development-only driver. Exercises real movement, collision and interaction code.
UCLASS(NotBlueprintable)
class AWDGameplayProbe : public AActor
{
    GENERATED_BODY()
public:
    AWDGameplayProbe();
    virtual void Tick(float DeltaSeconds) override;
private:
    void Finish(bool Success, const FString& Detail);
    bool AimAndUse(AWDInteractable* Target);
    void Stage(const FString& Name);
    void TickNetwork(bool Server);
    UPROPERTY() TObjectPtr<AWDCharacter> Player;
    UPROPERTY() TObjectPtr<AWDGhost> Ghost;
    UPROPERTY() TObjectPtr<AWDInteractable> Cupboard;
    UPROPERTY() TObjectPtr<AWDInteractable> Key;
    UPROPERTY() TObjectPtr<AWDInteractable> Door;
    TArray<FVector> Route;
    FString Phase = TEXT("Startup");
    double PhaseAt = 0;
    int32 Waypoint = 0;
    FVector GhostStart;
    float MaximumGhostTravel = 0;
    bool bFinished = false;
    int32 NetworkPlayers = 0;
};
