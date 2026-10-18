#include "WDInteractable.h"
#include "WDCharacter.h"
#include "WDGameState.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/PlayerState.h"
#include "EngineUtils.h"

int32 AWDInteractable::SurvivorsCount() const
{
    int32 Count=0;
    for(TActorIterator<AWDCharacter> It(GetWorld());It;++It)
        if(It->GetPlayerState() && !It->bCaught) ++Count;
    return Count;
}
int32 AWDInteractable::BoardedCount() const
{
    int32 Count=0;
    for(TActorIterator<AWDCharacter> It(GetWorld());It;++It)
        if(It->GetPlayerState() && !It->bCaught && It->RidingCar==this) ++Count;
    return Count;
}
bool AWDInteractable::AllSurvivorsAboard() const
{ return SurvivorsCount()>0 && BoardedCount()==SurvivorsCount(); }
FVector AWDInteractable::SeatLocation(int32 Seat) const
{
    // Actor faces +X; the two front seats precede the two rear seats.
    const FVector Seats[]={FVector(30,-42,72),FVector(30,42,72),FVector(-85,-42,72),FVector(-85,42,72)};
    return GetActorTransform().TransformPosition(Seats[FMath::Clamp(Seat,0,3)]);
}
FText AWDInteractable::CarStatus() const
{
    const auto* GS=GetWorld()->GetGameState<AWDGameState>();
    if(!GS || !GS->TeamKeys.Contains(TEXT("Ignition")))return FText::FromString(TEXT("Find the ignition key to start the engine."));
    if(!GS->CanEscape())return FText::FromString(TEXT("Unlock and open the garage before leaving."));
    for(TActorIterator<AWDInteractable> It(GetWorld());It;++It)
        if(It->Kind==EWDInteraction::Garage && !It->IsFullyOpen())return FText::FromString(TEXT("Wait for the garage door to finish opening."));
    if(!AllSurvivorsAboard())return FText::FromString(FString::Printf(TEXT("%d / %d aboard - wait for every surviving teammate."),BoardedCount(),SurvivorsCount()));
    return FText::FromString(TEXT("Everyone aboard. Start the engine to escape together."));
}
void AWDInteractable::Board(AWDCharacter* User)
{
    if(!HasAuthority() || Kind!=EWDInteraction::Car || !User || !User->GetPlayerState() || !User->CanAct() || User->RidingCar || User->HidingSpot || User->FindInteractionTarget()!=this)return;
    int32 Seat=0;
    for(;Seat<4;++Seat){bool Occupied=false;for(TActorIterator<AWDCharacter> It(GetWorld());It;++It)if(It->RidingCar==this && It->CarSeat==Seat)Occupied=true;if(!Occupied)break;}
    if(Seat==4)return;
    User->UnCrouch();User->CarSeat=Seat;User->RidingCar=this;User->bSprinting=false;
    User->GetCharacterMovement()->StopMovementImmediately();User->OnRep_Riding();
    User->SetActorLocation(SeatLocation(Seat),false,nullptr,ETeleportType::TeleportPhysics);
    if(auto* PC=Cast<APlayerController>(User->GetController())){PC->SetControlRotation(GetActorRotation());PC->ClientSetRotation(GetActorRotation(),true);}
    User->ForceNetUpdate();
    auto* GS=GetWorld()->GetGameState<AWDGameState>();
    GS->LastDiscovery=User->GetPlayerState()->GetPlayerName()+TEXT(" boarded the car. ")+FString::FromInt(BoardedCount())+TEXT(" / ")+FString::FromInt(SurvivorsCount())+TEXT(" aboard.");
    GS->DiscoveryAt=GS->GetServerWorldTimeSeconds();GS->ForceNetUpdate();
}
void AWDInteractable::StartCar(AWDCharacter* User)
{
    auto* GS=GetWorld()->GetGameState<AWDGameState>();
    if(!HasAuthority() || Kind!=EWDInteraction::Car || !User || !User->CanAct() || User->RidingCar!=this || !GS)return;
    bool Open=false;for(TActorIterator<AWDInteractable> It(GetWorld());It;++It)if(It->Kind==EWDInteraction::Garage && It->IsFullyOpen())Open=true;
    if(!GS->CanEscape() || !Open || !AllSurvivorsAboard()){
        GS->LastDiscovery=CarStatus().ToString();GS->DiscoveryAt=GS->GetServerWorldTimeSeconds();GS->ForceNetUpdate();return;
    }
    PlayInteractionSound();
    GS->EndRound(true,FString::Printf(TEXT("%d survivor%s escaped in the car before dawn. The house falls silent."),BoardedCount(),BoardedCount()==1?TEXT(""):TEXT("s")));
    ForceNetUpdate();
}
