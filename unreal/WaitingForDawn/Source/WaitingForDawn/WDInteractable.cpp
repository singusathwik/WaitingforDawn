#include "WDInteractable.h"
#include "WDCharacter.h"
#include "WDGameState.h"
#include "Components/StaticMeshComponent.h"
#include "Components/SceneComponent.h"
#include "GameFramework/PlayerState.h"
#include "Kismet/GameplayStatics.h"
#include "Net/UnrealNetwork.h"
#include "EngineUtils.h"

AWDInteractable::AWDInteractable()
{
    bReplicates = true;
    // Collected keys become hidden and non-colliding. They must still send their
    // collected state to late joiners instead of reverting to the map's visible state.
    bAlwaysRelevant = true;
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
    if(Kind==EWDInteraction::Garage)Handle->AttachToComponent(Pivot,FAttachmentTransformRules::KeepWorldTransform);
    if (Kind != EWDInteraction::Door || !bBlocksPassage) Mesh->SetCanEverAffectNavigation(false);
    OnRep_State();
}
void AWDInteractable::OnRep_State()
{
    SetActorHiddenInGame(bCollected || (Container && !Container->bOpen));
    // Physical closed doors stop players and the ghost. Opening clears navigation occupancy.
    const bool bBlocks = !bCollected && (Kind == EWDInteraction::Door || Kind == EWDInteraction::Garage || Kind == EWDInteraction::Drawer) && !bOpen;
    Mesh->SetCollisionEnabled(bBlocks ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision);
    Mesh->SetCanEverAffectNavigation(bBlocks && bBlocksPassage && (Kind==EWDInteraction::Door || Kind==EWDInteraction::Garage));
}
void AWDInteractable::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if(Kind==EWDInteraction::Car)
    {
        auto* Round=GetWorld()->GetGameState<AWDGameState>();
        if(Round && Round->Phase==EWDRoundPhase::Escaped && Round->EndingAge<7)
            AddActorWorldOffset(FVector(0,-250*DeltaSeconds,0));
    }
    OpenFraction = FMath::FInterpConstantTo(OpenFraction, bOpen ? 1.f : 0.f, DeltaSeconds, 2.5f);
    if (Kind == EWDInteraction::Door)
        Mesh->SetRelativeRotation(ClosedRotation + FRotator(0, OpenYaw * OpenFraction, 0));
    else if (Kind == EWDInteraction::Drawer || Kind == EWDInteraction::Garage)
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
    if ((!RequiredKey.IsNone() && (!State || !State->TeamKeys.Contains(RequiredKey))) || (State && !State->HasKeys(RequiredKeys)))
        return FText::FromString(TEXT("Locked - ") + DisplayName.ToString());
    if (Kind == EWDInteraction::Letter) return FText::FromString(TEXT("Read the keeper's letter"));
    if (Kind == EWDInteraction::Wardrobe || Kind == EWDInteraction::Bed) return FText::FromString(Occupant?TEXT("Occupied"):TEXT("Hide - ")+DisplayName.ToString());
    if (Kind == EWDInteraction::Car) return FText::FromString(State && State->CanEscape()?TEXT("Start the car - escape together"):TEXT("Car needs the ignition key and an open garage"));
    if (Kind == EWDInteraction::Noise) return FText::FromString(TEXT("Touch ")+DisplayName.ToString());
    const FString Verb = Kind == EWDInteraction::Key ? TEXT("Take ") : bOpen ? TEXT("Close ") : TEXT("Open ");
    return FText::FromString(Verb + DisplayName.ToString());
}
void AWDInteractable::Interact(AWDCharacter* User)
{
    auto* State = GetWorld()->GetGameState<AWDGameState>();
    if (!HasAuthority() || !User || !State || State->bRoundEnded || !IsAvailable() ||
        User->FindInteractionTarget() != this || GetWorld()->GetTimeSeconds() < NextUseTime) return;
    if (!RequiredKey.IsNone() && !State->TeamKeys.Contains(RequiredKey)) return;
    if (!State->HasKeys(RequiredKeys)) return;
    NextUseTime = GetWorld()->GetTimeSeconds() + .45;
    if (Kind == EWDInteraction::Wardrobe || Kind == EWDInteraction::Bed)
    {
        if (!Occupant) User->EnterHiding(this);
        return;
    }
    if (Kind == EWDInteraction::Car)
    {
        if(State->CanEscape())for(TActorIterator<AWDCharacter> It(GetWorld());It;++It)
            if(It->IsPlayerControlled()&&!It->bCaught&&(FVector::Dist2D(It->GetActorLocation(),GetActorLocation())>600 || FMath::Abs(It->GetActorLocation().Z-GetActorLocation().Z)>200))
            {State->LastDiscovery=TEXT("Bring the surviving team to the car before starting it.");State->DiscoveryAt=State->GetServerWorldTimeSeconds();State->ForceNetUpdate();return;}
        if (State->CanEscape()) { PlayInteractionSound(); State->EndRound(true, TEXT("The engine caught. Behind you, the first sunlight broke over Eleanor's house. You escaped together.")); }
        return;
    }
    if (Kind == EWDInteraction::Letter)
    {
        State->bLetterFound=true; State->LastDiscovery=TEXT("The keeper's letter was added to the journal.");
        State->DiscoveryAt=State->GetServerWorldTimeSeconds(); State->ForceNetUpdate();
        User->ShowLetter();
    }
    else if (Kind == EWDInteraction::Noise) { /* Noise only, no fake opening animation. */ }
    else if (Kind == EWDInteraction::Key)
    {
        const auto* PS = User->GetPlayerState();
        if (!State->AddKey(GrantsKey, PS ? PS->GetPlayerName() : TEXT("Survivor"))) return;
        bCollected = true;
    }
    else
    {
        // Do not materialize a closing door through a player or a chasing ghost.
        if (Kind == EWDInteraction::Door && bBlocksPassage && bOpen)
        {
            const FVector Doorway = GetActorTransform().TransformPosition(FVector(0,55,100));
            FCollisionQueryParams Params(SCENE_QUERY_STAT(DoorClose), false, this);
            if (GetWorld()->OverlapAnyTestByObjectType(Doorway, GetActorQuat(),
                FCollisionObjectQueryParams(ECC_Pawn), FCollisionShape::MakeBox(FVector(45,70,110)), Params)) return;
        }
        bOpen = !bOpen;
        if (Kind == EWDInteraction::Garage) { State->bGarageUnlocked=bOpen; State->ForceNetUpdate(); }
    }
    OnRep_State();
    ForceNetUpdate();
    PlayInteractionSound();
    State->EmitNoise(GetInteractionPoint(), 4500.f, Kind == EWDInteraction::Door ? TEXT("Door") : TEXT("Search"));
}
void AWDInteractable::PlayInteractionSound_Implementation()
{
    if (InteractionSound) UGameplayStatics::PlaySoundAtLocation(this, InteractionSound, GetActorLocation(), .55f);
}
void AWDInteractable::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME(AWDInteractable, bOpen);
    DOREPLIFETIME(AWDInteractable, bCollected);
    DOREPLIFETIME(AWDInteractable, Occupant);
}
