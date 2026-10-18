#pragma once
#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "WDPlayerController.generated.h"
UCLASS()
class WAITINGFORDAWN_API AWDPlayerController : public APlayerController
{
    GENERATED_BODY()
public:
    virtual void BeginPlay() override;
    AWDPlayerController();
    virtual void PlayerTick(float DeltaSeconds) override;
    virtual void SetupInputComponent() override;
    virtual bool InputTouch(const FInputDeviceId DeviceId,uint32 Handle,ETouchType::Type Type,const FVector2D& Location,float Force,uint32 TouchpadIndex,const uint64 Timestamp) override;
    UFUNCTION(Server,Reliable) void StartGame(int32 Difficulty,bool Skip);
    UFUNCTION(Server,Reliable) void SkipStory();
    UFUNCTION(Server,Reliable) void Retry();
    UFUNCTION(Client,Reliable) void ShowScare(FVector Face,FVector Facing);
    double ScareUntil=0;
    void OpenJoin();
    void ClosePanels();
    void ToggleMenu();
    void ToggleBag();
    void ToggleJournal();
    int32 SelectedDifficulty=1;
    static FString LastNetworkError;
    bool bMenuOpen=false;
    bool bBagOpen=false;
    FVector2D Stick;
    int32 MoveFinger=-1, LookFinger=-1;
private:
    FVector2D StickOrigin, LastLook;
    UPROPERTY() TObjectPtr<class UWDJoinPanel> JoinPanel;
    UPROPERTY() TObjectPtr<class ACameraActor> StoryCamera;
    UPROPERTY() TObjectPtr<class UAudioComponent> Narration;
    bool bWasStory=false;
    void OnNetworkFailure(UWorld* World,class UNetDriver* Driver,ENetworkFailure::Type Type,const FString& Error);
};
