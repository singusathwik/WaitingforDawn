#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "WDInteractable.generated.h"

class AWDCharacter;
class UStaticMeshComponent;
class USceneComponent;
class USoundBase;

UENUM(BlueprintType)
enum class EWDInteraction : uint8 { Door, Drawer, Key, Letter, Wardrobe, Bed, Garage, Car, Noise };

// Furniture shell is a separate static actor. This actor contains only its moving leaf/tray.
UCLASS()
class WAITINGFORDAWN_API AWDInteractable : public AActor
{
    GENERATED_BODY()
public:
    AWDInteractable();
    virtual void Tick(float DeltaSeconds) override;
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& Out) const override;
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly) TObjectPtr<USceneComponent> Pivot;
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly) TObjectPtr<UStaticMeshComponent> Mesh;
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly) TObjectPtr<USceneComponent> Handle;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) EWDInteraction Kind = EWDInteraction::Door;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FText DisplayName;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FName RequiredKey;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TArray<FName> RequiredKeys;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FVector HideOffset = FVector(0,0,90);
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FVector ExitOffset = FVector(0,-140,92);
    UPROPERTY(BlueprintReadOnly, Replicated) TObjectPtr<AWDCharacter> Occupant;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FName GrantsKey;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FVector OpenOffset = FVector(0,-45,0);
    UPROPERTY(EditAnywhere, BlueprintReadOnly) float OpenYaw = 100.f;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) bool bBlocksPassage = true;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TObjectPtr<AWDInteractable> Container;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TObjectPtr<USoundBase> InteractionSound;
    UPROPERTY(BlueprintReadOnly, ReplicatedUsing=OnRep_State) bool bOpen = false;
    UPROPERTY(BlueprintReadOnly, ReplicatedUsing=OnRep_State) bool bCollected = false;
    FVector GetInteractionPoint() const;
    bool IsAvailable() const;
    FText GetPrompt() const;
    void Interact(AWDCharacter* User);
protected:
    virtual void BeginPlay() override;
    UFUNCTION() void OnRep_State();
    UFUNCTION(NetMulticast, Unreliable) void PlayInteractionSound();
private:
    float OpenFraction = 0;
    double NextUseTime = 0;
    FVector ClosedLocation;
    FRotator ClosedRotation;
};
