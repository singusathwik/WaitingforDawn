#include "Tests/WDGameplayProbe.h"
#include "WDCharacter.h"
#include "WDGhost.h"
#include "WDInteractable.h"
#include "WDGameState.h"
#include "AIController.h"
#include "Components/StaticMeshComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "EngineUtils.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "HAL/FileManager.h"
#include "Engine/World.h"
#include "Engine/GameViewportClient.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"

AWDGameplayProbe::AWDGameplayProbe() { PrimaryActorTick.bCanEverTick = true; }
void AWDGameplayProbe::Stage(const FString& Name)
{
    Phase = Name;
    PhaseAt = GetWorld()->GetTimeSeconds();
    UE_LOG(LogTemp, Display, TEXT("WD_PROBE_STAGE %s"), *Phase);
    if (FParse::Param(FCommandLine::Get(), TEXT("WDProbeScreenshots")))
        FScreenshotRequest::RequestScreenshot(FPaths::ProjectSavedDir() / TEXT("Validation") / (Phase + TEXT(".png")), true, false);
}
void AWDGameplayProbe::Finish(bool Success, const FString& Detail)
{
    if (bFinished) return;
    bFinished = true;
    if (Player) UE_LOG(LogTemp, Display, TEXT("WD_PROBE_PLAYER position=%s caught=%d velocity=%s"),
        *Player->GetActorLocation().ToString(), Player->bCaught, *Player->GetVelocity().ToString());
    if (Ghost) UE_LOG(LogTemp, Display, TEXT("WD_PROBE_GHOST position=%s goal=%s state=%d"),
        *Ghost->GetActorLocation().ToString(), *Ghost->NoiseGoal.ToString(), static_cast<int32>(Ghost->State));
    const FString Report = FString::Printf(TEXT("{\"passed\":%s,\"phase\":\"%s\",\"detail\":\"%s\",\"stair_waypoints\":%d,\"ghost_travel_cm\":%.1f}\n"),
        Success ? TEXT("true") : TEXT("false"), *Phase, *Detail, Waypoint, MaximumGhostTravel);
    const FString Directory = FPaths::ProjectSavedDir() / TEXT("Validation");
    IFileManager::Get().MakeDirectory(*Directory, true);
    const TCHAR* File = FParse::Param(FCommandLine::Get(),TEXT("WDNetworkServer")) ? TEXT("network-server.json") :
        FParse::Param(FCommandLine::Get(),TEXT("WDNetworkClient")) ? TEXT("network-client.json") : TEXT("gameplay-probe.json");
    FFileHelper::SaveStringToFile(Report, *(Directory / File));
    UE_LOG(LogTemp, Display, TEXT("WD_PROBE_RESULT %s"), *Report);
    FPlatformMisc::RequestExitWithStatus(false, Success ? 0 : 1);
}
bool AWDGameplayProbe::AimAndUse(AWDInteractable* Target)
{
    if (!Player || !Target || !Player->GetController()) return false;
    Player->GetController()->SetControlRotation((Target->GetInteractionPoint() - Player->GetPawnViewLocation()).Rotation());
    if (Player->FindInteractionTarget() != Target)
    {
        Finish(false, TEXT("Expected handle/key is not selectable from the test position"));
        return false;
    }
    Player->Use();
    return true;
}
void AWDGameplayProbe::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (bFinished) return;
    if (FParse::Param(FCommandLine::Get(),TEXT("WDNetworkServer"))) { TickNetwork(true); return; }
    if (FParse::Param(FCommandLine::Get(),TEXT("WDNetworkClient"))) { TickNetwork(false); return; }
    const double Now = GetWorld()->GetTimeSeconds();
    if (Now - PhaseAt > 75.) { Finish(false, TEXT("Stage timed out")); return; }
    if (Phase == TEXT("Startup"))
    {
        for (TActorIterator<AWDCharacter> It(GetWorld()); It; ++It) if (It->IsPlayerControlled()) { Player = *It; break; }
        for (TActorIterator<AWDGhost> It(GetWorld()); It; ++It) { Ghost = *It; break; }
        for (TActorIterator<AWDInteractable> It(GetWorld()); It; ++It)
        {
            if (It->Kind == EWDInteraction::Key) Key = *It;
            else if (It->GetActorLocation().X < -400) Cupboard = *It;
            else Door = *It;
        }
        if (!Player || !Ghost || !Cupboard || !Key || !Door) { Finish(false,TEXT("Missing test actors")); return; }
        Ghost->SetActorTickEnabled(false);
        if (auto* AI = Cast<AAIController>(Ghost->GetController())) AI->StopMovement();
        Ghost->GetCharacterMovement()->DisableMovement();
        if (Now < 4.) return;
        if (Player->bCaught) { Finish(false,TEXT("Player caught before isolated traversal began")); return; }
        Player->SetActorLocation(FVector(-450,250,92),false,nullptr,ETeleportType::TeleportPhysics);
        Route = {FVector(-340,250,48),FVector(-200,250,128),FVector(-60,250,208),FVector(80,250,288),
            FVector(220,250,320),FVector(310,250,320),FVector(310,40,320),FVector(-320,40,320),
            FVector(310,40,320),FVector(310,250,320),FVector(220,250,320),FVector(80,250,288),
            FVector(-60,250,208),FVector(-200,250,128),FVector(-340,250,48),FVector(-450,250,0)};
        Stage(TEXT("StairsUpAndDown"));
    }
    else if (Phase == TEXT("StairsUpAndDown"))
    {
        const FVector Position = Player->GetActorLocation();
        if (Position.Z < 80 || Player->FallRecoveryCount != 0) { Finish(false,TEXT("Character fell or required recovery")); return; }
        FVector Delta = Route[Waypoint] - Position;
        if (Delta.Size2D() < 18)
        {
            if (FMath::Abs(Position.Z - 92 - Route[Waypoint].Z) > 40) { Finish(false,TEXT("Character reached wrong floor")); return; }
            ++Waypoint;
            UE_LOG(LogTemp, Display, TEXT("WD_PROBE_WAYPOINT %d position=%s"), Waypoint, *Position.ToString());
            if (Waypoint == Route.Num())
            {
                Player->GetCharacterMovement()->StopMovementImmediately();
                Player->SetActorLocation(FVector(-520,-110,92),false,nullptr,ETeleportType::TeleportPhysics);
                Player->ToggleLight();
                if (!AimAndUse(Cupboard)) return;
                if (!Cupboard->bOpen) { Finish(false,TEXT("Cupboard did not open")); return; }
                Stage(TEXT("VisibleKey"));
                return;
            }
            Delta = Route[Waypoint] - Position;
        }
        Delta.Z = 0;
        Player->AddMovementInput(Delta.GetSafeNormal());
    }
    else if (Phase == TEXT("VisibleKey") && Now - PhaseAt > .8)
    {
        if (Key->IsHidden() || !Key->IsAvailable()) { Finish(false,TEXT("Key not visible in open cupboard")); return; }
        Player->GetController()->SetControlRotation((Key->GetInteractionPoint()-Player->GetPawnViewLocation()).Rotation());
        Stage(TEXT("KeyInspection"));
    }
    else if (Phase == TEXT("KeyInspection") && Now - PhaseAt > .8)
    {
        if (!AimAndUse(Key)) return;
        const auto* GS = GetWorld()->GetGameState<AWDGameState>();
        if (!Key->bCollected || !GS || !GS->TeamKeys.Contains(Key->GrantsKey)) { Finish(false,TEXT("Key was not added to shared inventory")); return; }
        Stage(TEXT("CloseCupboard"));
    }
    else if (Phase == TEXT("CloseCupboard") && Now - PhaseAt > .8)
    {
        if (!AimAndUse(Cupboard)) return;
        if (Cupboard->bOpen) { Finish(false,TEXT("Cupboard could not close again")); return; }
        Player->SetActorLocation(FVector(-340,-145,92),false,nullptr,ETeleportType::TeleportPhysics);
        Stage(TEXT("DoorNoise"));
    }
    else if (Phase == TEXT("DoorNoise") && Now - PhaseAt > .8)
    {
        Ghost->State = EWDGhostState::Patrol;
        Ghost->SetActorTickEnabled(true);
        Ghost->GetCharacterMovement()->SetMovementMode(MOVE_Walking);
        GhostStart = Ghost->GetActorLocation();
        FHitResult Hit;
        if (!GetWorld()->LineTraceSingleByChannel(Hit,FVector(-240,-145,110),FVector(-160,-145,110),ECC_Visibility) || Hit.GetActor()!=Door)
        { Finish(false,TEXT("Closed door has no blocking collision across doorway")); return; }
        if (!AimAndUse(Door)) return;
        if (!Door->bOpen || Ghost->State != EWDGhostState::Listening) { Finish(false,TEXT("Door did not generate an audible AI event")); return; }
        // Remove visual pursuit as a confound: the player waits upstairs behind a solid floor.
        Player->SetActorLocation(FVector(-320,-300,412),false,nullptr,ETeleportType::TeleportPhysics);
        Player->GetCharacterMovement()->StopMovementImmediately();
        Stage(TEXT("NoiseInvestigation"));
    }
    else if (Phase == TEXT("NoiseInvestigation"))
    {
        MaximumGhostTravel = FMath::Max(MaximumGhostTravel,FVector::Dist(GhostStart,Ghost->GetActorLocation()));
        if (Ghost->State == EWDGhostState::Chasing) { Finish(false,TEXT("Sight contaminated the noise-only test")); return; }
        if (Ghost->State == EWDGhostState::Searching && MaximumGhostTravel > 250)
        {
            Finish(true,TEXT("Actual stairs traversed both ways; cupboard opened/closed; visible key collected; door noise investigated"));
        }
        else if (Now - PhaseAt > 35.) Finish(false,TEXT("Ghost failed to reach the noise location"));
    }
}

