#include "WDGameMode.h"
#include "WDGameState.h"
#include "WDCharacter.h"
#include "WDHUD.h"
#include "WDPlayerController.h"
#include "Kismet/GameplayStatics.h"
#include "Tests/WDGameplayProbe.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "WDAmbience.h"
#include "Tests/WDCampaignProbe.h"
#include "NavigationSystem.h"

void AWDGameMode::BeginPlay()
{
    Super::BeginPlay();
    // A saved editor map can contain an unfinished asynchronous nav build.
    // Rebuild all runtime tiles on the authority, including unchanged stairs.
    if(auto* Navigation=FNavigationSystem::GetCurrent<UNavigationSystemV1>(GetWorld()))Navigation->Build();
    GetWorld()->SpawnActor<AWDAmbience>();
#if !UE_BUILD_SHIPPING
    if(FParse::Param(FCommandLine::Get(),TEXT("WDHouseTest"))||FParse::Param(FCommandLine::Get(),TEXT("WDHouseNetServer"))||FParse::Param(FCommandLine::Get(),TEXT("WDVisualTour"))||FParse::Param(FCommandLine::Get(),TEXT("WDThreatTest")))GetWorld()->SpawnActor<AWDCampaignProbe>();
    if (FParse::Param(FCommandLine::Get(), TEXT("WDGameplayTest")) ||
        FParse::Param(FCommandLine::Get(), TEXT("WDNetworkServer"))) GetWorld()->SpawnActor<AWDGameplayProbe>();
#endif
}
void AWDGameMode::RestartPlayer(AController* NewPlayer)
{
    Super::RestartPlayer(NewPlayer);
#if !UE_BUILD_SHIPPING
    if(FParse::Param(FCommandLine::Get(),TEXT("WDHouseNetServer"))&&NewPlayer&&NewPlayer->GetPawn()&&!NewPlayer->IsLocalController())
        NewPlayer->GetPawn()->SetActorLocation(GetNumPlayers()<=2?FVector(-828,-1150,92):FVector(0,-500+GetNumPlayers()*90,92),false,nullptr,ETeleportType::TeleportPhysics);
    if (FParse::Param(FCommandLine::Get(),TEXT("WDNetworkServer")) && NewPlayer && NewPlayer->GetPawn())
        NewPlayer->GetPawn()->SetActorLocation(NewPlayer->IsLocalController()?FVector(-350,-50,92):FVector(-520,-110,92),false,nullptr,ETeleportType::TeleportPhysics);
#endif
}

AWDGameMode::AWDGameMode()
{
    DefaultPawnClass = AWDCharacter::StaticClass();
    GameStateClass = AWDGameState::StaticClass();
    HUDClass = AWDHUD::StaticClass();
    PlayerControllerClass = AWDPlayerController::StaticClass();
}
void AWDGameMode::InitGameState()
{
    Super::InitGameState();
    if (auto* State = GetGameState<AWDGameState>())
    {
        const int32 Level = FMath::Clamp(UGameplayStatics::GetIntOption(OptionsString, TEXT("Difficulty"), 1), 0, 3);
        State->Difficulty = static_cast<EWDDifficulty>(Level);
        State->SecondsRemaining = AWDGameState::RoundDuration(State->Difficulty);
        if (GetWorld()->GetMapName().Contains(TEXT("House")))
        {
            State->Phase=EWDRoundPhase::Lobby;
            if (UGameplayStatics::HasOption(OptionsString,TEXT("Start")))
                State->StartRound(State->Difficulty,UGameplayStatics::HasOption(OptionsString,TEXT("SkipStory")));
        }
    }
}
void AWDGameMode::PreLogin(const FString& Options, const FString& Address, const FUniqueNetIdRepl& UniqueId, FString& ErrorMessage)
{
    Super::PreLogin(Options, Address, UniqueId, ErrorMessage);
    if (GetNumPlayers() >= 4) ErrorMessage = TEXT("This house already has four survivors.");
}
