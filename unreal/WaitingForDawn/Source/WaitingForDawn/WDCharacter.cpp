#include "WDCharacter.h"
#include "WDInteractable.h"
#include "WDGameState.h"
#include "WDGhost.h"
#include "WDPlayerController.h"
#include "Components/AudioComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Sound/SoundWave.h"
#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/SpotLightComponent.h"
#include "Components/InputComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "EngineUtils.h"
#include "Net/UnrealNetwork.h"
#include "Components/SkeletalMeshComponent.h"
#include "Animation/AnimSequence.h"
#include "UObject/ConstructorHelpers.h"

AWDCharacter::AWDCharacter()
{
    PrimaryActorTick.bCanEverTick = true;
    bReplicates = true;
    BaseEyeHeight = 68.f;
    GetCapsuleComponent()->InitCapsuleSize(34.f, 90.f);
    Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Eyes"));
    Camera->SetupAttachment(GetCapsuleComponent());
    Camera->SetRelativeLocation(FVector(0,0,68));
    Camera->bUsePawnControlRotation = true;
    Camera->bConstrainAspectRatio = false;
    Flashlight = CreateDefaultSubobject<USpotLightComponent>(TEXT("Torch"));
    Flashlight->SetupAttachment(Camera);
    Flashlight->SetRelativeLocation(FVector(10,12,-12));
    Flashlight->SetIntensityUnits(ELightUnits::Lumens);
    Flashlight->SetIntensity(12.f);
    Flashlight->SetAttenuationRadius(1800.f);
    Flashlight->SetInnerConeAngle(15.f);
    Flashlight->SetOuterConeAngle(32.f);
    Breath = CreateDefaultSubobject<UAudioComponent>(TEXT("UneasyBreathing"));
    Breath->SetupAttachment(Camera); Breath->bAutoActivate=false;
    GetCharacterMovement()->GetNavAgentPropertiesRef().bCanCrouch = true;
    GetCharacterMovement()->MaxStepHeight = 35.f;
    GetCharacterMovement()->MaxWalkSpeed = 240.f;
    GetCharacterMovement()->MaxWalkSpeedCrouched = 120.f;
    static ConstructorHelpers::FObjectFinder<USkeletalMesh> Body(TEXT("/Game/Characters/Mannequins/Meshes/SKM_Manny_Simple.SKM_Manny_Simple"));
    GetMesh()->SetSkeletalMeshAsset(Body.Object);GetMesh()->SetRelativeLocation(FVector(0,0,-90));GetMesh()->SetRelativeRotation(FRotator(0,-90,0));GetMesh()->SetOwnerNoSee(true);GetMesh()->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    static ConstructorHelpers::FObjectFinder<UAnimSequence> Idle(TEXT("/Game/Characters/Mannequins/Anims/Unarmed/MM_Idle.MM_Idle"));IdleAnimation=Idle.Object;
    static ConstructorHelpers::FObjectFinder<UAnimSequence> Walk(TEXT("/Game/Characters/Mannequins/Anims/Unarmed/Walk/MF_Unarmed_Walk_Fwd.MF_Unarmed_Walk_Fwd"));WalkAnimation=Walk.Object;
    static ConstructorHelpers::FObjectFinder<UAnimSequence> Run(TEXT("/Game/Characters/Mannequins/Anims/Unarmed/Jog/MF_Unarmed_Jog_Fwd.MF_Unarmed_Jog_Fwd"));RunAnimation=Run.Object;
    static ConstructorHelpers::FObjectFinder<UAnimSequence> Death(TEXT("/Game/Characters/Mannequins/Anims/Death/MM_Death_Front_01.MM_Death_Front_01"));DeathAnimation=Death.Object;
}
void AWDCharacter::BeginPlay()
{
    Super::BeginPlay();
    LastSafePosition = GetActorLocation();
    PreviousPosition = LastSafePosition;
    CreakSound=LoadObject<USoundBase>(nullptr,TEXT("/Game/Imported/S_creak.S_creak"));
    GlassSound=LoadObject<USoundBase>(nullptr,TEXT("/Game/Imported/S_glass.S_glass"));
    StingerSound=LoadObject<USoundBase>(nullptr,TEXT("/Game/Imported/S_stinger.S_stinger"));
    if (IsLocallyControlled())
    {
        if (auto* Sound=LoadObject<USoundWave>(nullptr,TEXT("/Game/Imported/S_breath.S_breath")))
        { Sound->bLooping=true; Breath->SetSound(Sound); Breath->SetVolumeMultiplier(0); Breath->Play(); }
    }
}
void AWDCharacter::Forward(float Value)
{
    if (CanMove() && Controller) AddMovementInput(FRotationMatrix(FRotator(0, Controller->GetControlRotation().Yaw, 0)).GetUnitAxis(EAxis::X), Value);
}
bool AWDCharacter::CanAct() const
{
    const auto* GS=GetWorld()->GetGameState<AWDGameState>();
    return !bCaught && GS && !GS->bRoundEnded && GS->Phase==EWDRoundPhase::Playing;
}
bool AWDCharacter::CanMove() const
{
    const auto* PC=Cast<AWDPlayerController>(Controller);
    return CanAct() && !HidingSpot && !RidingCar && !(PC && (PC->bMenuOpen || PC->bBagOpen || bJournalOpen));
}
void AWDCharacter::EndPlay(const EEndPlayReason::Type Reason)
{
    if(HasAuthority() && HidingSpot && HidingSpot->Occupant==this){HidingSpot->Occupant=nullptr;HidingSpot->ForceNetUpdate();}
    Super::EndPlay(Reason);
}
void AWDCharacter::Right(float Value)
{
    if (CanMove() && Controller) AddMovementInput(FRotationMatrix(FRotator(0, Controller->GetControlRotation().Yaw, 0)).GetUnitAxis(EAxis::Y), Value);
}
void AWDCharacter::TurnRate(float Value) { AddControllerYawInput(Value * 90.f * GetWorld()->GetDeltaSeconds()); }
void AWDCharacter::LookRate(float Value) { AddControllerPitchInput(Value * 70.f * GetWorld()->GetDeltaSeconds()); }
void AWDCharacter::SprintOn() { ServerSprint(true); }
void AWDCharacter::SprintOff() { ServerSprint(false); }
void AWDCharacter::ServerSprint_Implementation(bool bEnabled) { bSprinting = bEnabled && CanAct() && !HidingSpot && !RidingCar && Stamina > 5.f; }
void AWDCharacter::ToggleCrouch() { if(!CanMove())return; if (bIsCrouched) UnCrouch(); else Crouch(); }
void AWDCharacter::OnStartCrouch(float HalfHeightAdjust, float ScaledHalfHeightAdjust)
{
    Super::OnStartCrouch(HalfHeightAdjust, ScaledHalfHeightAdjust);
    Camera->SetRelativeLocation(FVector(0,0,BaseEyeHeight));
}
void AWDCharacter::OnEndCrouch(float HalfHeightAdjust, float ScaledHalfHeightAdjust)
{
    Super::OnEndCrouch(HalfHeightAdjust, ScaledHalfHeightAdjust);
    Camera->SetRelativeLocation(FVector(0,0,BaseEyeHeight));
}
void AWDCharacter::ToggleLight() { ServerToggleLight(); }
void AWDCharacter::ServerToggleLight_Implementation() { if (CanAct()) bLightOn = !bLightOn; }
void AWDCharacter::Use() { ServerUse(GetViewRotation()); }
void AWDCharacter::ServerUse_Implementation(FRotator ViewRotation)
{
    // Include the view in this reliable action: a stationary client's latest
    // look packet may otherwise arrive after Use and select an adjacent drawer.
    // Reach, occlusion, availability and locks are still checked on the server.
    if(ViewRotation.ContainsNaN() || !Controller) return;
    Controller->SetControlRotation(ViewRotation.GetNormalized());
    if (bCaught || GetWorld()->GetTimeSeconds() < NextUse) return;
    const auto* Round=GetWorld()->GetGameState<AWDGameState>();
    if(!Round || Round->Phase!=EWDRoundPhase::Playing) return;
    NextUse = GetWorld()->GetTimeSeconds() + .15;
    if (RidingCar) { RidingCar->StartCar(this); return; }
    if (HidingSpot) { LeaveHiding(); return; }
    if (auto* Target = FindInteractionTarget()) Target->Interact(this);
}
AWDInteractable* AWDCharacter::FindInteractionTarget() const
{
    if (bCaught || RidingCar) return nullptr;
    const FVector Eye = GetPawnViewLocation();
    const FVector ForwardVector = GetViewRotation().Vector();
    AWDInteractable* Best = nullptr;
    float BestScore = -FLT_MAX;
    for (TActorIterator<AWDInteractable> It(GetWorld()); It; ++It)
    {
        if (!It->IsAvailable()) continue;
        const FVector Offset = It->GetInteractionPoint() - Eye;
        const float Distance = Offset.Size();
        const float Dot = FVector::DotProduct(ForwardVector, Offset.GetSafeNormal());
        if (Distance > 280.f || Dot < .65f) continue;
        FHitResult Hit;
        FCollisionQueryParams Params(SCENE_QUERY_STAT(UseVisibility), false, this);
        Params.AddIgnoredActor(*It);
        // A nearby handle is forgiving; a wall between the player and handle is not.
        if (GetWorld()->LineTraceSingleByChannel(Hit, Eye, It->GetInteractionPoint(), ECC_Visibility, Params)) continue;
        const float Score = Dot * 20.f - Distance / 560.f;
        if (Score > BestScore) { Best = *It; BestScore = Score; }
    }
    return Best;
}
void AWDCharacter::Catch()
{
    if (!HasAuthority() || !CanAct() || RidingCar) return;
    bCaught = true;
    // A blocked hide exit must not leave a dead survivor occupying the furniture.
    if (HidingSpot) {HidingSpot->Occupant=nullptr;HidingSpot->ForceNetUpdate();HidingSpot=nullptr;OnRep_Hiding();}
    bSprinting = false;
    PlayCue(StingerSound,GetActorLocation());
    if(auto* PC=Cast<AWDPlayerController>(Controller))
        for(TActorIterator<AWDGhost> It(GetWorld());It;++It){PC->ShowScare(It->GetFaceLocation(),It->GetActorForwardVector());break;}
    GetCharacterMovement()->StopMovementImmediately();
    ForceNetUpdate();
}
void AWDCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if(RidingCar && CarSeat>=0)SetActorLocation(RidingCar->SeatLocation(CarSeat),false,nullptr,ETeleportType::TeleportPhysics);
    auto* Desired=bCaught?DeathAnimation.Get():GetVelocity().Size2D()>300?RunAnimation.Get():GetVelocity().Size2D()>5?WalkAnimation.Get():IdleAnimation.Get();
    if(Desired && Desired!=ActiveAnimation){ActiveAnimation=Desired;GetMesh()->PlayAnimation(Desired,!bCaught);}
    GetMesh()->SetVisibility(!HidingSpot && !RidingCar);
    const auto* GameState = GetWorld()->GetGameState<AWDGameState>();
    const bool bStopped = bCaught || HidingSpot || RidingCar || (GameState && (GameState->bRoundEnded || GameState->Phase != EWDRoundPhase::Playing));
    GetCharacterMovement()->MaxWalkSpeed = bStopped ? 0.f : bSprinting && Stamina > 0.f ? 430.f : 240.f;
    GetCharacterMovement()->MaxWalkSpeedCrouched = bStopped ? 0.f : 120.f;
    Flashlight->SetVisibility(bLightOn && !HidingSpot && !bCaught);
    if (IsLocallyControlled())
    {
        float Danger=0;
        for (TActorIterator<AWDGhost> It(GetWorld()); It; ++It)
            Danger=FMath::Max(Danger,It->ThreatAt(GetActorLocation()));
        Breath->SetVolumeMultiplier(bStopped && !HidingSpot?0.f:FMath::Clamp(Danger*.7f,0.f,.7f));
    }
    // Short intermittent dips, not rapid strobing; the light remains usable.
    const float Time = GetWorld()->GetTimeSeconds();
    const float Dip = FMath::Fmod(Time, 19.f) > 18.55f ? .65f : 1.f;
    Flashlight->SetIntensity(12.f * Dip);
    if (!HasAuthority()) return;
    const float Travel=FVector::Dist2D(GetActorLocation(),PreviousPosition);
    PreviousPosition=GetActorLocation();
    if (!bStopped && Travel<100 && GetCharacterMovement()->IsMovingOnGround()) DistanceWalked+=Travel;
    if(!bStopped && Travel>.1f && Time>NextBump)
        for(TActorIterator<AWDInteractable>It(GetWorld());It;++It)
            if(It->Kind==EWDInteraction::Noise && FVector::Dist2D(GetActorLocation(),It->GetActorLocation())<65 && FMath::Abs(GetActorLocation().Z-It->GetActorLocation().Z)<120)
            {NextBump=Time+8;PlayCue(GlassSound,It->GetActorLocation());GetWorld()->GetGameState<AWDGameState>()->EmitNoise(It->GetActorLocation(),8000,TEXT("Disturbed clutter"));break;}
    // A loose-board event after roughly 25-50 walking steps, only on authored rotten patches.
    if (!bStopped && DistanceWalked>2200 && !bIsCrouched && GameState)
    {
        FHitResult Floor;
        FCollisionQueryParams Params(SCENE_QUERY_STAT(LooseFloor),false,this);
        if (GetWorld()->LineTraceSingleByChannel(Floor,GetActorLocation(),GetActorLocation()-FVector(0,0,130),ECC_Visibility,Params)
            && Floor.GetActor() && Floor.GetActor()->ActorHasTag(TEXT("LooseBoard")))
        { DistanceWalked=0; PlayCue(CreakSound,GetActorLocation()); GetWorld()->GetGameState<AWDGameState>()->EmitNoise(GetActorLocation(),6000,TEXT("Loose floorboard")); }
    }
    if (bSprinting && GetVelocity().SizeSquared2D() > 100.f)
        Stamina = FMath::Max(0.f, Stamina - DeltaSeconds * 18.f);
    else Stamina = FMath::Min(100.f, Stamina + DeltaSeconds * 12.f);
    if (Stamina <= 0) bSprinting = false;
    if (!bStopped && GetCharacterMovement()->IsMovingOnGround()) LastSafePosition = GetActorLocation();
    else if (!bStopped && GetVelocity().Z < -500.f && GetActorLocation().Z < LastSafePosition.Z - 250.f)
    {
        // Last resort only. Regression tests must prove the stair collision independently.
        ++FallRecoveryCount;
        TeleportTo(LastSafePosition + FVector(0,0,4), GetActorRotation(), false, false);
        GetCharacterMovement()->StopMovementImmediately();
        UE_LOG(LogTemp, Warning, TEXT("WD_FALL_RECOVERY %s"), *LastSafePosition.ToString());
    }
}
void AWDCharacter::SetupPlayerInputComponent(UInputComponent* Input)
{
    Super::SetupPlayerInputComponent(Input);
    Input->BindAxis("MoveForward", this, &AWDCharacter::Forward);
    Input->BindAxis("MoveRight", this, &AWDCharacter::Right);
    Input->BindAxis("Turn", this, &APawn::AddControllerYawInput);
    Input->BindAxis("LookUp", this, &APawn::AddControllerPitchInput);
    Input->BindAxis("TurnRate", this, &AWDCharacter::TurnRate);
    Input->BindAxis("LookRate", this, &AWDCharacter::LookRate);
    Input->BindAction("Use", IE_Pressed, this, &AWDCharacter::Use);
    Input->BindAction("Throw", IE_Pressed, this, &AWDCharacter::ThrowBottle);
    Input->BindAction("Flashlight", IE_Pressed, this, &AWDCharacter::ToggleLight);
    Input->BindAction("Crouch", IE_Pressed, this, &AWDCharacter::ToggleCrouch);
    Input->BindAction("Sprint", IE_Pressed, this, &AWDCharacter::SprintOn);
    Input->BindAction("Sprint", IE_Released, this, &AWDCharacter::SprintOff);
}
void AWDCharacter::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME(AWDCharacter, Stamina);
    DOREPLIFETIME(AWDCharacter, bCaught);
    DOREPLIFETIME(AWDCharacter, bLightOn);
    DOREPLIFETIME(AWDCharacter, bSprinting);
    DOREPLIFETIME(AWDCharacter, HidingSpot);
    DOREPLIFETIME(AWDCharacter, RidingCar);
    DOREPLIFETIME(AWDCharacter, CarSeat);
    DOREPLIFETIME(AWDCharacter, Bottles);
}
void AWDCharacter::ShowLetter_Implementation() { bJournalOpen=true; }
void AWDCharacter::OnRep_Hiding()
{
    GetCapsuleComponent()->SetCollisionEnabled(HidingSpot?ECollisionEnabled::NoCollision:ECollisionEnabled::QueryAndPhysics);
    GetCharacterMovement()->SetMovementMode(HidingSpot?MOVE_None:MOVE_Walking);
    Camera->SetRelativeLocation(HidingSpot?FVector(0,0,HidingSpot->Kind==EWDInteraction::Bed?-58:45):FVector(0,0,BaseEyeHeight));
}
void AWDCharacter::EnterHiding(AWDInteractable* Spot)
{
    if (!HasAuthority() || !CanAct() || HidingSpot || RidingCar || !Spot || Spot->Occupant) return;
    Spot->Occupant=this; HidingSpot=Spot; bSprinting=false;
    OnRep_Hiding();
    SetActorLocation(Spot->GetActorTransform().TransformPosition(Spot->HideOffset),false,nullptr,ETeleportType::TeleportPhysics);
    if (Controller){const FRotator Facing=Spot->GetActorRotation()+FRotator(0,-90,0);Controller->SetControlRotation(Facing);if(auto* PC=Cast<APlayerController>(Controller))PC->ClientSetRotation(Facing,true);}
    ForceNetUpdate(); Spot->ForceNetUpdate();
}
void AWDCharacter::LeaveHiding()
{
    if (!HasAuthority() || !HidingSpot) return;
    auto* Spot=HidingSpot.Get();
    FVector Exit=Spot->GetActorTransform().TransformPosition(Spot->ExitOffset);
    FCollisionQueryParams Params(SCENE_QUERY_STAT(HideExit),false,this); Params.AddIgnoredActor(Spot);
    if (GetWorld()->OverlapBlockingTestByChannel(Exit,FQuat::Identity,ECC_Pawn,FCollisionShape::MakeCapsule(34,90),Params)) return;
    Spot->Occupant=nullptr; HidingSpot=nullptr;
    SetActorLocation(Exit,false,nullptr,ETeleportType::TeleportPhysics); OnRep_Hiding();
    ForceNetUpdate(); Spot->ForceNetUpdate();
}
void AWDCharacter::ThrowBottle_Implementation()
{
    auto* State=GetWorld()->GetGameState<AWDGameState>();
    if (RidingCar){LeaveCar();return;}
    if (!State || State->Phase!=EWDRoundPhase::Playing || bCaught || HidingSpot || Bottles<=0 || GetWorld()->GetTimeSeconds()<NextThrow) return;
    NextThrow=GetWorld()->GetTimeSeconds()+1; --Bottles;
    const FVector Start=GetPawnViewLocation(), End=Start+GetViewRotation().Vector()*950;
    FHitResult Hit; FCollisionQueryParams Params(SCENE_QUERY_STAT(Bottle),false,this);
    const FVector Impact=GetWorld()->LineTraceSingleByChannel(Hit,Start,End,ECC_Visibility,Params)?Hit.ImpactPoint:End;
    PlayCue(GlassSound,Impact); State->EmitNoise(Impact,8000,TEXT("Broken bottle"));
}
void AWDCharacter::PlayCue_Implementation(USoundBase* Sound,FVector Location)
{ if (Sound) UGameplayStatics::PlaySoundAtLocation(this,Sound,Location,.6f); }

