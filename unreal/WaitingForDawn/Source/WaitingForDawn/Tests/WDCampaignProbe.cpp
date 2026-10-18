#include "Tests/WDCampaignProbe.h"
#include "WDCharacter.h"
#include "WDGhost.h"
#include "WDInteractable.h"
#include "WDGameState.h"
#include "WDPlayerController.h"
#include "Components/StaticMeshComponent.h"
#include "Components/SceneComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "AIController.h"
#include "EngineUtils.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "HAL/FileManager.h"
#include "Engine/GameViewportClient.h"
#include "NavigationSystem.h"
#include "NavigationPath.h"

AWDCampaignProbe::AWDCampaignProbe(){PrimaryActorTick.bCanEverTick=true;}
void AWDCampaignProbe::Stage(const FString& N){Phase=N;At=GetWorld()->GetTimeSeconds();UE_LOG(LogTemp,Display,TEXT("WD_CAMPAIGN %s"),*N);if(FParse::Param(FCommandLine::Get(),TEXT("WDProbeScreenshots")) || (FParse::Param(FCommandLine::Get(),TEXT("WDCarScreenshots")) && (N==TEXT("Seated")||N==TEXT("Departure")||N==TEXT("Passenger")||N==TEXT("ClientDeparture"))))FScreenshotRequest::RequestScreenshot(FPaths::ProjectSavedDir()/TEXT("Validation")/(N+TEXT(".png")),true,false);}
void AWDCampaignProbe::Finish(bool Pass,const FString& Why)
{
    Done=true;FString R=FString::Printf(TEXT("{\"passed\":%s,\"phase\":\"%s\",\"detail\":\"%s\",\"checks\":%d,\"keys\":%d,\"stair_flights_both_directions\":%d,\"fall_recoveries\":%d}"),Pass?TEXT("true"):TEXT("false"),*Phase,*Why,Checks,KeyIndex,Flight,Player?Player->FallRecoveryCount:-1);
    FString File=TEXT("campaign");
    if(FParse::Param(FCommandLine::Get(),TEXT("WDHouseNetServer")))File=TEXT("house-net-server");
    if(FParse::Param(FCommandLine::Get(),TEXT("WDThreatTest")))File=TEXT("threat-encounter");
    if(FParse::Param(FCommandLine::Get(),TEXT("WDAuditTest")))File=TEXT("component-audit");
    if(FParse::Param(FCommandLine::Get(),TEXT("WDCarOnly")))File=TEXT("car-visual");
    if(FParse::Param(FCommandLine::Get(),TEXT("WDHouseNetClient"))){int32 Observer=0;FParse::Value(FCommandLine::Get(),TEXT("WDObserver="),Observer);File=FString::Printf(TEXT("house-net-client%d"),Observer);}
    IFileManager::Get().MakeDirectory(*(FPaths::ProjectSavedDir()/TEXT("Validation")),true);FFileHelper::SaveStringToFile(R,*(FPaths::ProjectSavedDir()/TEXT("Validation")/(File+TEXT(".json"))));
    UE_LOG(LogTemp,Display,TEXT("WD_CAMPAIGN_RESULT %s"),*R);if(Player)UE_LOG(LogTemp,Display,TEXT("Position %s"),*Player->GetActorLocation().ToString());FPlatformMisc::RequestExitWithStatus(false,Pass?0:1);
}
AWDInteractable* AWDCampaignProbe::Find(const FString& Tag){for(TActorIterator<AWDInteractable>It(GetWorld());It;++It)if(It->ActorHasTag(FName(Tag)))return *It;return nullptr;}
void AWDCampaignProbe::Place(FVector P){Player->GetCharacterMovement()->StopMovementImmediately();Player->SetActorLocation(P,false,nullptr,ETeleportType::TeleportPhysics);}
bool AWDCampaignProbe::Use(AWDInteractable* T)
{
    if(!T){Finish(false,TEXT("Missing interactable"));return false;}
    Player->GetController()->SetControlRotation((T->GetInteractionPoint()-Player->GetPawnViewLocation()).Rotation());
    if(Player->FindInteractionTarget()!=T){
        auto* Selected=Player->FindInteractionTarget();FHitResult Hit;FCollisionQueryParams Params(SCENE_QUERY_STAT(ProbeSelection),false,Player);Params.AddIgnoredActor(T);
        GetWorld()->LineTraceSingleByChannel(Hit,Player->GetPawnViewLocation(),T->GetInteractionPoint(),ECC_Visibility,Params);
        UE_LOG(LogTemp,Error,TEXT("Target unavailable %s point %s selected %s blocker %s eye %s"),*T->DisplayName.ToString(),*T->GetInteractionPoint().ToString(),Selected?*Selected->DisplayName.ToString():TEXT("none"),Hit.GetActor()?*Hit.GetActor()->GetName():TEXT("none"),*Player->GetPawnViewLocation().ToString());Finish(false,TEXT("Use prompt did not select intended object"));return false;}
    Player->Use();++Checks;return true;
}
void AWDCampaignProbe::StartFlight()
{
    const float Z=(Flight-1)*320.f,Y=Flight==1?700.f:1050.f;
    Place(FVector(-1340,Y,Z+92));Route.Reset();
    for(int I=0;I<20;I+=3)Route.Add(FVector(-1226+I*30,Y,Z+(I+1)*16));
    Route.Add(FVector(-550,Y,Z+320));Route.Add(FVector(-400,Y,Z+320));
    for(int I=Route.Num()-2;I>=0;--I){const FVector P=Route[I];Route.Add(P);}
    Route.Add(FVector(-1340,Y,Z));Point=0;Stage(TEXT("StairFlight")+FString::FromInt(Flight));
}
void AWDCampaignProbe::Tick(float D)
{
    Super::Tick(D);if(Done)return;double Now=GetWorld()->GetTimeSeconds();auto* GS=GetWorld()->GetGameState<AWDGameState>();if(!GS)return;
    // Assertions sample the completed passenger update, not a partially ticked frame.
    if(Player)AddTickPrerequisiteActor(Player);
    if(FParse::Param(FCommandLine::Get(),TEXT("WDVisualTour"))){TickTour();return;}
    if(FParse::Param(FCommandLine::Get(),TEXT("WDThreatTest"))){TickThreat();return;}
    if(FParse::Param(FCommandLine::Get(),TEXT("WDAuditTest"))){TickAudit();return;}
    if(FParse::Param(FCommandLine::Get(),TEXT("WDHouseNetServer"))){TickNetwork(true);return;}
    if(FParse::Param(FCommandLine::Get(),TEXT("WDHouseNetClient"))){TickNetwork(false);return;}
    if(Now-At>100){Finish(false,TEXT("Stage timed out"));return;}
    if(FParse::Param(FCommandLine::Get(),TEXT("WDCarScreenshots")) && (Phase==TEXT("Seated")||Phase==TEXT("Departure")) && Now-At>1 && LastThreatScreenshot!=Phase){
        LastThreatScreenshot=Phase;FScreenshotRequest::RequestScreenshot(FPaths::ProjectSavedDir()/TEXT("Validation")/(Phase+TEXT("-settled.png")),true,false);
        UE_LOG(LogTemp,Display,TEXT("WD_CAR_VIEW pawn=%s view=%s rot=%s car_bounds=%s"),*Player->GetActorLocation().ToString(),*Player->GetPawnViewLocation().ToString(),*Player->GetViewRotation().ToString(),*Current->Mesh->Bounds.ToString());
    }
    if(Phase==TEXT("Startup")){
        for(TActorIterator<AWDCharacter>It(GetWorld());It;++It)if(It->IsLocallyControlled())Player=*It;
        for(TActorIterator<AWDGhost>It(GetWorld());It;++It){Ghost=*It;Ghost->SetActorTickEnabled(false);if(auto* AI=Cast<AAIController>(Ghost->GetController()))AI->StopMovement();Ghost->GetCharacterMovement()->DisableMovement();}
        if(!Player||!Ghost||Now<5)return;
        GS->StartRound(EWDDifficulty::Easy,true);GS->Phase=EWDRoundPhase::Playing;Player->ToggleLight();
        if(FParse::Param(FCommandLine::Get(),TEXT("WDCarOnly"))){for(TActorIterator<AWDInteractable> It(GetWorld());It;++It)if(It->Kind==EWDInteraction::Key)GS->AddKey(It->GrantsKey,TEXT("Visual fixture"));Stage(TEXT("CarLocked"));return;}
        if(FParse::Param(FCommandLine::Get(),TEXT("WDNavOnly"))){Stage(TEXT("Navigation"));return;}
        // A locked door must reject use before any key has been collected.
        Current=Find(TEXT("Door_Nursery"));Place(FVector(-65,-730,412));
        if(!Use(Current))return;if(Current->bOpen){Finish(false,TEXT("Locked nursery opened without key"));return;}StartFlight();
    }
    else if(Phase.StartsWith(TEXT("StairFlight"))){
        if(Player->FallRecoveryCount){Finish(false,TEXT("Stair required fall recovery"));return;}
        FVector Delta=Route[Point]-Player->GetActorLocation();
        if(Delta.Size2D()<14){if(FMath::Abs(Player->GetActorLocation().Z-90-Route[Point].Z)>40){Finish(false,TEXT("Wrong stair floor"));return;}++Point;if(Point==Route.Num()){++Flight;++Checks;if(Flight<3)StartFlight();else Stage(TEXT("NextKey"));return;}Delta=Route[Point]-Player->GetActorLocation();}
        Delta.Z=0;Player->AddMovementInput(Delta.GetSafeNormal());
    }
    else if(Phase==TEXT("NextKey")&&Now-At>.7){
        const TCHAR* Names[]={TEXT("Nursery"),TEXT("Pantry"),TEXT("Study"),TEXT("Cellar"),TEXT("Boiler"),TEXT("Bedroom"),TEXT("Attic"),TEXT("Safe"),TEXT("Archive"),TEXT("Workshop"),TEXT("Garage"),TEXT("Ignition")};
        if(KeyIndex==12){Stage(TEXT("HideStart"));return;}
        Key=Find(FString(TEXT("Key_"))+Names[KeyIndex]);if(!Key||!Key->Container){Finish(false,TEXT("Missing key/container"));return;}Current=Key->Container;
        FVector Pos=Current->GetActorLocation();const float Floor=FMath::FloorToFloat((Pos.Z+5)/320)*320;
        Place(FVector(Pos.X,Pos.Y-120,Floor+92));if(!Use(Current))return;if(!Current->bOpen){Finish(false,TEXT("Progression container stayed locked"));return;}Stage(TEXT("InspectKey")+FString::FromInt(KeyIndex));
    }
    else if(Phase.StartsWith(TEXT("InspectKey"))&&Now-At>.8){
        if(Key->IsHidden()||!Key->IsAvailable()){Finish(false,TEXT("Key not visible after opening"));return;}
        if(!Use(Key))return;if(!Key->bCollected||!GS->TeamKeys.Contains(Key->GrantsKey)){Finish(false,TEXT("Key not stored"));return;}
        if(GS->AddKey(Key->GrantsKey,TEXT("duplicate"))){Finish(false,TEXT("Duplicate inventory award"));return;}
        ++KeyIndex;Stage(TEXT("NextKey"));
    }
    else if(Phase==TEXT("HideStart")&&Now-At>.7){Current=Find(TEXT("Hide_Parlour"));Place(Current->GetActorLocation()+FVector(0,-180,92));if(!Use(Current))return;if(Player->HidingSpot!=Current||Current->Occupant!=Player){Finish(false,TEXT("Wardrobe occupancy failed"));return;}Stage(TEXT("WardrobePeek"));}
    else if(Phase==TEXT("WardrobePeek")&&Now-At>1){Player->Use();if(Player->HidingSpot){Finish(false,TEXT("Cannot leave wardrobe"));return;}Stage(TEXT("BedStart"));}
    else if(Phase==TEXT("BedStart")&&Now-At>.7){Current=Find(TEXT("Under_bed_Eleanor bedroom"));Place(Current->GetActorLocation()+FVector(0,-180,92));if(!Use(Current))return;if(Player->HidingSpot!=Current){Finish(false,TEXT("Under-bed hiding failed"));return;}Stage(TEXT("UnderBedPeek"));}
    else if(Phase==TEXT("UnderBedPeek")&&Now-At>1){Player->Use();if(Player->HidingSpot){Finish(false,TEXT("Cannot leave bed"));return;}Current=Find(TEXT("KeeperLetter"));Place(Current->GetActorLocation()+FVector(0,-130,62));Stage(TEXT("Letter"));}
    else if(Phase==TEXT("Letter")&&Now-At>.7){if(!Use(Current))return;if(!GS->bLetterFound||!Player->bJournalOpen){Finish(false,TEXT("Letter not shared"));return;}Player->bJournalOpen=false;Stage(TEXT("Navigation"));}
    else if(Phase==TEXT("Navigation")&&Now-At>.7){
        if(FParse::Param(FCommandLine::Get(),TEXT("WDNavOnly"))){
            const FVector Points[]={FVector(0,500,90),FVector(-400,700,90),FVector(-1340,700,90),FVector(-1196,700,122),FVector(-956,700,250),FVector(-716,700,378),FVector(-550,700,410),FVector(0,500,410)};
            for(int I=1;I<8;++I){auto* P=UNavigationSystemV1::FindPathToLocationSynchronously(this,Points[I-1],Points[I],Player);UE_LOG(LogTemp,Display,TEXT("WD_NAV segment %d valid %d partial %d"),I,P?P->IsValid():false,P?P->IsPartial():true);if(P)for(auto V:P->PathPoints)UE_LOG(LogTemp,Display,TEXT("WD_NAV point %s"),*V.ToString());}
        }
        // Real nav paths between the hallway on every floor, independent of key teleports above.
        for(float Z:{-320.f,0.f,320.f,640.f}){auto* Path=UNavigationSystemV1::FindPathToLocationSynchronously(this,FVector(0,500,90),FVector(0,300,Z+90),Player);if(!Path||!Path->IsValid()||Path->IsPartial()){UE_LOG(LogTemp,Error,TEXT("Navigation floor %.0f valid %d partial %d points %d"),Z,Path?Path->IsValid():false,Path?Path->IsPartial():false,Path?Path->PathPoints.Num():0);Finish(false,TEXT("Navigation cannot connect all four storeys"));return;}++Checks;}
        Current=Find(TEXT("Door_Parlour"));
        if(Current->bOpen){Finish(false,TEXT("Door fixture unexpectedly open"));return;}
        Ghost->SetActorLocation(FVector(0,350,90));GhostStart=Ghost->GetActorLocation();Ghost->State=EWDGhostState::Patrol;Ghost->SetActorTickEnabled(true);Ghost->GetCharacterMovement()->SetMovementMode(MOVE_Walking);
        GS->EmitNoise(FVector(-450,-730,80),8000,TEXT("Campaign room noise"));Place(FVector(0,-900,732));Stage(TEXT("ClosedDoorNoise"));
    }
    else if(Phase==TEXT("ClosedDoorNoise")){
        if(!Current->bOpen&&Ghost->GetActorLocation().X < -190){Finish(false,TEXT("Ghost crossed shut door without opening it"));return;}
        if(Current->bOpen){if(!Current->bGhostOpened||Now-At<6){Finish(false,TEXT("Ghost door opened without warning delay"));return;}++Checks;Stage(TEXT("NoisePursuit"));}
        else if(Now-At>40){Finish(false,TEXT("Ghost did not open the noisy room door"));return;}
    }
    else if(Phase==TEXT("NoisePursuit")){
        if(Ghost->State==EWDGhostState::Searching&&FVector::Dist(GhostStart,Ghost->GetActorLocation())>700&&Ghost->GetActorLocation().X < -230){Ghost->SetActorTickEnabled(false);if(auto* AI=Cast<AAIController>(Ghost->GetController()))AI->StopMovement();Ghost->GetCharacterMovement()->DisableMovement();++Checks;Point=0;Stage(TEXT("DoorAccess"));}
        else if(Now-At>45){UE_LOG(LogTemp,Error,TEXT("Ghost stopped at %s state %d goal %s"),*Ghost->GetActorLocation().ToString(),int32(Ghost->State),*Ghost->NoiseGoal.ToString());Finish(false,TEXT("Ghost did not reach door noise"));return;}
    }
    else if(Phase==TEXT("DoorAccess")&&Now-At>.7){
        const TCHAR* Names[]={TEXT("Coal cellar"),TEXT("Boiler room"),TEXT("Workshop"),TEXT("Wine store"),TEXT("Parlour"),TEXT("Kitchen"),TEXT("Garage"),TEXT("Study"),TEXT("Nursery"),TEXT("Playroom"),TEXT("Schoolroom"),TEXT("Music room"),TEXT("Eleanor bedroom"),TEXT("Attic bedroom"),TEXT("Guest bedroom"),TEXT("Archive")};
        if(Point==16){Stage(TEXT("KeyReachability"));return;}
        Current=Find(FString(TEXT("Door_"))+Names[Point++]);if(!Current){Finish(false,TEXT("Missing room door"));return;}
        FVector P=Current->GetActorLocation();Place(FVector(P.X<0?-65:65,P.Y+85,P.Z+92));
        if(!Current->bOpen){if(!Use(Current))return;if(!Current->bOpen){Finish(false,TEXT("Earned key did not unlock room"));return;}}
        Stage(TEXT("DoorAccess"));
    }
    else if(Phase==TEXT("KeyReachability")&&Now-At>1){
        for(TActorIterator<AWDInteractable>It(GetWorld());It;++It)if(It->Kind==EWDInteraction::Key&&It->Container){
            const FVector P=It->Container->GetActorLocation();const float Floor=FMath::FloorToFloat((P.Z+5)/320)*320;
            auto* Path=UNavigationSystemV1::FindPathToLocationSynchronously(this,FVector(0,-900,90),FVector(P.X,P.Y-120,Floor+90),Player);
            if(!Path||!Path->IsValid()||Path->IsPartial()){UE_LOG(LogTemp,Error,TEXT("Unreachable key %s"),*It->GrantsKey.ToString());Finish(false,TEXT("A key approach is disconnected from the house"));return;}++Checks;
        }
        Stage(TEXT("CarLocked"));
    }
    else if(Phase==TEXT("CarLocked")&&Now-At>.7){Current=Find(TEXT("EscapeCar"));Place(FVector(850,-780,92));if(!Use(Current))return;if(Player->RidingCar!=Current || GS->bRoundEnded){Finish(false,TEXT("Boarding failed or won without starting"));return;}Stage(TEXT("CarLockedStart"));}
    else if(Phase==TEXT("CarLockedStart")&&Now-At>.7){Player->Use();++Checks;if(GS->bRoundEnded){Finish(false,TEXT("Car escaped through locked garage"));return;}Player->LeaveCar();++Checks;if(Player->RidingCar){Finish(false,TEXT("Cannot leave parked car"));return;}Stage(TEXT("Garage"));}
    else if(Phase==TEXT("Garage")&&Now-At>.7){Current=Find(TEXT("GarageLock"));Place(FVector(920,-1050,92));if(!Use(Current))return;if(!GS->bGarageUnlocked){Finish(false,TEXT("Garage lock failed"));return;}Stage(TEXT("Escape"));}
    else if(Phase==TEXT("Escape")&&Now-At>1){Current=Find(TEXT("EscapeCar"));Place(FVector(850,-780,92));if(!Use(Current))return;if(!Player->RidingCar || GS->bRoundEnded){Finish(false,TEXT("Reboarding failed or auto-started"));return;}Stage(TEXT("Seated"));}
    else if(Phase==TEXT("Seated")&&Now-At>2){
        if(FParse::Param(FCommandLine::Get(),TEXT("WDCarUI"))){Stage(TEXT("TouchGetOut"));return;}
        if(GS->TeamKeys.Num()!=12 || Current->BoardedCount()!=1 || !Current->AllSurvivorsAboard()){Finish(false,TEXT("Car passenger state invalid"));return;}
        FHitResult Obstacle;FCollisionQueryParams Q(SCENE_QUERY_STAT(CarRoad),false,Current);Q.AddIgnoredActor(Player);
        const FVector Start=Current->GetActorLocation()+FVector(0,0,90);
        if(GetWorld()->SweepSingleByChannel(Obstacle,Start,Start+FVector(0,-1700,0),FQuat::Identity,ECC_Visibility,FCollisionShape::MakeBox(FVector(112,248,77)),Q)){
            UE_LOG(LogTemp,Error,TEXT("WD_CAR_EXIT_BLOCKER %s at %s"),Obstacle.GetActor()?*Obstacle.GetActor()->GetName():TEXT("none"),*Obstacle.ImpactPoint.ToString());Finish(false,TEXT("Car departure path obstructed"));return;
        }++Checks;
        Player->SetSprint(true);Player->ToggleCrouch();++Checks;if(Player->bSprinting||Player->bIsCrouched){Finish(false,TEXT("Seated player can move"));return;}
        Player->Use();++Checks;if(GS->Phase!=EWDRoundPhase::Escaped){Finish(false,TEXT("Engine did not finish round"));return;}GhostStart=Current->GetActorLocation();Stage(TEXT("Departure"));
    }
    else if(Phase==TEXT("TouchGetOut")&&!Player->RidingCar){++Checks;Place(FVector(850,-780,92));Player->GetController()->SetControlRotation((Current->GetInteractionPoint()-Player->GetPawnViewLocation()).Rotation());Stage(TEXT("TouchBoard"));}
    else if(Phase==TEXT("TouchBoard")&&Player->RidingCar==Current){++Checks;Stage(TEXT("TouchStart"));}
    else if(Phase==TEXT("TouchStart")&&GS->Phase==EWDRoundPhase::Escaped){++Checks;GhostStart=Current->GetActorLocation();Stage(TEXT("Departure"));}
    else if(Phase==TEXT("Departure")&&Now-At>4){
        if(Current->GetActorLocation().Y>GhostStart.Y-750 || FVector::Dist(Player->GetActorLocation(),Current->SeatLocation(Player->CarSeat))>10){
            UE_LOG(LogTemp,Error,TEXT("WD_DEPARTURE_METRICS car=%s start=%s passenger=%s seat=%s lag=%.2f"),*Current->GetActorLocation().ToString(),*GhostStart.ToString(),*Player->GetActorLocation().ToString(),*Current->SeatLocation(Player->CarSeat).ToString(),FVector::Dist(Player->GetActorLocation(),Current->SeatLocation(Player->CarSeat)));
            Finish(false,TEXT("Car or passenger did not leave garage"));return;
        }
        Player->LeaveCar();++Checks;if(!Player->RidingCar){Finish(false,TEXT("Player left departing car"));return;}
        if(FParse::Param(FCommandLine::Get(),TEXT("WDCarUI"))){Stage(TEXT("WaitVictoryScreen"));return;}
        Finish(true,TEXT("Three stair flights both ways; twelve keys and locks; hiding; letter; all-floor paths; noise and doors; board, blocked start, exit, reboard, engine, passenger and car departure"));
    }
    else if(Phase==TEXT("WaitVictoryScreen")&&GS->EndingAge>8.5){Stage(TEXT("VictoryScreen"));}
    else if(Phase==TEXT("VictoryScreen")&&Now-At>3){Finish(true,TEXT("Actual Android Get Out, Board and Start Engine touches; car departure and victory screen"));}
}
