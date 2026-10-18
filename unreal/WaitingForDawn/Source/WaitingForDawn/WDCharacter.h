#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "WDCharacter.generated.h"
class UCameraComponent;
class USpotLightComponent;
class AWDInteractable;
class UAudioComponent;

UCLASS()
class WAITINGFORDAWN_API AWDCharacter : public ACharacter
{
    GENERATED_BODY()
public:
    int32 FallRecoveryCount = 0;
    AWDCharacter();
    virtual void Tick(float DeltaSeconds) override;
    virtual void EndPlay(const EEndPlayReason::Type Reason) override;
    virtual void SetupPlayerInputComponent(UInputComponent* Input) override;
    virtual void OnStartCrouch(float HalfHeightAdjust, float ScaledHalfHeightAdjust) override;
    virtual void OnEndCrouch(float HalfHeightAdjust, float ScaledHalfHeightAdjust) override;
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& Out) const override;
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly) TObjectPtr<UCameraComponent> Camera;
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly) TObjectPtr<USpotLightComponent> Flashlight;
    UPROPERTY(BlueprintReadOnly, Replicated) float Stamina = 100.f;
    UPROPERTY(BlueprintReadOnly, Replicated) bool bCaught = false;
    UPROPERTY(BlueprintReadOnly, Replicated) bool bLightOn = false;
    UPROPERTY(BlueprintReadOnly, Replicated) bool bSprinting = false;
    UPROPERTY(BlueprintReadOnly, ReplicatedUsing=OnRep_Hiding) TObjectPtr<AWDInteractable> HidingSpot;
    UPROPERTY(BlueprintReadOnly, ReplicatedUsing=OnRep_Riding) TObjectPtr<AWDInteractable> RidingCar;
    UPROPERTY(BlueprintReadOnly, ReplicatedUsing=OnRep_Riding) int32 CarSeat = INDEX_NONE;
    UPROPERTY(VisibleAnywhere) TObjectPtr<UAudioComponent> Breath;
    UPROPERTY(BlueprintReadOnly, Replicated) int32 Bottles = 3;
    bool bJournalOpen = false;
    void EnterHiding(AWDInteractable* Spot);
    void LeaveHiding();
    void SetSprint(bool Value) { ServerSprint(Value); }
    UFUNCTION(Client, Reliable) void ShowLetter();
    UFUNCTION(Server, Reliable) void ThrowBottle();
    UFUNCTION() void OnRep_Hiding();
    UFUNCTION() void OnRep_Riding();
    UFUNCTION(Server, Reliable) void LeaveCar();
    bool CanAct() const;
    bool CanMove() const;
    UFUNCTION(BlueprintCallable) void Use();
    UFUNCTION(BlueprintCallable) void ToggleLight();
    UFUNCTION(BlueprintCallable) void ToggleCrouch();
    AWDInteractable* FindInteractionTarget() const;
    void Catch();
protected:
    virtual void BeginPlay() override;
private:
    void Forward(float Value);
    void Right(float Value);
    void TurnRate(float Value);
    void LookRate(float Value);
    void SprintOn();
    void SprintOff();
    UFUNCTION(Server, Reliable) void ServerUse(FRotator ViewRotation);
    UFUNCTION(Server, Reliable) void ServerToggleLight();
    UFUNCTION(Server, Reliable) void ServerSprint(bool bEnabled);
    FVector LastSafePosition;
    double NextUse = 0;
    double NextThrow = 0;
    double NextBump = 0;
    float DistanceWalked = 0;
    FVector PreviousPosition;
    TWeakObjectPtr<AWDInteractable> RidingTickDependency;
    UPROPERTY() TObjectPtr<USoundBase> CreakSound;
    UPROPERTY() TObjectPtr<USoundBase> GlassSound;
    UPROPERTY() TObjectPtr<USoundBase> StingerSound;
    UPROPERTY() TObjectPtr<class UAnimSequence> IdleAnimation;
    UPROPERTY() TObjectPtr<class UAnimSequence> WalkAnimation;
    UPROPERTY() TObjectPtr<class UAnimSequence> RunAnimation;
    UPROPERTY() TObjectPtr<class UAnimSequence> DeathAnimation;
    UPROPERTY() TObjectPtr<class UAnimSequence> ActiveAnimation;
    UFUNCTION(NetMulticast, Unreliable) void PlayCue(USoundBase* Sound, FVector Location);
};
