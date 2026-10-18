#include "WDInteractable.h"
#include "WDCharacter.h"
#include "WDGameState.h"
#include "Components/StaticMeshComponent.h"
#include "Components/SceneComponent.h"
#include "GameFramework/PlayerState.h"
#include "Kismet/GameplayStatics.h"
#include "Net/UnrealNetwork.h"

AWDInteractable::AWDInteractable()
{
    bReplicates = true;
    PrimaryActorTick.bCanEverTick = true;
    Pivot = CreateDefaultSubobject<USceneComponent>(TEXT("Pivot"));
    SetRootComponent(Pivot);
    Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("MovingMesh"));
    Mesh->SetupAttachment(Pivot);
    Mesh->SetMobility(EComponentMobility::Movable);
    Mesh->SetCollisionProfileName(TEXT("BlockAllDynamic"));
    Handle = CreateDefaultSubobject<USceneComponent>(TEXT("Handle"));
    Handle->SetupAttachment(Mesh);
}
void AWDInteractable::BeginPlay()
{
    Super::BeginPlay();
    ClosedLocation = Mesh->GetRelativeLocation();
    ClosedRotation = Mesh->GetRelativeRotation();
    OpenFraction = bOpen ? 1.f : 0.f;
    if (Kind != EWDInteraction::Door) Mesh->SetCanEverAffectNavigation(false);
    OnRep_State();
}
void AWDInteractable::OnRep_State()
{
    SetActorHiddenInGame(bCollected || (Container && !Container->bOpen));
    // Physical closed doors stop players and the ghost. Opening clears navigation occupancy.
    const bool bBlocks = !bCollected && Kind != EWDInteraction::Key && !bOpen;
    Mesh->SetCollisionEnabled(bBlocks ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision);
}
void AWDInteractable::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    OpenFraction = FMath::FInterpConstantTo(OpenFraction, bOpen ? 1.f : 0.f, DeltaSeconds, 2.5f);
    if (Kind == EWDInteraction::Door)
        Mesh->SetRelativeRotation(ClosedRotation + FRotator(0, OpenYaw * OpenFraction, 0));
    else if (Kind == EWDInteraction::Drawer)
        Mesh->SetRelativeLocation(ClosedLocation + OpenOffset * OpenFraction);
    if (Container)
    {
        SetActorHiddenInGame(bCollected || Container->OpenFraction < .95f);
        // Keys track the tray without attachment replication ordering issues.
        if (Container->Kind == EWDInteraction::Drawer)
            SetActorLocation(Container->Mesh->GetComponentTransform().TransformPosition(OpenOffset));
    }
}
FVector AWDInteractable::GetInteractionPoint() const { return Handle->GetComponentLocation(); }
bool AWDInteractable::IsAvailable() const
{
    return !bCollected && (!Container || Container->OpenFraction > .95f);
}
FText AWDInteractable::GetPrompt() const
{
    const auto* State = GetWorld()->GetGameState<AWDGameState>();
    if (!RequiredKey.IsNone() && (!State || !State->TeamKeys.Contains(RequiredKey)))
        return FText::FromString(TEXT("Locked - ") + DisplayName.ToString());
    const FString Verb = Kind == EWDInteraction::Key ? TEXT("Take ") : bOpen ? TEXT("Close ") : TEXT("Open ");
    return FText::FromString(Verb + DisplayName.ToString());
}
void AWDInteractable::Interact(AWDCharacter* User)
{
    auto* State = GetWorld()->GetGameState<AWDGameState>();
    if (!HasAuthority() || !User || !State || State->bRoundEnded || !IsAvailable() ||
        User->FindInteractionTarget() != this || GetWorld()->GetTimeSeconds() < NextUseTime) return;
    if (!RequiredKey.IsNone() && !State->TeamKeys.Contains(RequiredKey)) return;
    NextUseTime = GetWorld()->GetTimeSeconds() + .45;
    if (Kind == EWDInteraction::Key)
    {
        const auto* PS = User->GetPlayerState();
        if (!State->AddKey(GrantsKey, PS ? PS->GetPlayerName() : TEXT("Survivor"))) return;
        bCollected = true;
    }
    else
    {
        // Do not materialize a closing door through a player or a chasing ghost.
        if (Kind == EWDInteraction::Door && bOpen)
        {
            const FVector Doorway = GetActorTransform().TransformPosition(FVector(0,55,100));
            FCollisionQueryParams Params(SCENE_QUERY_STAT(DoorClose), false, this);
            if (GetWorld()->OverlapAnyTestByObjectType(Doorway, GetActorQuat(),
                FCollisionObjectQueryParams(ECC_Pawn), FCollisionShape::MakeBox(FVector(45,70,110)), Params)) return;
        }
        bOpen = !bOpen;
    }
    OnRep_State();
    ForceNetUpdate();
    PlayInteractionSound();
    State->EmitNoise(GetActorLocation(), 4500.f, Kind == EWDInteraction::Door ? TEXT("Door") : TEXT("Search"));
}
void AWDInteractable::PlayInteractionSound_Implementation()
{
    if (InteractionSound) UGameplayStatics::PlaySoundAtLocation(this, InteractionSound, GetActorLocation(), .55f);
}
void AWDInteractable::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& Out) const
{
    Super::GetLifetimeReplicatedProps(Out);
    DOREPLIFETIME(AWDInteractable, bOpen);
    DOREPLIFETIME(AWDInteractable, bCollected);
}
