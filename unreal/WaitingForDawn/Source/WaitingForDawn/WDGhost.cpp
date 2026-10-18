#include "WDGhost.h"
#include "WDCharacter.h"
#include "WDInteractable.h"
#include "WDGameState.h"
#include "AIController.h"
#include "Components/CapsuleComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Animation/AnimSequence.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/GameplayStatics.h"
#include "EngineUtils.h"
#include "Net/UnrealNetwork.h"
AWDGhost::AWDGhost(){
 bReplicates=true;bAlwaysRelevant=true;SetNetUpdateFrequency(30);PrimaryActorTick.bCanEverTick=true;
 GetCapsuleComponent()->InitCapsuleSize(32,88);AIControllerClass=AAIController::StaticClass();AutoPossessAI=EAutoPossessAI::PlacedInWorldOrSpawned;
 GetCharacterMovement()->MaxWalkSpeed=155;GetCharacterMovement()->MaxStepHeight=35;GetCharacterMovement()->bOrientRotationToMovement=true;bUseControllerRotationYaw=false;
}
void AWDGhost::BeginPlay(){
 Super::BeginPlay();MeshHome=GetMesh()->GetRelativeLocation();MeshRotation=GetMesh()->GetRelativeRotation();
 GetMesh()->VisibilityBasedAnimTickOption=EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;GetMesh()->SetCollisionEnabled(ECollisionEnabled::NoCollision);
 for(int I=0;I<GetMesh()->GetNumBones();++I)if(GetMesh()->GetBoneName(I).ToString().Contains(TEXT("head"),ESearchCase::IgnoreCase)){HeadBone=GetMesh()->GetBoneName(I);break;}
 if(!AttackAnimation)AttackAnimation=LoadObject<UAnimSequence>(nullptr,TEXT("/Game/Imported/SK_Eleanor_Anim_Armature_attack2_Armature.SK_Eleanor_Anim_Armature_attack2_Armature"));
}
FVector AWDGhost::GetFaceLocation()const{if(!HeadBone.IsNone())return GetMesh()->GetSocketLocation(HeadBone)+FVector(0,0,5);const auto B=GetMesh()->Bounds;return B.Origin+FVector(0,0,B.BoxExtent.Z*.72f);}
float AWDGhost::ThreatAt(FVector P)const{if(FMath::Abs(P.Z-GetActorLocation().Z)>220)return 0;return FMath::Clamp(1-FVector::Dist2D(P,GetActorLocation())/1400.f,0.f,1.f);}
bool AWDGhost::HasAttackWindow(double Now,double FirstSeen,double Started,float Distance){return Started>0&&Now-FirstSeen>=2.2&&Now-Started>=.95&&Distance<145;}
double AWDGhost::ReactionDeadline(EWDGhostState Current,double Existing,double Now,float Delay){if(Current==EWDGhostState::Chasing||Current==EWDGhostState::Investigating)return Now;return Current==EWDGhostState::Listening?FMath::Min(Existing,Now+Delay):Now+Delay;}
void AWDGhost::HearNoise(FVector Location,float Delay){
 if(!HasAuthority())return;const double Now=GetWorld()->GetTimeSeconds();NoiseGoal=Location;RememberUntil=Now+90;ReactAt=ReactionDeadline(State,ReactAt,Now,Delay);
 if(State!=EWDGhostState::Chasing&&State!=EWDGhostState::Investigating)State=EWDGhostState::Listening;NextRouteAt=0;
 if(Now>=NextWarningAt){Warn();NextWarningAt=Now+12;}ForceNetUpdate();
}
void AWDGhost::Warn_Implementation(){if(WarningSound)UGameplayStatics::PlaySoundAtLocation(this,WarningSound,GetActorLocation(),.7f);}
void AWDGhost::UpdateAppearance(float D){
 const auto* GS=GetWorld()->GetGameState<AWDGameState>();const float T=GS?GS->GetServerWorldTimeSeconds():GetWorld()->GetTimeSeconds();
 CeilingBlend=FMath::FInterpConstantTo(CeilingBlend,bCeilingCrawling?1.f:0.f,D,1.2f);
 // Floor navigation remains authoritative. The body crawls beneath the traced hall ceiling;
 // it must descend completely before starting an attack. No wall-crossing teleports.
 GetMesh()->SetRelativeRotation(FQuat::Slerp(MeshRotation.Quaternion(),(FRotator(0,0,90)+MeshRotation).Quaternion(),CeilingBlend));
 GetMesh()->SetRelativeLocation(MeshHome+FVector(0,0,9+FMath::Sin(T*1.8f)*3));
 if(CeilingBlend>0){FHitResult Hit;FCollisionQueryParams Q(SCENE_QUERY_STAT(GhostCeiling),false,this);
  if(GetWorld()->LineTraceSingleByChannel(Hit,GetActorLocation(),GetActorLocation()+FVector(0,0,280),ECC_Visibility,Q)){
   const auto B=GetMesh()->CalcBounds(GetMesh()->GetComponentTransform());const float Raise=Hit.ImpactPoint.Z-14-(B.Origin.Z+B.BoxExtent.Z);GetMesh()->AddWorldOffset(FVector(0,0,Raise*CeilingBlend));}}
 UAnimSequence* Desired=bAttacking&&AttackAnimation?AttackAnimation.Get():GetVelocity().SizeSquared2D()<25?IdleAnimation.Get():State==EWDGhostState::Chasing?RunAnimation.Get():WalkAnimation.Get();
 if(Desired&&Desired!=ActiveAnimation){ActiveAnimation=Desired;GetMesh()->PlayAnimation(Desired,!bAttacking);}if(Desired)GetMesh()->SetPlayRate(bCeilingCrawling?.7f:1.f);
}
bool AWDGhost::TryDoor(FVector Goal){
 AWDInteractable* Best=nullptr;float Nearest=210;
 for(TActorIterator<AWDInteractable>It(GetWorld());It;++It){if(!It->CanGhostOpen())continue;const FVector P=It->GetInteractionPoint();const float Dist=FVector::Dist2D(GetActorLocation(),P);
  if(Dist>=Nearest||FMath::Abs(P.Z-GetActorLocation().Z)>150)continue;
  if(FVector::DotProduct((P-GetActorLocation()).GetSafeNormal2D(),(Goal-GetActorLocation()).GetSafeNormal2D())<-.1f)continue;
  FHitResult Hit;FCollisionQueryParams Q(SCENE_QUERY_STAT(GhostDoor),false,this);Q.AddIgnoredActor(*It);if(GetWorld()->LineTraceSingleByChannel(Hit,GetActorLocation(),P,ECC_Visibility,Q))continue;
  Best=*It;Nearest=Dist;}
 if(!Best)return false;PendingDoor=Best;bOpeningDoor=true;bCeilingCrawling=false;DoorOpenAt=GetWorld()->GetTimeSeconds()+2.2;Best->RattleForGhost();ForceNetUpdate();return true;
}
void AWDGhost::Tick(float D){
 Super::Tick(D);auto* GS=GetWorld()->GetGameState<AWDGameState>();SetActorHiddenInGame(GS&&(GS->Phase==EWDRoundPhase::Lobby||GS->Phase==EWDRoundPhase::Introduction));UpdateAppearance(D);
 if(!HasAuthority())return;auto* AI=Cast<AAIController>(GetController());if(!AI||!GS)return;
 if(GS->bRoundEnded||GS->Phase!=EWDRoundPhase::Playing){AI->StopMovement();return;}const double Now=GetWorld()->GetTimeSeconds();
 if(Now<CapturePauseUntil){AI->StopMovement();return;}if(CapturePauseUntil>0){CapturePauseUntil=0;bAttacking=false;}
 if(PendingDoor.IsValid()){AI->StopMovement();if(Now<DoorOpenAt)return;PendingDoor->OpenForGhost();PendingDoor.Reset();bOpeningDoor=false;DoorPauseUntil=Now+1.8;ForceNetUpdate();}
 if(Now<DoorPauseUntil){AI->StopMovement();return;}
 AWDCharacter* Seen=nullptr;float Nearest=1800;
 for(TActorIterator<AWDCharacter>It(GetWorld());It;++It){const float Dist=FVector::Dist(GetActorLocation(),It->GetActorLocation());const FVector Dir=(It->GetActorLocation()-GetActorLocation()).GetSafeNormal();
  if(It->IsPlayerControlled()&&!It->bCaught&&!It->HidingSpot&&!It->RidingCar&&Dist<Nearest&&(Dist<180||FVector::DotProduct(GetActorForwardVector(),Dir)>.1f)&&AI->LineOfSightTo(*It)){Seen=*It;Nearest=Dist;}}
 if(Seen){if(ChaseTarget.Get()!=Seen||State!=EWDGhostState::Chasing){SpottedAt=Now;AttackStarted=0;Warn();NextWarningAt=Now+12;}
  ChaseTarget=Seen;LastSeen=Seen->GetActorLocation();SeenAt=Now;State=EWDGhostState::Chasing;bCeilingCrawling=false;}
 const bool WitnessedHide=ChaseTarget.IsValid()&&ChaseTarget->HidingSpot&&Now-SeenAt<1.2;
 if(State==EWDGhostState::Chasing&&ChaseTarget.IsValid()&&!ChaseTarget->bCaught&&!ChaseTarget->RidingCar){
  const float Range=FVector::Dist(GetActorLocation(),ChaseTarget->GetActorLocation());const bool CanReach=(Seen==ChaseTarget.Get()||WitnessedHide)&&Range<145&&CeilingBlend<.05;
  // A readable alert, followed by a cancellable attack. Sprinting and a closed door can save you.
  if(Now-SpottedAt<1.8||CeilingBlend>.05){AI->StopMovement();return;}
  if(CanReach){AI->StopMovement();SetActorRotation(FRotator(0,(LastSeen-GetActorLocation()).Rotation().Yaw,0));
   if(AttackStarted<=0){AttackStarted=Now;bAttacking=true;ForceNetUpdate();}
   if(HasAttackWindow(Now,SpottedAt,AttackStarted,Range)){ChaseTarget->Catch();CapturePauseUntil=Now+2.4;AttackStarted=0;ForceNetUpdate();}return;}
  AttackStarted=0;bAttacking=false;
 }
 if(State==EWDGhostState::Chasing&&(!ChaseTarget.IsValid()||ChaseTarget->bCaught||ChaseTarget->RidingCar||Now-SeenAt>3.5)){
  NoiseGoal=LastSeen;RememberUntil=Now+30;State=EWDGhostState::Investigating;ChaseTarget.Reset();AttackStarted=0;bAttacking=false;}
 if(State==EWDGhostState::Listening){AI->StopMovement();if(Now<ReactAt)return;State=EWDGhostState::Investigating;NextRouteAt=0;}
 if(State==EWDGhostState::Investigating){if(FVector::Dist2D(GetActorLocation(),NoiseGoal)<110&&FMath::Abs(GetActorLocation().Z-NoiseGoal.Z)<180){State=EWDGhostState::Searching;SearchUntil=Now+6;}else if(Now>RememberUntil)State=EWDGhostState::Patrol;}
 if(State==EWDGhostState::Searching){AI->StopMovement();if(Now<SearchUntil){AddActorWorldRotation(FRotator(0,D*28,0));return;}State=EWDGhostState::Patrol;}
 const FVector P=GetActorLocation();const bool InHall=FMath::Abs(P.X)<95&&P.Y>-1050&&P.Y<450;
 if(State==EWDGhostState::Patrol&&InHall&&Now>NextHauntAt){bCeilingCrawling=true;HauntUntil=Now+5;NextHauntAt=Now+33;ForceNetUpdate();}
 if((!InHall||State!=EWDGhostState::Patrol||Now>HauntUntil)&&bCeilingCrawling){bCeilingCrawling=false;ForceNetUpdate();}
 if(Now<NextRouteAt)return;NextRouteAt=Now+.35;FVector Destination=NoiseGoal;
 if(State==EWDGhostState::Chasing){Destination=LastSeen;GetCharacterMovement()->MaxWalkSpeed=GS->Difficulty==EWDDifficulty::Easy?285:GS->Difficulty==EWDDifficulty::Extreme?365:325;}
 else{GetCharacterMovement()->MaxWalkSpeed=bCeilingCrawling?105:155;if(State==EWDGhostState::Patrol){if(PatrolPoints.IsEmpty())return;if(FVector::Dist(GetActorLocation(),PatrolPoints[PatrolIndex])<125)PatrolIndex=(PatrolIndex+1)%PatrolPoints.Num();Destination=PatrolPoints[PatrolIndex];}}
 if(TryDoor(Destination)){AI->StopMovement();return;}AI->MoveToLocation(Destination,45,true,true,true,false,nullptr,true);
}
void AWDGhost::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps)const{
 Super::GetLifetimeReplicatedProps(OutLifetimeProps);DOREPLIFETIME(AWDGhost,State);DOREPLIFETIME(AWDGhost,NoiseGoal);DOREPLIFETIME(AWDGhost,bAttacking);DOREPLIFETIME(AWDGhost,bCeilingCrawling);DOREPLIFETIME(AWDGhost,bOpeningDoor);
}
