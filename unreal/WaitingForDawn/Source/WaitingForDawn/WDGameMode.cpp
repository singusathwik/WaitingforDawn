#include "WDGameMode.h"
#include "WDGameState.h"
#include "WDCharacter.h"
#include "WDHUD.h"
#include "WDPlayerController.h"
#include "Kismet/GameplayStatics.h"

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
    }
}
void AWDGameMode::PreLogin(const FString& Options, const FString& Address, const FUniqueNetIdRepl& UniqueId, FString& ErrorMessage)
{
    Super::PreLogin(Options, Address, UniqueId, ErrorMessage);
    if (GetNumPlayers() >= 4) ErrorMessage = TEXT("This house already has four survivors.");
}
