#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "WDCampaignProbe.generated.h"
UCLASS()
class AWDCampaignProbe : public AActor
{
    GENERATED_BODY()
public:
    AWDCampaignProbe();
    virtual void Tick(float DeltaSeconds) override;
private:
    UPROPERTY() TObjectPtr<class AWDCharacter> Player;
    UPROPERTY() TObjectPtr<class AWDGhost> Ghost;
    UPROPERTY() TObjectPtr<class AWDInteractable> Current;
    UPROPERTY() TObjectPtr<class AWDInteractable> Key;
    TArray<FVector> Route;
    FString Phase=TEXT("Startup");
    double At=0;
    int32 Point=0,Flight=0,KeyIndex=0,Checks=0;
    bool Done=false;
    FVector GhostStart;
    void Stage(const FString& Name);
    void Finish(bool Pass,const FString& Why);
    class AWDInteractable* Find(const FString& Tag);
    bool Use(class AWDInteractable* Target);
    void Place(FVector Position);
    void StartFlight();
    void TickNetwork(bool Server);
    void TickTour();
    void TickThreat();
    void TickAudit();
    TArray<TObjectPtr<class AWDInteractable>> AuditObjects;
    int32 NetworkMax=0;
    bool SawHidden=false;
    FString LastThreatScreenshot;
};
