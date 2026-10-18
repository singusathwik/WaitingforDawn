#include "WDGhost.h"
#include "WDCharacter.h"
#include "WDGameState.h"
#include "AIController.h"
#include "Components/CapsuleComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Animation/AnimSequence.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/GameplayStatics.h"
#include "EngineUtils.h"
#include "Net/UnrealNetwork.h"

AWDGhost::AWDGhost()
{
    bReplicates = true;
    PrimaryActorTick.bCanEverTick = true;
    GetCapsuleComponent()->InitCapsuleSize(32,88);
    AIControllerClass = AAIController::StaticClass();
    AutoPossessAI = EAutoPossessAI::PlacedInWorldOrSpawned;
    GetCharacterMovement()->MaxWalkSpeed = 190.f;
    GetCharacterMovement()->MaxStepHeight = 35.f;
    GetCharacterMovement()->bOrientRotationToMovement = true;
    bUseControllerRotationYaw = false;
}
void AWDGhost::BeginPlay() { Super::BeginPlay(); }
double AWDGhost::ReactionDeadline(EWDGhostState Current, double Existing, double Now, float Delay)
{
    if (Current == EWDGhostState::Chasing || Current == EWDGhostState::Investigating) return Now;
    return Current == EWDGhostState::Listening ? FMath::Min(Existing, Now + Delay) : Now + Delay;
}
void AWDGhost::HearNoise(FVector Location, float Delay)
{
    if (!HasAuthority()) return;
    const double Now = GetWorld()->GetTimeSeconds();
    NoiseGoal = Location;
    RememberUntil = Now + 90.;
    // Repeated drawer clicks must never postpone an investigation already counting down.
    ReactAt = ReactionDeadline(State, ReactAt, Now, Delay);
    if (State != EWDGhostState::Chasing && State != EWDGhostState::Investigating) State = EWDGhostState::Listening;
    NextRouteAt = 0;
    if (Now >= NextWarningAt) { Warn(); NextWarningAt = Now + 8.; }
    ForceNetUpdate();
}
void AWDGhost::Warn_Implementation()
{
    if (WarningSound) UGameplayStatics::PlaySoundAtLocation(this, WarningSound, GetActorLocation(), .65f);
}
void AWDGhost::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    UAnimSequence* DesiredAnimation = GetVelocity().SizeSquared2D() < 25.f ? IdleAnimation.Get() :
        State == EWDGhostState::Chasing ? RunAnimation.Get() : WalkAnimation.Get();
    if (DesiredAnimation && ActiveAnimation != DesiredAnimation)
    {
        ActiveAnimation = DesiredAnimation;
        GetMesh()->PlayAnimation(DesiredAnimation, true);
    }
    if (!HasAuthority()) return;
    auto* AI = Cast<AAIController>(GetController());
    auto* GS = GetWorld()->GetGameState<AWDGameState>();
    if (!AI || !GS) return;
    if (GS->bRoundEnded) { AI->StopMovement(); return; }
    const double Now = GetWorld()->GetTimeSeconds();
    AWDCharacter* Seen = nullptr;
    float Nearest = 1400.f;
    for (TActorIterator<AWDCharacter> It(GetWorld()); It; ++It)
    {
        const float Distance = FVector::Dist(GetActorLocation(), It->GetActorLocation());
        const FVector Direction = (It->GetActorLocation() - GetActorLocation()).GetSafeNormal();
        if (!It->bCaught && Distance < Nearest && (Distance < 180.f || FVector::DotProduct(GetActorForwardVector(), Direction) > .25f)
            && AI->LineOfSightTo(*It)) { Seen = *It; Nearest = Distance; }
    }
    if (Seen)
    {
        ChaseTarget = Seen;
        LastSeen = Seen->GetActorLocation();
        SeenAt = Now;
        State = EWDGhostState::Chasing;
        if (Nearest < 115.f) Seen->Catch();
    }
    if (State == EWDGhostState::Chasing && (!ChaseTarget.IsValid() || ChaseTarget->bCaught || Now - SeenAt > 3.))
    {
        NoiseGoal = LastSeen;
        RememberUntil = Now + 30.;
        State = EWDGhostState::Investigating;
        ChaseTarget.Reset();
    }
    if (State == EWDGhostState::Listening)
    {
        AI->StopMovement();
        if (Now < ReactAt) return;
        State = EWDGhostState::Investigating;
        NextRouteAt = 0;
    }
    if (State == EWDGhostState::Investigating)
    {
        if (FVector::Dist(GetActorLocation(), NoiseGoal) < 110.f)
        { State = EWDGhostState::Searching; SearchUntil = Now + 8.; }
        else if (Now > RememberUntil) State = EWDGhostState::Patrol;
    }
    if (State == EWDGhostState::Searching)
    {
        AI->StopMovement();
        if (Now < SearchUntil) { AddActorWorldRotation(FRotator(0,DeltaSeconds*24.f,0)); return; }
        State = EWDGhostState::Patrol;
    }
    if (Now < NextRouteAt) return;
    NextRouteAt = Now + .6;
    FVector Destination = NoiseGoal;
    if (State == EWDGhostState::Chasing)
    {
        Destination = LastSeen; // Never track the player's hidden position through walls.
        GetCharacterMovement()->MaxWalkSpeed = 345.f;
    }
    else
    {
        GetCharacterMovement()->MaxWalkSpeed = 190.f;
        if (State == EWDGhostState::Patrol)
        {
            if (PatrolPoints.IsEmpty()) return;
            if (FVector::Dist(GetActorLocation(), PatrolPoints[PatrolIndex]) < 120.f)
                PatrolIndex = (PatrolIndex + 1) % PatrolPoints.Num();
            Destination = PatrolPoints[PatrolIndex];
        }
    }
    // Partial paths let her reach the accessible side of a shut door. Keep the original goal
    // and retry after dynamic navigation updates instead of discarding it on path failure.
    AI->MoveToLocation(Destination, 45.f, true, true, true, false, nullptr, true);
}
void AWDGhost::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& Out) const
{
    Super::GetLifetimeReplicatedProps(Out);
    DOREPLIFETIME(AWDGhost, State);
    DOREPLIFETIME(AWDGhost, NoiseGoal);
}