void AWDCharacter::OnRep_Riding()
{
    if(RidingTickDependency.IsValid())RemoveTickPrerequisiteActor(RidingTickDependency.Get());
    RidingTickDependency=RidingCar.Get();
    // Update passengers after the vehicle, including at low mobile frame rates.
    // Otherwise their cabin position trails the car by a whole frame.
    if(RidingCar)AddTickPrerequisiteActor(RidingCar);
    GetCharacterMovement()->StopMovementImmediately();
    GetCharacterMovement()->SetMovementMode(RidingCar?MOVE_None:MOVE_Walking);
    GetCapsuleComponent()->SetCollisionEnabled(RidingCar?ECollisionEnabled::NoCollision:ECollisionEnabled::QueryAndPhysics);
    Camera->SetRelativeLocation(RidingCar?FVector(0,0,62):FVector(0,0,BaseEyeHeight));
}
void AWDCharacter::LeaveCar_Implementation()
{
    if(!HasAuthority() || !RidingCar || !CanAct())return;
    auto* Car=RidingCar.Get();
    // Try both sides and the rear; another boarding player must not trap a passenger.
    FCollisionQueryParams Q(SCENE_QUERY_STAT(CarExit),false,this);Q.AddIgnoredActor(Car);
    for(const FVector Local:{FVector(0,-160,92),FVector(0,160,92),FVector(-310,0,92)}){
        const FVector Exit=Car->GetActorTransform().TransformPosition(Local);
        FHitResult Floor;
        if(GetWorld()->OverlapBlockingTestByChannel(Exit,FQuat::Identity,ECC_Pawn,FCollisionShape::MakeCapsule(34,90),Q) ||
           !GetWorld()->LineTraceSingleByChannel(Floor,Exit,Exit-FVector(0,0,120),ECC_Visibility,Q))continue;
        RidingCar=nullptr;CarSeat=INDEX_NONE;OnRep_Riding();SetActorLocation(Exit,false,nullptr,ETeleportType::TeleportPhysics);LastSafePosition=Exit;PreviousPosition=Exit;ForceNetUpdate();return;
    }
    auto* GS=GetWorld()->GetGameState<AWDGameState>();GS->LastDiscovery=TEXT("The car exit is blocked. Ask your teammate to step aside.");GS->DiscoveryAt=GS->GetServerWorldTimeSeconds();GS->ForceNetUpdate();
}
