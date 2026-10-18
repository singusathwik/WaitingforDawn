#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "WDCharacter.generated.h"
class UCameraComponent;
class USpotLightComponent;
class AWDInteractable;

UCLASS()
class WAITINGFORDAWN_API AWDCharacter : public ACharacter
{
    GENERATED_BODY()
public:
    AWDCharacter();
    virtual void Tick(float DeltaSeconds) override;
    virtual void SetupPlayerInputComponent(UInputComponent* Input) override;
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& Out) const override;
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly) TObjectPtr<UCameraComponent> Camera;
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly) TObjectPtr<USpotLightComponent> Flashlight;
    UPROPERTY(BlueprintReadOnly, Replicated) float Stamina = 100.f;
    UPROPERTY(BlueprintReadOnly, Replicated) bool bCaught = false;
    UPROPERTY(BlueprintReadOnly, Replicated) bool bLightOn = false;
    UPROPERTY(BlueprintReadOnly, Replicated) bool bSprinting = false;
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
    UFUNCTION(Server, Reliable) void ServerUse();
    UFUNCTION(Server, Reliable) void ServerToggleLight();
    UFUNCTION(Server, Reliable) void ServerSprint(bool bEnabled);
    FVector LastSafePosition;
    double NextUse = 0;
};
