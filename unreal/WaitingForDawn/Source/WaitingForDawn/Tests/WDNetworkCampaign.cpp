#include "Tests/WDCampaignProbe.h"
#include "WDCharacter.h"
#include "WDGhost.h"
#include "WDInteractable.h"
#include "WDGameState.h"
#include "AIController.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "EngineUtils.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
void AWDCampaignProbe::TickNetwork(bool Server)
{
    const double Now=GetWorld()->GetTimeSeconds();auto* GS=GetWorld()->GetGameState<AWDGameState>();
    int32 Expected=4;FParse::Value(FCommandLine::Get(),TEXT("WDExpectedPlayers="),Expected);Expected=FMath::Clamp(Expected,2,4);
    if(Now-At>80){Finish(false,TEXT("House network phase timed out"));return;}
    NetworkMax=FMath::Max(NetworkMax,GS->PlayerArray.Num());
    Key=Find(TEXT("Key_Nursery"));auto* Hide=Find(TEXT("Hide_Parlour"));auto* Car=Find(TEXT("EscapeCar"));
    if(!Key||!Key->Container||!Hide)return;
    if(int32(Now)%5==0 && int32(Now)!=int32(Now-GetWorld()->GetDeltaSeconds()))
        UE_LOG(LogTemp,Display,TEXT("WD_NET_DIAGNOSTIC server=%d phase=%s container_open=%d key_available=%d key_collected=%d actors=%d"),Server,*Phase,Key->Container->bOpen,Key->IsAvailable(),Key->bCollected,GS->PlayerArray.Num());
    if(Server){
        if(!GS->bRoundEnded)GS->Phase=EWDRoundPhase::Playing;
        for(TActorIterator<AWDGhost>It(GetWorld());It;++It){It->SetActorTickEnabled(false);if(auto* AI=Cast<AAIController>(It->GetController()))AI->StopMovement();It->GetCharacterMovement()->DisableMovement();
            if(!It->bCeilingCrawling){It->bCeilingCrawling=true;It->bOpeningDoor=true;It->ForceNetUpdate();}}
        if(auto* Door=Find(TEXT("Door_Study"));Door&&!Door->bOpen)Door->OpenForGhost();
        for(TActorIterator<AWDCharacter>It(GetWorld());It;++It)if(It->IsPlayerControlled()&&!It->IsLocallyControlled()&&!Player)Player=*It;
        if(GS->TeamKeys.Contains(TEXT("Nursery"))&&Phase==TEXT("Startup")){
            if(GS->TeamKeys.Num()!=1){Finish(false,TEXT("Duplicate key award on server"));return;}
            Place(Hide->GetActorLocation()+FVector(0,-180,92));Player->ForceNetUpdate();Stage(TEXT("WaitHiding"));
        }
        if(Hide->Occupant){SawHidden=true;}
        if(Phase==TEXT("WaitHiding")&&SawHidden&&NetworkMax>=Expected){Stage(TEXT("FourPlayers"));}
        if(Phase==TEXT("FourPlayers")&&Now-At>5&&!Hide->Occupant){
            GS->AddKey(TEXT("Ignition"),TEXT("Fixture"));GS->AddKey(TEXT("Garage"),TEXT("Fixture"));
            for(TActorIterator<AWDCharacter> It(GetWorld());It;++It)if(It->IsLocallyControlled())Player=*It;
            auto* Garage=Find(TEXT("GarageLock"));Place(FVector(920,-1050,92));if(!Use(Garage))return;
            if(!GS->bGarageUnlocked){Finish(false,TEXT("Host garage interaction failed"));return;}Stage(TEXT("GarageReady"));
        }
        if(Phase==TEXT("GarageReady")&&Now-At>1){
            int32 I=0;for(TActorIterator<AWDCharacter> It(GetWorld());It;++It)if(It->IsPlayerControlled()){
                It->GetCharacterMovement()->StopMovementImmediately();It->SetActorLocation(FVector(850,-800+(I++)*40,92),false,nullptr,ETeleportType::TeleportPhysics);It->ForceNetUpdate();}
            if(!Use(Car))return;Car->StartCar(Player);
            if(GS->bRoundEnded){Finish(false,TEXT("Host abandoned unboarded teammates"));return;}
            Checks+=2;Stage(TEXT("Boarding"));
        }
        if(Phase==TEXT("Boarding")&&Now-At>10 && Car->BoardedCount()==Expected){
            TSet<int32> Seats;for(TActorIterator<AWDCharacter> It(GetWorld());It;++It)if(It->RidingCar==Car)Seats.Add(It->CarSeat);
            if(Seats.Num()!=Expected || !Car->AllSurvivorsAboard()){Finish(false,TEXT("Seats duplicated or team count wrong"));return;}
            GhostStart=Car->GetActorLocation();Player->Use();if(!GS->bRoundEnded){Finish(false,TEXT("Full team could not start engine"));return;}Checks+=Expected;Stage(TEXT("TeamDeparture"));
        }
        if(Phase==TEXT("TeamDeparture")&&Now-At>14){
            if(Hide->Occupant || Car->BoardedCount()!=1 || Car->GetActorLocation().Y>GhostStart.Y-1200){Finish(false,TEXT("Departure or disconnected passenger cleanup failed"));return;}
            ++Checks;Finish(true,FString::Printf(TEXT("%d processes: remote pickup, late join, hiding, actual boarding, unique seats, no abandonment, engine and moving car, passenger disconnect cleanup"),NetworkMax));}
        return;
    }
    for(TActorIterator<AWDCharacter>It(GetWorld());It;++It)if(It->IsLocallyControlled())Player=*It;
    if(!Player||!Player->GetController())return;
    for(TActorIterator<AWDGhost>It(GetWorld());It;++It)Ghost=*It;
    auto* OpenedDoor=Find(TEXT("Door_Study"));
    const bool ThreatReplicated=Ghost&&Ghost->bCeilingCrawling&&Ghost->bOpeningDoor&&OpenedDoor&&OpenedDoor->bOpen&&OpenedDoor->bGhostOpened;
    int32 Observer=0;FParse::Value(FCommandLine::Get(),TEXT("WDObserver="),Observer);
    if(Car && GS->TeamKeys.Contains(TEXT("Ignition")) && SawHidden){
        if(Phase!=TEXT("BoardAim") && Phase!=TEXT("BoardWait") && Phase!=TEXT("SeatExit") && Phase!=TEXT("ReboardAim") && Phase!=TEXT("Passenger") && Phase!=TEXT("ClientDeparture") && !Player->HidingSpot && FVector::Dist2D(Player->GetActorLocation(),Car->GetActorLocation())<450){
            Player->GetController()->SetControlRotation((Car->GetInteractionPoint()-Player->GetPawnViewLocation()).Rotation());Stage(TEXT("BoardAim"));
        }
        if(Phase==TEXT("BoardAim")&&Now-At>1){if(!Use(Car))return;Stage(TEXT("BoardWait"));}
        if(Phase==TEXT("BoardWait")&&Player->RidingCar==Car){
            if(Observer){Stage(TEXT("Passenger"));}else{Player->LeaveCar();Stage(TEXT("SeatExit"));}
        }
        if(Phase==TEXT("SeatExit")&&!Player->RidingCar&&Now-At>1){++Checks;Player->GetController()->SetControlRotation((Car->GetInteractionPoint()-Player->GetPawnViewLocation()).Rotation());Stage(TEXT("ReboardAim"));}
        if(Phase==TEXT("ReboardAim")&&Now-At>1){if(!Use(Car))return;Stage(TEXT("Passenger"));}
        if(Phase==TEXT("Passenger")&&Car->BoardedCount()==Expected && GS->Phase==EWDRoundPhase::Escaped){
            if(!Player->RidingCar || Player->CarSeat<0){Finish(false,TEXT("Ending without replicated passenger"));return;}GhostStart=Car->GetActorLocation();Stage(TEXT("ClientDeparture"));
        }
        if(Phase==TEXT("ClientDeparture")&&Now-At>3){
            if(Car->GetActorLocation().Y>GhostStart.Y-500 || FVector::Dist(Player->GetActorLocation(),Car->SeatLocation(Player->CarSeat))>20){Finish(false,TEXT("Car and passenger departure did not replicate"));return;}
            Checks+=Expected;Finish(true,Observer?TEXT("Late joining observer received shared state, boarded a unique seat and escaped in the replicated moving car"):TEXT("Remote drawer and key, hiding, exit, car boarding, disembark/reboard and synchronized team departure"));
        }
        return;
    }
    if(Observer){
        if(GS->TeamKeys.Contains(TEXT("Nursery"))&&Key->bCollected&&Key->Container->bOpen&&Hide->Occupant&&ThreatReplicated){SawHidden=true;}
        if(SawHidden&&GS->PlayerArray.Num()>=Expected&&Phase==TEXT("Startup")){Checks=GS->PlayerArray.Num();Stage(TEXT("ObserverReady"));}
        return;
    }
    if(Phase==TEXT("Startup")){
        if(NetworkMax<2||FVector::Dist2D(Player->GetActorLocation(),FVector(-828,-1150,92))>35)return;
        Current=Key->Container;Player->GetController()->SetControlRotation((Current->GetInteractionPoint()-Player->GetPawnViewLocation()).Rotation());Stage(TEXT("NetAimDrawer"));
    }
    else if(Phase==TEXT("NetAimDrawer")&&Now-At>.7){if(!Use(Current))return;Stage(TEXT("NetWaitDrawer"));}
    else if(Phase==TEXT("NetWaitDrawer")&&Key->IsAvailable()){
        Player->GetController()->SetControlRotation((Key->GetInteractionPoint()-Player->GetPawnViewLocation()).Rotation());Stage(TEXT("NetAimKey"));
    }
    else if(Phase==TEXT("NetAimKey")&&Now-At>.7){if(!Use(Key))return;Stage(TEXT("NetWaitInventory"));}
    else if(Phase==TEXT("NetWaitInventory")&&GS->TeamKeys.Contains(TEXT("Nursery"))&&Key->bCollected){
        if(FVector::Dist2D(Player->GetActorLocation(),Hide->GetActorLocation()+FVector(0,-180,92))<30){Current=Hide;Player->GetController()->SetControlRotation((Hide->GetInteractionPoint()-Player->GetPawnViewLocation()).Rotation());Stage(TEXT("NetAimHide"));}
    }
    else if(Phase==TEXT("NetAimHide")&&Now-At>.8){if(!Use(Current))return;Stage(TEXT("NetWaitHiding"));}
    else if(Phase==TEXT("NetWaitHiding")&&Player->HidingSpot==Hide&&Hide->Occupant==Player){
        if(NetworkMax>=Expected&&ThreatReplicated){SawHidden=true;Stage(TEXT("NetFourSeen"));}
    }
    else if(Phase==TEXT("NetFourSeen")&&Now-At>4){Checks=NetworkMax;Player->Use();Stage(TEXT("HideExit"));}
}
