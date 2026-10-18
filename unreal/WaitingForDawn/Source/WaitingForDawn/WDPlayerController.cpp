#include "WDPlayerController.h"
#include "Tests/WDGameplayProbe.h"
#include "Tests/WDCampaignProbe.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "Engine/World.h"
#include "WDGameState.h"
#include "WDCharacter.h"
#include "WDInteractable.h"
#include "EngineUtils.h"
#include "WDHUD.h"
#include "WDJoinPanel.h"
#include "Camera/CameraActor.h"
#include "Camera/CameraComponent.h"
#include "Components/AudioComponent.h"
#include "Components/InputComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Engine/Engine.h"
#include "GameFramework/CharacterMovementComponent.h"

FString AWDPlayerController::LastNetworkError;
void AWDPlayerController::BeginPlay()
{
    Super::BeginPlay();
    if(auto* GS=GetWorld()->GetGameState<AWDGameState>())SelectedDifficulty=static_cast<int32>(GS->Difficulty);
    if(IsLocalController() && GEngine) GEngine->OnNetworkFailure().AddUObject(this,&AWDPlayerController::OnNetworkFailure);
#if !UE_BUILD_SHIPPING
    if(IsLocalController()&&GetNetMode()==NM_Client&&FParse::Param(FCommandLine::Get(),TEXT("WDHouseNetClient")))GetWorld()->SpawnActor<AWDCampaignProbe>();
    if (IsLocalController() && GetNetMode()==NM_Client && FParse::Param(FCommandLine::Get(),TEXT("WDNetworkClient")))
        GetWorld()->SpawnActor<AWDGameplayProbe>();
#endif
}
void AWDPlayerController::OnNetworkFailure(UWorld*,UNetDriver*,ENetworkFailure::Type,const FString& Error)
{ if (IsLocalController()){LastNetworkError=Error;UGameplayStatics::OpenLevel(this,TEXT("House"));} }
void AWDPlayerController::StartGame_Implementation(int32 Difficulty,bool Skip)
{
    if (GetNetMode()==NM_ListenServer && !IsLocalController()) return;
    if(auto* GS=GetWorld()->GetGameState<AWDGameState>()) GS->StartRound(static_cast<EWDDifficulty>(FMath::Clamp(Difficulty,0,3)),Skip);
}
void AWDPlayerController::SkipStory_Implementation()
{
    if (GetNetMode()==NM_ListenServer && !IsLocalController()) return;
    if(auto* GS=GetWorld()->GetGameState<AWDGameState>(); GS && GS->Phase==EWDRoundPhase::Introduction) GS->IntroRemaining=0;
}
void AWDPlayerController::Retry_Implementation()
{
    if (GetNetMode()==NM_ListenServer && !IsLocalController()) return;
    if(auto* GS=GetWorld()->GetGameState<AWDGameState>())
        GetWorld()->ServerTravel(FString::Printf(TEXT("/Game/Maps/House?Start?SkipStory?Difficulty=%d%s"),static_cast<int32>(GS->Difficulty),GetNetMode()==NM_ListenServer?TEXT("?listen"):TEXT("")));
}
void AWDPlayerController::SetupInputComponent()
{
    Super::SetupInputComponent();
    InputComponent->BindAction("Menu",IE_Pressed,this,&AWDPlayerController::ToggleMenu);
    InputComponent->BindAction("Bag",IE_Pressed,this,&AWDPlayerController::ToggleBag);
    InputComponent->BindAction("Journal",IE_Pressed,this,&AWDPlayerController::ToggleJournal);
}
void AWDPlayerController::ToggleMenu() { bMenuOpen=!bMenuOpen; }
void AWDPlayerController::ToggleBag(){bBagOpen=!bBagOpen;bMenuOpen=false;if(auto* P=Cast<AWDCharacter>(GetPawn()))P->bJournalOpen=false;}
void AWDPlayerController::ToggleJournal(){if(auto* P=Cast<AWDCharacter>(GetPawn()))P->bJournalOpen=!P->bJournalOpen;bBagOpen=false;bMenuOpen=false;}
void AWDPlayerController::ShowScare_Implementation(FVector Face,FVector Facing)
{
    ScareUntil=GetWorld()->GetTimeSeconds()+1.6;
    if(!StoryCamera)StoryCamera=GetWorld()->SpawnActor<ACameraActor>();
    StoryCamera->GetCameraComponent()->bConstrainAspectRatio=false;
    StoryCamera->SetActorLocation(Face+Facing*85);
    StoryCamera->SetActorRotation((Face-StoryCamera->GetActorLocation()).Rotation());SetViewTarget(StoryCamera);
}
void AWDPlayerController::ClosePanels() { JoinPanel=nullptr; bMenuOpen=false; SetInputMode(FInputModeGameAndUI()); }
void AWDPlayerController::OpenJoin()
{
    if(!JoinPanel) { JoinPanel=CreateWidget<UWDJoinPanel>(this,UWDJoinPanel::StaticClass()); JoinPanel->AddToViewport(20); }
    SetInputMode(FInputModeGameAndUI()); bShowMouseCursor=true;
}
void AWDPlayerController::PlayerTick(float DeltaSeconds)
{
    Super::PlayerTick(DeltaSeconds);
    if(!IsLocalController()) return;
    auto* GS=GetWorld()->GetGameState<AWDGameState>(); auto* P=Cast<AWDCharacter>(GetPawn());
    if(!GS || !P) return;
    if(ScareUntil>GetWorld()->GetTimeSeconds())return;
    if(ScareUntil>0){ScareUntil=0;SetViewTarget(P);if(StoryCamera)StoryCamera->Destroy();StoryCamera=nullptr;}
    bShowMouseCursor=bMenuOpen || JoinPanel || GS->Phase!=EWDRoundPhase::Playing || P->bCaught || bBagOpen || P->bJournalOpen;
    if(GS->Phase==EWDRoundPhase::Playing && !bMenuOpen && !bBagOpen && !P->bJournalOpen && !JoinPanel && !P->bCaught && !P->HidingSpot)
    {
        const FRotator Yaw(0,GetControlRotation().Yaw,0);
        P->AddMovementInput(FRotationMatrix(Yaw).GetUnitAxis(EAxis::X),-Stick.Y);
        P->AddMovementInput(FRotationMatrix(Yaw).GetUnitAxis(EAxis::Y),Stick.X);
    }
    if(GS->Phase==EWDRoundPhase::Escaped && GS->EndingAge<8)
    {
        if(!StoryCamera)StoryCamera=GetWorld()->SpawnActor<ACameraActor>();
        SetViewTarget(StoryCamera);
        for(TActorIterator<AWDInteractable>It(GetWorld());It;++It)if(It->Kind==EWDInteraction::Car)
        {StoryCamera->SetActorLocation(It->GetActorLocation()+FVector(-360,380,210));StoryCamera->SetActorRotation((It->GetActorLocation()+FVector(0,0,70)-StoryCamera->GetActorLocation()).Rotation());break;}
        return;
    }
    if(GS->Phase==EWDRoundPhase::Introduction)
    {
        if(!bWasStory)
        {
            bWasStory=true; StoryCamera=GetWorld()->SpawnActor<ACameraActor>();
            StoryCamera->GetCameraComponent()->bConstrainAspectRatio=false; SetViewTarget(StoryCamera);
            if(auto* Voice=LoadObject<USoundBase>(nullptr,TEXT("/Game/Imported/S_introduction.S_introduction"))) Narration=UGameplayStatics::SpawnSound2D(this,Voice,.7f);
        }
        const float T=36-GS->IntroRemaining;
        const FVector Shots[]={FVector(0,-2200,200),FVector(0,-1000,170),FVector(-1000,390,500),FVector(-970,30,445)};
        const FVector Targets[]={FVector(0,-1200,440),FVector(0,0,170),FVector(-1100,160,345),FVector(-1040,175,350)};
        const int32 Shot=FMath::Clamp(static_cast<int32>(T/9.f),0,3);
        const FVector Position=Shots[Shot]+FVector(FMath::Fmod(T,9.f)*3,0,0);
        StoryCamera->SetActorLocation(Position);StoryCamera->SetActorRotation((Targets[Shot]-Position).Rotation());
    }
    else if(bWasStory)
    { bWasStory=false; SetViewTarget(P); if(StoryCamera) StoryCamera->Destroy(); StoryCamera=nullptr; if(Narration) Narration->Stop(); }
}
bool AWDPlayerController::InputTouch(const FInputDeviceId DeviceId,uint32 Handle,ETouchType::Type Type,const FVector2D& Location,float Force,uint32 TouchpadIndex,const uint64 Timestamp)
{
    if(JoinPanel) return Super::InputTouch(DeviceId,Handle,Type,Location,Force,TouchpadIndex,Timestamp);
    int32 W,H; GetViewportSize(W,H);
    if(Type==ETouchType::Began)
    {
        if(auto* UI=Cast<AWDHUD>(GetHUD()); UI && UI->ClickAt(Location)) return true;
        if(Location.X<W*.36 && Location.Y>H*.45 && MoveFinger<0) { MoveFinger=Handle; StickOrigin=Location; Stick=FVector2D::ZeroVector; }
        else if(LookFinger<0) { LookFinger=Handle; LastLook=Location; }
    }
    else if(Type==ETouchType::Moved || Type==ETouchType::Stationary)
    {
        if(static_cast<int32>(Handle)==MoveFinger) Stick=((Location-StickOrigin)/(H*.13f)).GetClampedToMaxSize(1);
        if(static_cast<int32>(Handle)==LookFinger)
        {
            auto* GS=GetWorld()->GetGameState<AWDGameState>();
            if(GS && GS->Phase==EWDRoundPhase::Playing && !bMenuOpen) { const FVector2D D=Location-LastLook; AddYawInput(D.X*.13f); AddPitchInput(D.Y*.13f); }
            LastLook=Location;
        }
    }
    else if(Type==ETouchType::Ended)
    { if(static_cast<int32>(Handle)==MoveFinger) {MoveFinger=-1;Stick=FVector2D::ZeroVector;} if(static_cast<int32>(Handle)==LookFinger) LookFinger=-1; }
    return true;
}
AWDPlayerController::AWDPlayerController()
{
    bEnableTouchEvents = true;
    bEnableClickEvents = true;
    bShowMouseCursor = false;
}
