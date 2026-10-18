#include "WDHUD.h"
#include "WDCharacter.h"
#include "WDInteractable.h"
#include "WDGhost.h"
#include "WDGameState.h"
#include "Engine/Canvas.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"

void AWDHUD::DrawHUD()
{
    Super::DrawHUD();
    if (!Canvas || !PlayerOwner) return;
    auto* Player = Cast<AWDCharacter>(PlayerOwner->GetPawn());
    auto* State = GetWorld()->GetGameState<AWDGameState>();
    if (!Player || !State) return;
    const float W = Canvas->ClipX, H = Canvas->ClipY;
    const float Scale = H / 720.f;
    DrawText(TEXT("UNREAL DEVELOPMENT SLICE"), FLinearColor(.7,.65,.5), 28*Scale, 18*Scale, nullptr, Scale);
    const int32 Minutes = FMath::CeilToInt(State->SecondsRemaining / 60.f);
    DrawText(FString::Printf(TEXT("DAWN IN %d MIN"), Minutes), FLinearColor::White, W*.46f, 18*Scale, nullptr, Scale);
    DrawRect(FLinearColor(.08,.08,.08,.8), W*.35f, H-38*Scale, W*.3f, 8*Scale);
    DrawRect(FLinearColor(.22,.55,.25,1), W*.35f, H-38*Scale, W*.3f * Player->Stamina / 100.f, 8*Scale);
    DrawLine(W*.5f-4,H*.5f,W*.5f+4,H*.5f,FLinearColor::White);
    DrawLine(W*.5f,H*.5f-4,W*.5f,H*.5f+4,FLinearColor::White);
    if (auto* Target = Player->FindInteractionTarget())
        DrawText(TEXT("E / USE - ") + Target->GetPrompt().ToString(), FLinearColor(1,.85,.55), W*.35f,H*.65f,nullptr,Scale);
    FString Bag = TEXT("BAG");
    for (FName Key : State->TeamKeys) Bag += TEXT("\n") + Key.ToString();
    DrawText(Bag, FLinearColor(.8,.8,.7), W-240*Scale, 50*Scale, nullptr, Scale);
    DrawText(State->LastDiscovery, FLinearColor(.85,.8,.65), 28*Scale, 55*Scale, nullptr, Scale);
    float Danger = 0;
    for (TActorIterator<AWDGhost> It(GetWorld()); It; ++It)
        Danger = FMath::Max(Danger, 1.f - FVector::Dist(It->GetActorLocation(), Player->GetActorLocation()) / 1000.f);
    if (Danger > 0)
    {
        DrawRect(FLinearColor(.45,0,0,Danger*.4f), 0,0,18*Scale,H);
        DrawRect(FLinearColor(.45,0,0,Danger*.4f), W-18*Scale,0,18*Scale,H);
    }
    const FName Actions[] = {TEXT("Use"),TEXT("Light"),TEXT("Crouch")};
    for (int32 Index=0; Index<3; ++Index)
    {
        const float X = W - (3-Index)*95*Scale;
        DrawRect(FLinearColor(.08,.07,.06,.8), X,H-120*Scale,85*Scale,55*Scale);
        DrawText(Actions[Index].ToString(),FLinearColor::White,X+10*Scale,H-103*Scale,nullptr,Scale);
        AddHitBox(FVector2D(X,H-120*Scale),FVector2D(85*Scale,55*Scale),Actions[Index],true);
    }
    if (Player->bCaught || State->bRoundEnded)
    {
        DrawRect(FLinearColor(0,0,0,.75),W*.2f,H*.3f,W*.6f,H*.3f);
        DrawText(Player->bCaught ? TEXT("SHE FOUND YOU") : TEXT("DAWN CAME TOO LATE"), FLinearColor(.9,.75,.65),W*.35f,H*.42f,nullptr,2*Scale);
        DrawText(TEXT("Development slice: restart from the console with RestartLevel"),FLinearColor::White,W*.26f,H*.51f,nullptr,Scale);
    }
}
void AWDHUD::NotifyHitBoxClick(FName BoxName)
{
    Super::NotifyHitBoxClick(BoxName);
    if (auto* Player = Cast<AWDCharacter>(GetOwningPawn()))
    {
        if (BoxName == TEXT("Use")) Player->Use();
        else if (BoxName == TEXT("Light")) Player->ToggleLight();
        else if (BoxName == TEXT("Crouch")) Player->ToggleCrouch();
    }
}
