#pragma once
#include "CoreMinimal.h"
#include "GameFramework/GameStateBase.h"
#include "WDGameState.generated.h"

UENUM(BlueprintType)
enum class EWDDifficulty : uint8 { Easy, Normal, Hard, Extreme };

UCLASS()
class WAITINGFORDAWN_API AWDGameState : public AGameStateBase
{
    GENERATED_BODY()
public:
    AWDGameState();
    virtual void Tick(float DeltaSeconds) override;
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& Out) const override;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Replicated) EWDDifficulty Difficulty = EWDDifficulty::Normal;
    UPROPERTY(BlueprintReadOnly, Replicated) float SecondsRemaining = 1920.f;
    UPROPERTY(BlueprintReadOnly, Replicated) bool bRoundEnded = false;
    UPROPERTY(BlueprintReadOnly, Replicated) TArray<FName> TeamKeys;
    UPROPERTY(BlueprintReadOnly, Replicated) FString LastDiscovery;
    static float ReactionDelay(EWDDifficulty Level);
    static float RoundDuration(EWDDifficulty Level);
    bool AddKey(FName Key, const FString& Finder);
    void EmitNoise(FVector Location, float Radius, FName Source);
protected:
    virtual void BeginPlay() override;
};
