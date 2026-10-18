#include "WDGameState.h"
#include "WDGhost.h"
#include "EngineUtils.h"
#include "Net/UnrealNetwork.h"

AWDGameState::AWDGameState() { PrimaryActorTick.bCanEverTick = true; }
float AWDGameState::ReactionDelay(EWDDifficulty Level)
{
    const float Values[] = {6.f, 4.5f, 3.f, 2.f};
    return Values[FMath::Clamp(static_cast<int32>(Level), 0, 3)];
}
float AWDGameState::RoundDuration(EWDDifficulty Level)
{
    const float Values[] = {2400.f, 1920.f, 1560.f, 1200.f};
    return Values[FMath::Clamp(static_cast<int32>(Level), 0, 3)];
}
void AWDGameState::BeginPlay()
{
    Super::BeginPlay();
    if (HasAuthority()) SecondsRemaining = RoundDuration(Difficulty);
}
void AWDGameState::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (HasAuthority() && !bRoundEnded)
    {
        SecondsRemaining = FMath::Max(0.f, SecondsRemaining - DeltaSeconds);
        bRoundEnded = SecondsRemaining <= 0.f;
    }
}
bool AWDGameState::AddKey(FName Key, const FString& Finder)
{
    if (!HasAuthority() || bRoundEnded || Key.IsNone() || TeamKeys.Contains(Key)) return false;
    TeamKeys.Add(Key);
    LastDiscovery = Finder + TEXT(" found ") + Key.ToString();
    ForceNetUpdate();
    return true;
}
void AWDGameState::EmitNoise(FVector Location, float Radius, FName Source)
{
    if (!HasAuthority() || bRoundEnded) return;
    UE_LOG(LogTemp, Display, TEXT("WD_NOISE source=%s at=%s"), *Source.ToString(), *Location.ToString());
    for (TActorIterator<AWDGhost> It(GetWorld()); It; ++It)
        if (FVector::DistSquared(It->GetActorLocation(), Location) <= FMath::Square(Radius))
            It->HearNoise(Location, ReactionDelay(Difficulty));
}
void AWDGameState::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME(AWDGameState, Difficulty);
    DOREPLIFETIME(AWDGameState, SecondsRemaining);
    DOREPLIFETIME(AWDGameState, bRoundEnded);
    DOREPLIFETIME(AWDGameState, TeamKeys);
    DOREPLIFETIME(AWDGameState, LastDiscovery);
}
