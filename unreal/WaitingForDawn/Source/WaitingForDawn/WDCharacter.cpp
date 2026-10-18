#include "WDCharacter.h"
#include "WDInteractable.h"
#include "WDGameState.h"
#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/SpotLightComponent.h"
#include "Components/InputComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "EngineUtils.h"
#include "Net/UnrealNetwork.h"

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
    Flashlight->SetIntensity(1800.f);
    Flashlight->SetAttenuationRadius(1800.f);
    Flashlight->SetInnerConeAngle(15.f);
    Flashlight->SetOuterConeAngle(32.f);
    GetCharacterMovement()->GetNavAgentPropertiesRef().bCanCrouch = true;
    GetCharacterMovement()->MaxStepHeight = 35.f;
    GetCharacterMovement()->MaxWalkSpeed = 240.f;
    GetCharacterMovement()->MaxWalkSpeedCrouched = 120.f;
}
void AWDCharacter::BeginPlay()
{
    Super::BeginPlay();
    LastSafePosition = GetActorLocation();
}
void AWDCharacter::Forward(float Value)
{
    if (!bCaught && Controller) AddMovementInput(FRotationMatrix(FRotator(0, Controller->GetControlRotation().Yaw, 0)).GetUnitAxis(EAxis::X), Value);
}
void AWDCharacter::Right(float Value)
{
    if (!bCaught && Controller) AddMovementInput(FRotationMatrix(FRotator(0, Controller->GetControlRotation().Yaw, 0)).GetUnitAxis(EAxis::Y), Value);
}
void AWDCharacter::TurnRate(float Value) { AddControllerYawInput(Value * 90.f * GetWorld()->GetDeltaSeconds()); }
void AWDCharacter::LookRate(float Value) { AddControllerPitchInput(Value * 70.f * GetWorld()->GetDeltaSeconds()); }
void AWDCharacter::SprintOn() { ServerSprint(true); }
void AWDCharacter::SprintOff() { ServerSprint(false); }
void AWDCharacter::ServerSprint_Implementation(bool bEnabled) { bSprinting = bEnabled && !bCaught && Stamina > 5.f; }
void AWDCharacter::ToggleCrouch() { if (bIsCrouched) UnCrouch(); else Crouch(); }
void AWDCharacter::ToggleLight() { ServerToggleLight(); }
void AWDCharacter::ServerToggleLight_Implementation() { if (!bCaught) bLightOn = !bLightOn; }
void AWDCharacter::Use() { ServerUse(); }
void AWDCharacter::ServerUse_Implementation()
{
    if (bCaught || GetWorld()->GetTimeSeconds() < NextUse) return;
    NextUse = GetWorld()->GetTimeSeconds() + .15;
    if (auto* Target = FindInteractionTarget()) Target->Interact(this);
}
AWDInteractable* AWDCharacter::FindInteractionTarget() const
{
    if (bCaught) return nullptr;
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
        const float Score = Dot * 3.f - Distance / 280.f;
        if (Score > BestScore) { Best = *It; BestScore = Score; }
    }
    return Best;
}
void AWDCharacter::Catch()
{
    if (!HasAuthority() || bCaught) return;
    bCaught = true;
    bSprinting = false;
    GetCharacterMovement()->StopMovementImmediately();
    ForceNetUpdate();
}
void AWDCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    const auto* GameState = GetWorld()->GetGameState<AWDGameState>();
    const bool bStopped = bCaught || (GameState && GameState->bRoundEnded);
    GetCharacterMovement()->MaxWalkSpeed = bStopped ? 0.f : bSprinting && Stamina > 0.f ? 430.f : 240.f;
    Flashlight->SetVisibility(bLightOn);
    // Short intermittent dips, not rapid strobing; the light remains usable.
    const float Time = GetWorld()->GetTimeSeconds();
    const float Dip = FMath::Fmod(Time, 19.f) > 18.55f ? .65f : 1.f;
    Flashlight->SetIntensity(1800.f * Dip);
    if (!HasAuthority()) return;
    if (bSprinting && GetVelocity().SizeSquared2D() > 100.f)
        Stamina = FMath::Max(0.f, Stamina - DeltaSeconds * 18.f);
    else Stamina = FMath::Min(100.f, Stamina + DeltaSeconds * 12.f);
    if (Stamina <= 0) bSprinting = false;
    if (GetCharacterMovement()->IsMovingOnGround()) LastSafePosition = GetActorLocation();
    else if (GetVelocity().Z < -500.f && GetActorLocation().Z < LastSafePosition.Z - 250.f)
    {
        // Last resort only. Regression tests must prove the stair collision independently.
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
    Input->BindAction("Flashlight", IE_Pressed, this, &AWDCharacter::ToggleLight);
    Input->BindAction("Crouch", IE_Pressed, this, &AWDCharacter::ToggleCrouch);
    Input->BindAction("Sprint", IE_Pressed, this, &AWDCharacter::SprintOn);
    Input->BindAction("Sprint", IE_Released, this, &AWDCharacter::SprintOff);
}
void AWDCharacter::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& Out) const
{
    Super::GetLifetimeReplicatedProps(Out);
    DOREPLIFETIME(AWDCharacter, Stamina);
    DOREPLIFETIME(AWDCharacter, bCaught);
    DOREPLIFETIME(AWDCharacter, bLightOn);
    DOREPLIFETIME(AWDCharacter, bSprinting);
}
