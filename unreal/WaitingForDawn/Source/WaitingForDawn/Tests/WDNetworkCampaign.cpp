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
    Key=Find(TEXT("Key_Nursery"));auto* Hide=Find(TEXT("Hide_Parlour"));
    if(!Key||!Key->Container||!Hide)return;
    if(int32(Now)%5==0 && int32(Now)!=int32(Now-GetWorld()->GetDeltaSeconds()))
        UE_LOG(LogTemp,Display,TEXT("WD_NET_DIAGNOSTIC server=%d phase=%s container_open=%d key_available=%d key_collected=%d actors=%d"),Server,*Phase,Key->Container->bOpen,Key->IsAvailable(),Key->bCollected,GS->PlayerArray.Num());
    if(Server){
        if(Phase!=TEXT("FourPlayers"))GS->Phase=EWDRoundPhase::Playing;
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
        if(Phase==TEXT("FourPlayers")&&Now-At>6&&!GS->bRoundEnded){GS->AddKey(TEXT("Ignition"),TEXT("Host"));GS->bGarageUnlocked=true;GS->EndRound(true,TEXT("Network ending fixture"));}
        if(Phase==TEXT("FourPlayers")&&Now-At>16){if(Hide->Occupant){Finish(false,TEXT("Disconnected player still occupies wardrobe"));return;}Checks=NetworkMax;Finish(true,FString::Printf(TEXT("%d separate processes; server validates remote drawer pickup, hiding and disconnect cleanup"),NetworkMax));}
        return;
    }
    for(TActorIterator<AWDCharacter>It(GetWorld());It;++It)if(It->IsLocallyControlled())Player=*It;
    if(!Player||!Player->GetController())return;
    for(TActorIterator<AWDGhost>It(GetWorld());It;++It)Ghost=*It;
    auto* OpenedDoor=Find(TEXT("Door_Study"));
    const bool ThreatReplicated=Ghost&&Ghost->bCeilingCrawling&&Ghost->bOpeningDoor&&OpenedDoor&&OpenedDoor->bOpen&&OpenedDoor->bGhostOpened;
    int32 Observer=0;FParse::Value(FCommandLine::Get(),TEXT("WDObserver="),Observer);
    if(Observer){
        if(GS->TeamKeys.Contains(TEXT("Nursery"))&&Key->bCollected&&Key->Container->bOpen&&Hide->Occupant&&ThreatReplicated){SawHidden=true;}
        if(SawHidden&&GS->PlayerArray.Num()>=4&&Phase==TEXT("Startup")){Checks=GS->PlayerArray.Num();Stage(TEXT("ObserverReady"));}
        if(Phase==TEXT("ObserverReady")&&Now-At>10&&GS->Phase==EWDRoundPhase::Escaped&&GS->bGarageUnlocked&&GS->TeamKeys.Contains(TEXT("Ignition")))Finish(true,Observer==2?TEXT("Late join received inventory, collected key, open drawer, occupied hiding spot and replicated escape ending"):TEXT("Observer received shared pickup, hiding and escape state"));
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
        if(NetworkMax>=Expected&&ThreatReplicated){Stage(TEXT("NetFourSeen"));}
    }
    else if(Phase==TEXT("NetFourSeen")&&Now-At>5){Checks=NetworkMax;Finish(true,FString::Printf(TEXT("Remote use, pickup and hiding replicated; %d players joined"),NetworkMax));}
}
