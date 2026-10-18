#include "WDHUD.h"
#include "WDCharacter.h"
#include "WDInteractable.h"
#include "WDGhost.h"
#include "WDGameState.h"
#include "WDPlayerController.h"
#include "Engine/Canvas.h"
#include "Engine/Texture2D.h"
#include "EngineUtils.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"

void AWDHUD::Ring(float X,float Y,float R,FLinearColor C,float T)
{ for(int I=0;I<48;++I){float A=I*2*PI/48,B=(I+1)*2*PI/48;DrawLine(X+FMath::Cos(A)*R,Y+FMath::Sin(A)*R,X+FMath::Cos(B)*R,Y+FMath::Sin(B)*R,C,T);} }
void AWDHUD::Icon(FName N,float X,float Y,float S)
{
    auto L=[&](float A,float B,float C,float D){DrawLine(X+A*S,Y+B*S,X+C*S,Y+D*S,FLinearColor(.9,.86,.73),2*S);};
    if(N==TEXT("Menu")){for(int I=-1;I<2;++I)L(-12,I*7,12,I*7);}
    else if(N==TEXT("Light")){L(-8,-14,8,-14);L(-8,-14,-4,14);L(8,-14,4,14);L(-4,14,4,14);L(-7,-6,7,-6);}
    else if(N==TEXT("Bag")){L(-12,-9,12,-9);L(-12,-9,-12,14);L(12,-9,12,14);L(-12,14,12,14);L(-5,-9,-5,-16);L(5,-9,5,-16);L(-5,-16,5,-16);L(-7,3,7,3);}
    else if(N==TEXT("Journal")){L(-11,-15,11,-15);L(-11,-15,-11,15);L(11,-15,11,15);L(-11,15,11,15);for(int I=-1;I<2;++I)L(-6,I*7,6,I*7);}
    else if(N==TEXT("Crouch")||N==TEXT("Run")){Ring(X+3*S,Y-12*S,4*S,FLinearColor(.9,.86,.73),2*S);L(2,-7,-4,2);L(-4,2,8,5);L(8,5,2,15);L(-4,2,-11,12);L(-11,12,-4,16);L(0,-4,11,-1);L(0,-4,-12,-5);}
    else if(N==TEXT("Throw")){Ring(X+9*S,Y-12*S,4*S,FLinearColor(.9,.86,.73),2*S);L(-12,12,-4,-2);L(-4,-2,6,-2);L(-12,12,4,12);L(4,12,10,1);}
    else{L(-10,12,-14,0);L(-14,0,-9,-3);L(-9,-3,-4,4);L(-4,4,-4,-14);L(-4,-14,1,-14);L(1,-14,1,-2);L(1,-2,12,-2);L(12,-2,10,12);L(10,12,-10,12);}
}
void AWDHUD::Button(FName N,const FString& Text,float X,float Y,float W,float H,bool Circle)
{
    float S=Canvas->ClipY/720;
    if(Circle){Ring(X+W/2,Y+H/2,W/2,FLinearColor(.8,.75,.6,.8),2*S);Icon(N,X+W/2,Y+H/2,S);}
    else{DrawRect(FLinearColor(.055,.045,.04,.92),X,Y,W,H);DrawLine(X,Y+H,X+W,Y+H,FLinearColor(.55,.39,.23),2*S);DrawText(Text,FLinearColor(.95,.88,.73),X+18*S,Y+H*.25,nullptr,1.35*S);}
    Buttons.Add({N,FVector2D(X,Y),FVector2D(W,H)});AddHitBox(FVector2D(X,Y),FVector2D(W,H),N,true);
}
bool AWDHUD::ClickAt(FVector2D P)
{
    for(int I=Buttons.Num()-1;I>=0;--I){const auto& B=Buttons[I];if(P.X>=B.Pos.X&&P.Y>=B.Pos.Y&&P.X<=B.Pos.X+B.Size.X&&P.Y<=B.Pos.Y+B.Size.Y){NotifyHitBoxClick(B.Name);return true;}}return false;
}
void AWDHUD::DrawHUD()
{
    Super::DrawHUD();Buttons.Reset();auto* PC=Cast<AWDPlayerController>(PlayerOwner);if(!Canvas||!PC)return;
    // Use viewport coordinates for both touch and drawing. Unreal's automatic
    // canvas safe-zone translation otherwise leaves a visible strip and offsets taps.
    Canvas->PopSafeZoneTransform();
    struct FRestoreSafeZone{UCanvas* C;~FRestoreSafeZone(){C->ApplySafeZoneTransform();}} Restore{Canvas};
    auto* P=Cast<AWDCharacter>(PC->GetPawn());auto* GS=GetWorld()->GetGameState<AWDGameState>();if(!P||!GS)return;
    float W=Canvas->ClipX,H=Canvas->ClipY,S=H/720;bool Host=GetNetMode()!=NM_Client;
    if(PC->ScareUntil>GetWorld()->GetTimeSeconds()){DrawRect(FLinearColor(.24,0,0,.24),0,0,W,H);return;}
    auto Text=[&](const FString& T,float X,float Y,float Size=1.3f){DrawText(T,FLinearColor(.92,.86,.73),X,Y,nullptr,Size*S);};
    if(GS->Phase==EWDRoundPhase::Lobby){
        if(!TitleTexture)TitleTexture=LoadObject<UTexture2D>(nullptr,TEXT("/Game/Imported/UI_manor.UI_manor"));
        if(TitleTexture)DrawTexture(TitleTexture,0,0,W,H,0,0,1,1,FLinearColor(.55,.55,.6),BLEND_Opaque);
        DrawRect(FLinearColor(.015,.01,.02,.55),0,0,W,H);
        Text(TEXT("WAITING\nFOR DAWN"),W*.08,H*.15,4);Text(TEXT("One house. One night. Leave together."),W*.08,H*.39);
        const TCHAR* Levels[]={TEXT("EASY"),TEXT("NORMAL"),TEXT("HARD"),TEXT("EXTREME")};
        Button(TEXT("Difficulty"),FString(TEXT("DIFFICULTY: "))+Levels[PC->SelectedDifficulty],W*.08,H*.47,340*S,46*S);
        Button(TEXT("Play"),Host?TEXT("PLAY"):TEXT("WAITING FOR HOST"),W*.08,H*.56,340*S,52*S);
        Button(TEXT("Friends"),TEXT("JOIN WITH FRIENDS"),W*.08,H*.66,340*S,52*S);
        Button(TEXT("Exit"),TEXT("EXIT"),W*.08,H*.76,340*S,48*S);
        Text(FString::Printf(TEXT("%d / 4 SURVIVORS"),GS->PlayerArray.Num()),W*.72,H*.88,1);
        if(!PC->LastNetworkError.IsEmpty())Text(PC->LastNetworkError.Left(95),W*.08,H*.92,1);return;
    }
    if(GS->Phase==EWDRoundPhase::Introduction){
        DrawRect(FLinearColor(0,0,0,.75),0,H*.73,W,H*.27);
        const TCHAR* C[]={TEXT("We were students on a midnight trip.\nThe house at the end of the road should have been empty."),TEXT("The front door slammed behind us. No handle would turn.\nUpstairs, we found the keeper. He had been dead for days."),TEXT("Eleanor once lived here with her children.\nAfter the fire, she kept every door locked, waiting for them to return."),TEXT("A letter lay in the keeper's hand.\nFind a way to the garage. Start the car. Leave before dawn.")};
        Text(C[FMath::Clamp(int32((36-GS->IntroRemaining)/9),0,3)],W*.13,H*.78,1.5);
        Button(TEXT("Skip"),Host?TEXT("SKIP STORY"):TEXT("HOST CONTROLS SKIP"),W-250*S,24*S,225*S,46*S);return;
    }
    if(GS->Phase==EWDRoundPhase::Escaped && GS->EndingAge<8){Text(TEXT("The road is yours. The house falls silent."),W*.27,H*.84,1.6);return;}
    if(GS->bRoundEnded||P->bCaught){
        DrawRect(FLinearColor(.02,.01,.015,.91),0,0,W,H);
        Text(GS->Phase==EWDRoundPhase::Escaped?TEXT("YOU REACHED THE DAWN"):P->bCaught?TEXT("SHE FOUND YOU"):TEXT("THE HOUSE KEPT YOU"),W*.18,H*.3,2.8);
        Text(GS->bRoundEnded?GS->EndingReason:TEXT("Your friends are still inside. Their escape is your last hope."),W*.14,H*.45,1.2);
        if(Host&&GS->bRoundEnded)Button(TEXT("Retry"),TEXT("TRY AGAIN - SKIP STORY"),W*.33,H*.6,360*S,55*S);
        Button(TEXT("Home"),TEXT("RETURN HOME"),W*.33,H*.72,360*S,55*S);return;
    }
    if(P->HidingSpot){bool Bed=P->HidingSpot->Kind==EWDInteraction::Bed;DrawRect(FLinearColor(.008,.005,.003,.98),0,0,W,H*(Bed?.30:.38));DrawRect(FLinearColor(.008,.005,.003,.98),0,H*(Bed?.65:.58),W,H);Text(TEXT("Stay quiet. Use the hand to leave."),W*.32,H*.68,1);}
    int Time=FMath::CeilToInt(GS->SecondsRemaining);Text(FString::Printf(TEXT("DAWN  %02d:%02d"),Time/60,Time%60),W*.45,22*S);
    Button(TEXT("Menu"),TEXT(""),22*S,18*S,56*S,56*S,true);Button(TEXT("Journal"),TEXT(""),22*S,88*S,56*S,56*S,true);Button(TEXT("Light"),TEXT(""),22*S,158*S,56*S,56*S,true);Button(TEXT("Bag"),TEXT(""),W-82*S,18*S,56*S,56*S,true);
    if(!P->RidingCar){
    Ring(135*S,H-130*S,77*S,FLinearColor(.7,.68,.6,.5),3*S);Ring((135+PC->Stick.X*48)*S,H-130*S+PC->Stick.Y*48*S,30*S,FLinearColor(.9,.87,.75,.8),4*S);
    Button(TEXT("Use"),TEXT(""),W-115*S,H-245*S,80*S,80*S,true);Button(TEXT("Crouch"),TEXT(""),W-205*S,H-150*S,64*S,64*S,true);Button(TEXT("Run"),TEXT(""),W-110*S,H-140*S,64*S,64*S,true);Button(TEXT("Throw"),TEXT(""),W-205*S,H-245*S,64*S,64*S,true);
    DrawRect(FLinearColor(.035,.035,.035,.8),W*.32,H-35*S,W*.34,8*S);DrawRect(FLinearColor(.27,.55,.27),W*.32,H-35*S,W*.34*P->Stamina/100,8*S);Ring(W/2,H/2,2*S,FLinearColor(.85,.82,.7));
    }else{
        DrawRect(FLinearColor(.015,.015,.015,.85),W*.20,H*.69,W*.60,H*.27);
        Text(FString::Printf(TEXT("IN THE CAR  |  SEAT %d  |  %d / %d ABOARD"),P->CarSeat+1,P->RidingCar->BoardedCount(),P->RidingCar->SurvivorsCount()),W*.24,H*.72,1.4);
        Text(P->RidingCar->CarStatus().ToString(),W*.24,H*.78,1.1);
        Button(TEXT("Use"),PLATFORM_ANDROID?TEXT("START ENGINE"):TEXT("START ENGINE [E]"),W*.25,H*.85,290*S,48*S);
        Button(TEXT("LeaveCar"),PLATFORM_ANDROID?TEXT("GET OUT"):TEXT("GET OUT [Q]"),W*.56,H*.85,230*S,48*S);
    }
    if(auto* T=P->FindInteractionTarget();T&&!P->HidingSpot){DrawRect(FLinearColor(0,0,0,.65),W*.3,H*.61,W*.4,35*S);Text(T->GetPrompt().ToString(),W*.32,H*.62,1.25);}
    if(GS->GetServerWorldTimeSeconds()-GS->DiscoveryAt<7)Text(GS->LastDiscovery,W*.26,65*S,1.15);
    float Danger=0;for(TActorIterator<AWDGhost>It(GetWorld());It;++It)Danger=FMath::Max(Danger,It->ThreatAt(P->GetActorLocation()));
    // A slow translucent wash covers the whole view without hiding her silhouette.
    if(Danger>0){const float Pulse=.82f+.18f*FMath::Sin(GetWorld()->GetTimeSeconds()*3.f);
        DrawRect(FLinearColor(.45,.015,.02,Danger*.20f*Pulse),0,0,W,H);
        for(int I=0;I<12;++I){const float A=Danger*.018f*(1-I/12.f);const float X=W*.012f*I,Y=H*.018f*I;
            DrawRect(FLinearColor(.5,0,0,A),X,Y,W-2*X,H*.018f);DrawRect(FLinearColor(.5,0,0,A),X,H-Y-H*.018f,W-2*X,H*.018f);}
    }
    if(PC->bBagOpen){
        DrawRect(FLinearColor(.025,.022,.018,.96),W*.25,H*.18,W*.5,H*.6);Text(TEXT("SHARED BAG"),W*.29,H*.22,2);
        FString Items=FString::Printf(TEXT("Bottles: %d\n\n"),P->Bottles);if(GS->TeamKeys.IsEmpty())Items+=TEXT("No keys found yet.");
        for(int I=0;I<GS->TeamKeys.Num();++I)Items+=GS->TeamKeys[I].ToString()+(I%3==2?TEXT("\n"):TEXT("     "));
        Text(Items,W*.29,H*.33);Button(TEXT("CloseBag"),TEXT("CLOSE BAG"),W*.4,H*.66,220*S,45*S);
    }
    if(P->bJournalOpen){
        if(!PaperTexture)PaperTexture=LoadObject<UTexture2D>(nullptr,TEXT("/Game/Imported/UI_parchment.UI_parchment"));
        if(PaperTexture)DrawTexture(PaperTexture,W*.2,H*.1,W*.6,H*.8,0,0,1,1,FLinearColor::White,BLEND_Opaque);else DrawRect(FLinearColor(.65,.57,.4),W*.2,H*.1,W*.6,H*.8);
        DrawText(TEXT("THE KEEPER'S LAST LETTER"),FLinearColor(.15,.07,.035),W*.25,H*.17,nullptr,1.8*S);
        FString Letter=GS->bLetterFound?TEXT("She still lays a place for the children.\nFollow what she loved, not what she says.\n\nThe nursery, pantry and study each guard a promise.\nThree promises open the old cellar cabinet.\nThe fire below remembers the rooms above.\n\nShe hears a drawer as clearly as a scream.\nClose the room door. Hide before she sees you.\nIf she watches you hide, she will remember.\n\nTwo final teeth remain: one wakes the garage,\none wakes the car. Leave together before dawn."):TEXT("No letter has been found.\nThe keeper lies upstairs.");
        DrawText(Letter,FLinearColor(.16,.085,.04),W*.25,H*.28,nullptr,1.22*S);Button(TEXT("CloseJournal"),TEXT("FOLD LETTER"),W*.4,H*.79,230*S,44*S);
    }
    if(PC->bMenuOpen){DrawRect(FLinearColor(.02,.015,.02,.96),W*.28,H*.2,W*.44,H*.6);Text(TEXT("THE NIGHT CONTINUES"),W*.33,H*.25,1.7);Button(TEXT("Resume"),TEXT("RESUME"),W*.34,H*.37,310*S,55*S);Button(TEXT("ReadJournal"),TEXT("READ LETTER"),W*.34,H*.49,310*S,55*S);Button(TEXT("Home"),TEXT("LEAVE HOUSE"),W*.34,H*.61,310*S,55*S);}
}
void AWDHUD::NotifyHitBoxClick(FName N)
{
    Super::NotifyHitBoxClick(N);auto* PC=Cast<AWDPlayerController>(PlayerOwner);if(!PC)return;auto* P=Cast<AWDCharacter>(PC->GetPawn());if(!P)return;
    if(N==TEXT("CloseBag"))N=TEXT("Bag");
    if(N==TEXT("CloseJournal")||N==TEXT("ReadJournal"))N=TEXT("Journal");
    if(N==TEXT("Resume"))N=TEXT("Menu");
    if(N==TEXT("LeaveCar")){P->LeaveCar();return;}
    if(N==TEXT("Play"))PC->StartGame(PC->SelectedDifficulty,false);else if(N==TEXT("Difficulty") && GetNetMode()!=NM_Client)PC->SelectedDifficulty=(PC->SelectedDifficulty+1)%4;
    else if(N==TEXT("Friends"))PC->OpenJoin();else if(N==TEXT("Skip"))PC->SkipStory();else if(N==TEXT("Exit"))UKismetSystemLibrary::QuitGame(this,PC,EQuitPreference::Quit,false);
    else if(N==TEXT("Home"))UGameplayStatics::OpenLevel(this,TEXT("House"));else if(N==TEXT("Retry"))PC->Retry();else if(N==TEXT("Use"))P->Use();else if(N==TEXT("Light"))P->ToggleLight();else if(N==TEXT("Crouch"))P->ToggleCrouch();else if(N==TEXT("Run"))P->SetSprint(!P->bSprinting);else if(N==TEXT("Throw"))P->ThrowBottle();else if(N==TEXT("Menu"))PC->ToggleMenu();else if(N==TEXT("Bag"))PC->ToggleBag();else if(N==TEXT("Journal"))PC->ToggleJournal();
}
