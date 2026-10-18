#include "WDGameState.h"
#include "WDGhost.h"
#include "WDCharacter.h"
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
    if(HasAuthority() && Phase==EWDRoundPhase::Escaped) EndingAge+=DeltaSeconds;
    if (HasAuthority() && Phase == EWDRoundPhase::Introduction)
    {
        IntroRemaining = FMath::Max(0.f, IntroRemaining - DeltaSeconds);
        if (IntroRemaining <= 0) Phase = EWDRoundPhase::Playing;
    }
    if (HasAuthority() && !bRoundEnded && Phase == EWDRoundPhase::Playing)
    {
        SecondsRemaining = FMath::Max(0.f, SecondsRemaining - DeltaSeconds);
        if (SecondsRemaining <= 0.f) EndRound(false, TEXT("Dawn reached the house before you reached the road."));
        int32 Alive=0, Total=0;
        for (TActorIterator<AWDCharacter> It(GetWorld()); It; ++It)
            if (It->IsPlayerControlled()) { ++Total; if (!It->bCaught) ++Alive; }
        if (Total > 0 && Alive == 0) EndRound(false, TEXT("No one was left to turn the ignition."));
    }
}
bool AWDGameState::AddKey(FName Key, const FString& Finder)
{
    if (!HasAuthority() || bRoundEnded || Key.IsNone() || TeamKeys.Contains(Key)) return false;
    TeamKeys.Add(Key);
    LastDiscovery = Finder + TEXT(" found ") + Key.ToString();
    DiscoveryAt = GetServerWorldTimeSeconds();
    ForceNetUpdate();
    return true;
}
void AWDGameState::StartRound(EWDDifficulty Level, bool SkipStory)
{
    if (!HasAuthority() || Phase != EWDRoundPhase::Lobby) return;
    Difficulty=Level; SecondsRemaining=RoundDuration(Level); IntroRemaining=36;
    Phase=SkipStory?EWDRoundPhase::Playing:EWDRoundPhase::Introduction;
    bRoundEnded=false; ForceNetUpdate();
}
void AWDGameState::EndRound(bool Escaped, const FString& Reason)
{
    if (!HasAuthority() || bRoundEnded) return;
    Phase=Escaped?EWDRoundPhase::Escaped:EWDRoundPhase::Lost;
    bRoundEnded=true; EndingReason=Reason; ForceNetUpdate();
}
bool AWDGameState::HasKeys(const TArray<FName>& Keys) const
{
    for (FName Key : Keys) if (!TeamKeys.Contains(Key)) return false;
    return true;
}
bool AWDGameState::CanEscape() const
{
    return Phase==EWDRoundPhase::Playing && !bRoundEnded && bGarageUnlocked && TeamKeys.Contains(TEXT("Ignition"));
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
    DOREPLIFETIME(AWDGameState, Phase);
    DOREPLIFETIME(AWDGameState, IntroRemaining);
    DOREPLIFETIME(AWDGameState, bLetterFound);
    DOREPLIFETIME(AWDGameState, bGarageUnlocked);
    DOREPLIFETIME(AWDGameState, EndingReason);
    DOREPLIFETIME(AWDGameState, DiscoveryAt);
    DOREPLIFETIME(AWDGameState, EndingAge);
}
