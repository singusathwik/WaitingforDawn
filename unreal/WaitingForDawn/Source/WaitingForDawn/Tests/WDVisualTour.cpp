#include "Tests/WDCampaignProbe.h"
#include "WDCharacter.h"
#include "WDGhost.h"
#include "WDGameState.h"
#include "WDPlayerController.h"
#include "EngineUtils.h"
#include "Engine/GameViewportClient.h"
#include "Misc/Paths.h"
#include "AIController.h"
#include "GameFramework/CharacterMovementComponent.h"
void AWDCampaignProbe::TickTour()
{
    const double Now=GetWorld()->GetTimeSeconds();auto* GS=GetWorld()->GetGameState<AWDGameState>();
    if(Phase==TEXT("Startup")){
        for(TActorIterator<AWDCharacter>It(GetWorld());It;++It)if(It->IsLocallyControlled())Player=*It;
        for(TActorIterator<AWDGhost>It(GetWorld());It;++It){Ghost=*It;It->SetActorTickEnabled(false);if(auto* AI=Cast<AAIController>(It->GetController()))AI->StopMovement();It->GetCharacterMovement()->DisableMovement();It->SetActorHiddenInGame(true);}
        if(!Player||!Ghost||Now<5)return;Stage(TEXT("Home"));return;
    }
    auto* PC=Cast<AWDPlayerController>(Player->GetController());if(!PC)return;
    if(Phase==TEXT("Home")&&Now-At>2){PC->StartGame(1,false);Stage(TEXT("StoryExterior"));}
    else if(Phase==TEXT("StoryExterior")&&Now-At>3){GS->IntroRemaining=17;Stage(TEXT("StoryKeeper"));}
    else if(Phase==TEXT("StoryKeeper")&&Now-At>3){PC->SkipStory();Stage(TEXT("BeginTour"));}
    else if((Phase==TEXT("BeginTour")||Phase.StartsWith(TEXT("Tour")))&&Now-At>3){
        const FVector Places[]={FVector(0,-950,92),FVector(-500,-800,92),FVector(-450,100,92),FVector(-400,-720,412),FVector(-450,-700,732),FVector(-400,-720,-228),FVector(420,-450,92)};
        const FVector Targets[]={FVector(0,250,160),FVector(-1000,-600,140),FVector(-1000,370,140),FVector(-950,-500,455),FVector(-1100,-650,770),FVector(-1000,-600,-240),FVector(1070,-800,100)};
        const TCHAR* Names[]={TEXT("TourHall"),TEXT("TourParlour"),TEXT("TourKitchen"),TEXT("TourNursery"),TEXT("TourBedroom"),TEXT("TourBasementTorch"),TEXT("TourGarage")};
        if(Point==7){Player->bJournalOpen=true;GS->bLetterFound=true;Stage(TEXT("LetterArt"));return;}
        Place(Places[Point]);PC->SetControlRotation((Targets[Point]-Player->GetPawnViewLocation()).Rotation());
        if(Point==5&&!Player->bLightOn)Player->ToggleLight();
        if(Point==6&&Player->bLightOn)Player->ToggleLight();Stage(Names[Point++]);
    }
    else if(Phase==TEXT("LetterArt")&&Now-At>3){Player->bJournalOpen=false;PC->bBagOpen=true;GS->AddKey(TEXT("Nursery"),TEXT("Survivor"));Stage(TEXT("BagArt"));}
    else if(Phase==TEXT("BagArt")&&Now-At>3){PC->bBagOpen=false;Place(FVector(0,-850,92));Ghost->SetActorLocation(FVector(0,-600,90));Ghost->SetActorRotation(FRotator(0,-90,0));Ghost->SetActorHiddenInGame(false);PC->SetControlRotation(FRotator(0,90,0));if(!Player->bLightOn)Player->ToggleLight();Stage(TEXT("GhostArt"));}
    else if(Phase==TEXT("GhostArt")&&Now-At>3){Player->Catch();Stage(TEXT("CaptureScare"));}
    else if(Phase==TEXT("CaptureScare")&&Now-At>2){if(GS->Phase!=EWDRoundPhase::Lost){Finish(false,TEXT("Last survivor capture did not end round"));return;}Stage(TEXT("LossScreen"));}
    else if(Phase==TEXT("LossScreen")&&Now-At>2){Finish(true,TEXT("Rendered home, skippable introduction, seven house views, journal, bag, ghost and capture loss"));}
    if(Now-At>.8&&Now-At<1.0)FScreenshotRequest::RequestScreenshot(FPaths::ProjectSavedDir()/TEXT("Validation")/(Phase+TEXT(".png")),true,false);
}
