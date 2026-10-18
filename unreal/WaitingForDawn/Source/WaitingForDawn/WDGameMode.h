#pragma once
#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "WDGameMode.generated.h"
UCLASS()
class WAITINGFORDAWN_API AWDGameMode : public AGameModeBase
{
    GENERATED_BODY()
public:
    AWDGameMode();
    virtual void BeginPlay() override;
    virtual void RestartPlayer(AController* NewPlayer) override;
    virtual void InitGameState() override;
    virtual void PreLogin(const FString& Options, const FString& Address, const FUniqueNetIdRepl& UniqueId, FString& ErrorMessage) override;
};