void AWDGameplayProbe::TickNetwork(bool Server)
{
    const double Now=GetWorld()->GetTimeSeconds();
    if (Now-PhaseAt>45.) { Finish(false,TEXT("Network stage timed out")); return; }
    auto* GS=GetWorld()->GetGameState<AWDGameState>();
    if (!GS) return;
    NetworkPlayers=FMath::Max(NetworkPlayers,GS->PlayerArray.Num());
    if (Server)
    {
        for (TActorIterator<AWDGhost> It(GetWorld()); It; ++It)
        {
            It->SetActorTickEnabled(false);
            if (auto* AI=Cast<AAIController>(It->GetController())) AI->StopMovement();
            It->GetCharacterMovement()->DisableMovement();
        }
        if (GS->TeamKeys.Contains(TEXT("Nursery")) && Phase!=TEXT("ReplicatedPickup")) Stage(TEXT("ReplicatedPickup"));
        if (Phase==TEXT("ReplicatedPickup") && Now-PhaseAt>3.)
            Finish(NetworkPlayers>=2,NetworkPlayers>=2?TEXT("Remote client pickup validated by listen server with two connected players"):TEXT("Two players never joined"));
        return;
    }
    if (Phase==TEXT("Startup"))
    {
        for (TActorIterator<AWDCharacter> It(GetWorld()); It; ++It) if (It->IsLocallyControlled()) Player=*It;
        for (TActorIterator<AWDInteractable> It(GetWorld()); It; ++It)
        {
            if (It->Kind==EWDInteraction::Key) Key=*It;
            else if (It->GetActorLocation().X < -400) Cupboard=*It;
        }
        if (!Player || !Player->GetController() || !Key || !Cupboard || NetworkPlayers<2) return;
        if (FVector::Dist2D(Player->GetActorLocation(),FVector(-520,-110,92))>30) return;
        Player->GetController()->SetControlRotation((Cupboard->GetInteractionPoint()-Player->GetPawnViewLocation()).Rotation());
        Stage(TEXT("AimCupboard"));
    }
    else if (Phase==TEXT("AimCupboard") && Now-PhaseAt>.6)
    {
        if (!AimAndUse(Cupboard)) return;
        Stage(TEXT("WaitOpenReplication"));
    }
    else if (Phase==TEXT("WaitOpenReplication"))
    {
        if (Cupboard->bOpen && Key->IsAvailable())
        {
            Player->GetController()->SetControlRotation((Key->GetInteractionPoint()-Player->GetPawnViewLocation()).Rotation());
            Stage(TEXT("AimKey"));
        }
        else if (Now-PhaseAt>8.) Finish(false,TEXT("Client use did not replicate an open cupboard"));
    }
    else if (Phase==TEXT("AimKey") && Now-PhaseAt>.6)
    {
        if (!AimAndUse(Key)) return;
        Stage(TEXT("WaitInventoryReplication"));
    }
    else if (Phase==TEXT("WaitInventoryReplication"))
    {
        if (GS->TeamKeys.Contains(TEXT("Nursery")) && Key->bCollected && !GS->LastDiscovery.IsEmpty())
            Finish(true,TEXT("Remote client opened cupboard and received server-owned key inventory and discovery message"));
        else if (Now-PhaseAt>8.) Finish(false,TEXT("Shared key and discovery did not replicate"));
    }
}
