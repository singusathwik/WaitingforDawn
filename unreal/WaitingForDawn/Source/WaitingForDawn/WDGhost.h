#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "WDGhost.generated.h"
class AWDCharacter;
class USoundBase;
class UAnimSequence;
UENUM(BlueprintType)
enum class EWDGhostState : uint8 { Patrol, Listening, Investigating, Searching, Chasing };

UCLASS()
class WAITINGFORDAWN_API AWDGhost : public ACharacter
{
    GENERATED_BODY()
public:
    AWDGhost();
    virtual void Tick(float DeltaSeconds) override;
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& Out) const override;
    UPROPERTY(EditAnywhere) TArray<FVector> PatrolPoints;
    UPROPERTY(EditAnywhere) TObjectPtr<USoundBase> WarningSound;
    UPROPERTY(EditAnywhere) TObjectPtr<UAnimSequence> IdleAnimation;
    UPROPERTY(EditAnywhere) TObjectPtr<UAnimSequence> WalkAnimation;
    UPROPERTY(EditAnywhere) TObjectPtr<UAnimSequence> RunAnimation;
    UPROPERTY(BlueprintReadOnly, Replicated) EWDGhostState State = EWDGhostState::Patrol;
    UPROPERTY(BlueprintReadOnly, Replicated) FVector NoiseGoal;
    void HearNoise(FVector Location, float Delay);
    static double ReactionDeadline(EWDGhostState Current, double Existing, double Now, float Delay);
protected:
    virtual void BeginPlay() override;
    UFUNCTION(NetMulticast, Unreliable) void Warn();
private:
    double ReactAt = 0;
    double RememberUntil = 0;
    double NextRouteAt = 0;
    double SearchUntil = 0;
    double NextWarningAt = 0;
    int32 PatrolIndex = 0;
    TWeakObjectPtr<AWDCharacter> ChaseTarget;
    FVector LastSeen;
    double SeenAt = 0;
    UPROPERTY(Transient) TObjectPtr<UAnimSequence> ActiveAnimation;
};
