#pragma once
#include "CoreMinimal.h"
#include "GameFramework/GameStateBase.h"
#include "WDGameState.generated.h"

UENUM(BlueprintType)
enum class EWDDifficulty : uint8 { Easy, Normal, Hard, Extreme };
UENUM(BlueprintType)
enum class EWDRoundPhase : uint8 { Lobby, Introduction, Playing, Escaped, Lost };

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
    UPROPERTY(BlueprintReadOnly, Replicated) EWDRoundPhase Phase = EWDRoundPhase::Playing;
    UPROPERTY(BlueprintReadOnly, Replicated) float IntroRemaining = 36.f;
    UPROPERTY(BlueprintReadOnly, Replicated) bool bLetterFound = false;
    UPROPERTY(BlueprintReadOnly, Replicated) bool bGarageUnlocked = false;
    UPROPERTY(BlueprintReadOnly, Replicated) FString EndingReason;
    UPROPERTY(BlueprintReadOnly, Replicated) float DiscoveryAt = 0.f;
    UPROPERTY(BlueprintReadOnly, Replicated) float EndingAge = 0.f;
    void StartRound(EWDDifficulty Level, bool SkipStory);
    void EndRound(bool Escaped, const FString& Reason);
    bool HasKeys(const TArray<FName>& Keys) const;
    bool CanEscape() const;
    static float ReactionDelay(EWDDifficulty Level);
    static float RoundDuration(EWDDifficulty Level);
    bool AddKey(FName Key, const FString& Finder);
    void EmitNoise(FVector Location, float Radius, FName Source);
protected:
    virtual void BeginPlay() override;
};
