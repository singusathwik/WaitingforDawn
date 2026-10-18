#include "Tests/WDCampaignProbe.h"
#include "WDCharacter.h"
#include "WDInteractable.h"
#include "WDGameState.h"
#include "WDGhost.h"
#include "WDPlayerController.h"
#include "AIController.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Components/BoxComponent.h"
#include "EngineUtils.h"

void AWDCampaignProbe::TickAudit()
{
    const double Now=GetWorld()->GetTimeSeconds();auto* GS=GetWorld()->GetGameState<AWDGameState>();
    if(Now-At>25){Finish(false,TEXT("Component audit stage timeout"));return;}
    if(Phase==TEXT("Startup")){
        for(TActorIterator<AWDCharacter> It(GetWorld());It;++It)if(It->IsLocallyControlled())Player=*It;
        for(TActorIterator<AWDGhost> It(GetWorld());It;++It){It->SetActorTickEnabled(false);if(auto* AI=Cast<AAIController>(It->GetController()))AI->StopMovement();It->GetCharacterMovement()->DisableMovement();}
        if(!Player || Now<4)return;
        if(Player->CanAct() || Player->CanMove() || GS->AddKey(TEXT("Invalid"),TEXT("fixture"))){Finish(false,TEXT("Lobby accepted gameplay actions"));return;}++Checks;
        GS->StartRound(EWDDifficulty::Normal,false);GS->IntroRemaining=.01f;Stage(TEXT("StoryToPlay"));
    }
    else if(Phase==TEXT("StoryToPlay")&&GS->Phase==EWDRoundPhase::Playing){
        if(!Player->CanMove()){Finish(false,TEXT("Story did not release controls"));return;}++Checks;
        const int32 Bottles=Player->Bottles;Player->ThrowBottle();Player->ThrowBottle();
        if(Player->Bottles!=Bottles-1){Finish(false,TEXT("Bottle cooldown failed"));return;}++Checks;
        // Unlock the furniture for a complete interaction sweep. The separate campaign earns every key.
        for(TActorIterator<AWDInteractable> It(GetWorld());It;++It)if(It->Kind==EWDInteraction::Key)GS->AddKey(It->GrantsKey,TEXT("Audit fixture"));
        for(TActorIterator<AWDInteractable> It(GetWorld());It;++It)if(It->Kind==EWDInteraction::Wardrobe || It->Kind==EWDInteraction::Bed)AuditObjects.Add(*It);
        if(AuditObjects.Num()!=20){Finish(false,TEXT("Expected sixteen wardrobes and four beds"));return;}
        Point=0;Stage(TEXT("NextHide"));
    }
    else if(Phase==TEXT("NextHide")&&Now-At>.55){
        if(Point==AuditObjects.Num()){
            AuditObjects.Reset();for(TActorIterator<AWDInteractable> It(GetWorld());It;++It)
                if(It->Kind==EWDInteraction::Drawer || (It->Kind==EWDInteraction::Door && !It->bBlocksPassage))AuditObjects.Add(*It);
            if(AuditObjects.Num()<98){Finish(false,TEXT("Searchable furniture missing"));return;}
            Point=0;Stage(TEXT("NextContainer"));return;
        }
        Current=AuditObjects[Point++];Place(Current->GetActorTransform().TransformPosition(FVector(0,-180,92)));
        if(!Use(Current))return;if(Player->HidingSpot!=Current){Finish(false,TEXT("Hiding entry failed"));return;}Stage(TEXT("ExitHide"));
    }
    else if(Phase==TEXT("ExitHide")&&Now-At>.6){
        Player->Use();++Checks;if(Player->HidingSpot || Current->Occupant){Finish(false,TEXT("Hiding exit blocked"));return;}Stage(TEXT("NextHide"));
    }
    else if(Phase==TEXT("NextContainer")&&Now-At>.55){
        if(Point==AuditObjects.Num()){Point=0;Stage(TEXT("NextDoor"));return;}
        Current=AuditObjects[Point++];const FVector P=Current->GetActorLocation();const float Floor=FMath::RoundToFloat((P.Z-100)/320)*320;
        Place(FVector(P.X,P.Y-120,Floor+92));if(!Use(Current))return;
        if(!Current->bOpen){Finish(false,TEXT("Search container did not open"));return;}Stage(TEXT("CloseContainer"));
    }
    else if(Phase==TEXT("CloseContainer")&&Now-At>.65){
        if(!Use(Current))return;if(Current->bOpen){Finish(false,TEXT("Search container did not close"));return;}Stage(TEXT("NextContainer"));
    }
    else if(Phase==TEXT("NextDoor")&&Now-At>.55){
        TArray<AWDInteractable*> Doors;for(TActorIterator<AWDInteractable> It(GetWorld());It;++It)if(It->Kind==EWDInteraction::Door && It->bBlocksPassage)Doors.Add(*It);
        if(Point==Doors.Num()){Stage(TEXT("CaughtHide"));return;}
        Current=Doors[Point++];const FVector P=Current->GetActorLocation();Place(FVector(P.X<0?-65:65,P.Y+85,P.Z+92));
        if(!Use(Current))return;if(!Current->bOpen){Finish(false,TEXT("Room door did not open"));return;}Stage(TEXT("CloseRoomDoor"));
    }
    else if(Phase==TEXT("CloseRoomDoor")&&Now-At>.75){
        const FVector P=Current->GetActorLocation();Place(FVector(P.X<0?-108:108,P.Y+85,P.Z+92));
        if(!Use(Current))return;if(Current->bOpen){Finish(false,TEXT("Room door did not close"));return;}Stage(TEXT("NextDoor"));
    }
    else if(Phase==TEXT("CaughtHide")&&Now-At>.6){
        Current=Find(TEXT("Hide_Parlour"));Place(Current->GetActorLocation()+FVector(0,-180,92));if(!Use(Current))return;
        auto* Blocker=GetWorld()->SpawnActor<AActor>();auto* Box=NewObject<UBoxComponent>(Blocker);Blocker->SetRootComponent(Box);Box->SetBoxExtent(FVector(70,70,110));Box->SetCollisionProfileName(TEXT("BlockAll"));Box->RegisterComponent();Blocker->SetActorLocation(Current->GetActorTransform().TransformPosition(Current->ExitOffset));
        Player->LeaveHiding();if(!Player->HidingSpot){Blocker->Destroy();Finish(false,TEXT("Player exited through a blocking object"));return;}++Checks;
        Player->Catch();Blocker->Destroy();
        if(!Player->bCaught || Player->HidingSpot || Current->Occupant){Finish(false,TEXT("Caught survivor left occupied hiding furniture"));return;}++Checks;Stage(TEXT("LastSurvivor"));
    }
    else if(Phase==TEXT("LastSurvivor")&&Now-At>1){
        const int32 Bottles=Player->Bottles;Player->ThrowBottle();Player->SetSprint(true);Player->ToggleCrouch();
        if(GS->Phase!=EWDRoundPhase::Lost || Player->CanMove() || Player->bSprinting || Player->Bottles!=Bottles || Player->GetCharacterMovement()->MaxWalkSpeedCrouched!=0){Finish(false,TEXT("Loss did not freeze gameplay"));return;}++Checks;
        Finish(true,FString::Printf(TEXT("Lobby and intro guards, bottle cooldown, all 20 hiding entries/exits, %d searchable containers and 16 room doors open/close, blocked hiding exit, caught occupancy cleanup and last-survivor loss"),AuditObjects.Num()));
    }
}
