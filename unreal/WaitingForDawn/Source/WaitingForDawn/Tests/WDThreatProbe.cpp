#include "Tests/WDCampaignProbe.h"
#include "WDCharacter.h"
#include "WDGhost.h"
#include "WDGameState.h"
#include "WDPlayerController.h"
#include "Camera/PlayerCameraManager.h"
#include "Components/SkeletalMeshComponent.h"
#include "AIController.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "EngineUtils.h"
#include "Engine/GameViewportClient.h"
#include "Misc/Paths.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"

void AWDCampaignProbe::TickThreat()
{
    const double Now=GetWorld()->GetTimeSeconds();auto* GS=GetWorld()->GetGameState<AWDGameState>();
    if(Now-At>50){Finish(false,TEXT("Threat encounter stage timed out"));return;}
    if(Phase==TEXT("Startup")){
        for(TActorIterator<AWDCharacter>It(GetWorld());It;++It)if(It->IsLocallyControlled())Player=*It;
        for(TActorIterator<AWDGhost>It(GetWorld());It;++It)Ghost=*It;
        if(!Player||!Ghost||Now<5)return;
        GS->StartRound(EWDDifficulty::Normal,true);Place(FVector(0,-800,92));Ghost->SetActorLocation(FVector(0,450,90));Ghost->SetActorRotation(FRotator(0,-90,0));
        Player->GetController()->SetControlRotation(FRotator(0,90,0));GhostStart=Ghost->GetActorLocation();Stage(TEXT("VisibleApproach"));return;
    }
    auto* PC=Cast<AWDPlayerController>(Player->GetController());if(!PC)return;
    if(Now-At>.8&&LastThreatScreenshot!=Phase&&FParse::Param(FCommandLine::Get(),TEXT("WDProbeScreenshots"))){
        LastThreatScreenshot=Phase;FScreenshotRequest::RequestScreenshot(FPaths::ProjectSavedDir()/TEXT("Validation")/(Phase+TEXT("-settled.png")),true,false);
    }
    if(Phase==TEXT("VisibleApproach")||Phase==TEXT("VisibleChase")){
        if(Player->bCaught){Finish(false,TEXT("Captured before readable approach"));return;}
        if(Now-At>2&&Ghost->IsHidden()){Finish(false,TEXT("Approaching ghost is hidden"));return;}
        if(Now-At>2&&Ghost->GetMesh()->Bounds.BoxExtent.Z<55){Finish(false,TEXT("Animated ghost shrank below human scale"));return;}
        if(Ghost->bAttacking){
            if(FVector::Dist2D(GhostStart,Ghost->GetActorLocation())<800){Finish(false,TEXT("No visible physical chase before attack"));return;}
            Checks+=3;Stage(TEXT("AttackWindup"));
        }
        else if(Phase==TEXT("VisibleApproach")&&FVector::Dist2D(Ghost->GetActorLocation(),Player->GetActorLocation())<700)Stage(TEXT("VisibleChase"));
    }
    else if(Phase==TEXT("AttackWindup")&&Now-At>.25){
        if(Player->bCaught){Finish(false,TEXT("Attack skipped its windup"));return;}
        Player->SetSprint(true);Stage(TEXT("SprintEscape"));
    }
    else if(Phase==TEXT("SprintEscape")){
        Player->AddMovementInput(FVector(0,-1,0),1);
        if(Player->bCaught){Finish(false,TEXT("Sprinting out of attack reach failed"));return;}
        if(Now-At>.6){
            if(FVector::Dist2D(Ghost->GetActorLocation(),Player->GetActorLocation())<145){Finish(false,TEXT("Sprint did not create escape space"));return;}
            Checks+=2;Player->SetSprint(false);Ghost->SetActorTickEnabled(false);if(auto* AI=Cast<AAIController>(Ghost->GetController()))AI->StopMovement();
            Ghost->GetCharacterMovement()->DisableMovement();Ghost->bAttacking=false;Place(FVector(0,-700,92));Ghost->SetActorLocation(FVector(0,-300,90));
            Ghost->SetActorRotation(FRotator(0,-90,0));Ghost->bCeilingCrawling=true;PC->SetControlRotation(FRotator(18,90,0));Stage(TEXT("CeilingCrawl"));
        }
    }
    else if(Phase==TEXT("CeilingCrawl")){
        // Tick only visual pose here; independent of the physical chase tested above.
        Ghost->SetActorTickEnabled(true);Ghost->State=EWDGhostState::Patrol;
        // Hide from perception while viewing the overhead body; the real capsule stays grounded.
        GS->Phase=EWDRoundPhase::Escaped;GS->EndingAge=9;
        if(Now-At>2){
            const auto B=Ghost->GetMesh()->Bounds;
            UE_LOG(LogTemp,Display,TEXT("WD_GHOST ceiling bounds %s %s face %s"),*B.Origin.ToString(),*B.BoxExtent.ToString(),*Ghost->GetFaceLocation().ToString());
            if(Ghost->IsHidden()||B.Origin.Z+B.BoxExtent.Z>325||B.Origin.Z<180||FMath::Max(B.BoxExtent.X,B.BoxExtent.Y)<55){Finish(false,TEXT("Ceiling body clipped, shrank or failed to rise"));return;}
            ++Checks;Ghost->bCeilingCrawling=false;Stage(TEXT("Descend"));
        }
    }
    else if(Phase==TEXT("Descend")&&Now-At>1.3){
        GS->Phase=EWDRoundPhase::Playing;Ghost->SetActorTickEnabled(false);Ghost->SetActorLocation(FVector(0,-540,90));Ghost->SetActorRotation(FRotator(0,-90,0));
        Ghost->bAttacking=true;Player->Catch();Stage(TEXT("VisibleCapture"));
    }
    else if(Phase==TEXT("VisibleCapture")&&Now-At>1){
        if(!Player->bCaught||PC->ScareUntil<=Now||PC->GetViewTarget()==Player){Finish(false,TEXT("Capture camera missing"));return;}
        const FVector Face=Ghost->GetFaceLocation();const FVector View=PC->PlayerCameraManager->GetCameraLocation();
        if(FVector::Dist(Face,View)>150){Finish(false,TEXT("Capture camera does not frame ghost face"));return;}++Checks;Stage(TEXT("CaptureHeld"));
    }
    else if(Phase==TEXT("CaptureHeld")&&Now-At>2){
        if(GS->Phase!=EWDRoundPhase::Lost){Finish(false,TEXT("Capture did not end solo round"));return;}
        ++Checks;Finish(true,TEXT("Visible physical approach, cancellable windup, actual sprint escape, ceiling bounds and face-framed capture"));
    }
}
