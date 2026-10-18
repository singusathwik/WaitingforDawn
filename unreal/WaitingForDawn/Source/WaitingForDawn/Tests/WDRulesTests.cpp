#if WITH_DEV_AUTOMATION_TESTS
#include "Misc/AutomationTest.h"
#include "WDGameState.h"
#include "WDGhost.h"
#include "Engine/Engine.h"
#include "Engine/World.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FWDDifficultyRules, "WaitingForDawn.Rules.Difficulty",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FWDDifficultyRules::RunTest(const FString& Parameters)
{
    TestEqual(TEXT("Easy response"), AWDGameState::ReactionDelay(EWDDifficulty::Easy), 6.f);
    TestEqual(TEXT("Normal response"), AWDGameState::ReactionDelay(EWDDifficulty::Normal), 4.5f);
    TestEqual(TEXT("Hard response"), AWDGameState::ReactionDelay(EWDDifficulty::Hard), 3.f);
    TestEqual(TEXT("Extreme response"), AWDGameState::ReactionDelay(EWDDifficulty::Extreme), 2.f);
    for (int32 Index=0; Index<4; ++Index)
    {
        const auto Difficulty = static_cast<EWDDifficulty>(Index);
        TestTrue(TEXT("Round allows at least twenty minutes"), AWDGameState::RoundDuration(Difficulty) >= 1200.f);
        if (Index) TestTrue(TEXT("Increasing difficulty shortens the round"),
            AWDGameState::RoundDuration(Difficulty) < AWDGameState::RoundDuration(static_cast<EWDDifficulty>(Index-1)));
    }
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FWDNoiseDeadline, "WaitingForDawn.Rules.NoiseCannotPostponePursuit",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FWDNoiseDeadline::RunTest(const FString& Parameters)
{
    TestEqual(TEXT("Initial easy reaction"), AWDGhost::ReactionDeadline(EWDGhostState::Patrol,0.,10.,6.f),16.);
    TestEqual(TEXT("Repeated noise keeps earlier deadline"), AWDGhost::ReactionDeadline(EWDGhostState::Listening,16.,15.,6.f),16.);
    TestEqual(TEXT("Investigation continues immediately"), AWDGhost::ReactionDeadline(EWDGhostState::Investigating,16.,17.,6.f),17.);
    TestEqual(TEXT("Noise does not interrupt chase"), AWDGhost::ReactionDeadline(EWDGhostState::Chasing,16.,17.,6.f),17.);
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FWDStairSupport, "WaitingForDawn.World.StairCollision",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FWDStairSupport::RunTest(const FString& Parameters)
{
    UWorld* World = nullptr;
    for (const FWorldContext& Context : GEngine->GetWorldContexts())
        if (Context.WorldType == EWorldType::Editor) World = Context.World();
    if (!World || !World->GetMapName().Contains(TEXT("StairHall")))
    { AddError(TEXT("Load the generated StairHall map before running collision tests.")); return false; }
    for (int32 Step=0; Step<20; ++Step)
    {
        const float X = -386.f + Step*28.f;
        const float Z = (Step+1)*16.f;
        for (float Side : {-38.f,0.f,38.f})
        {
            FHitResult Hit;
            const bool bHit = World->LineTraceSingleByChannel(Hit,FVector(X,250+Side,Z+5),FVector(X,250+Side,Z-5),ECC_Visibility);
            TestTrue(FString::Printf(TEXT("Step %d side %.0f supports feet"),Step,Side),bHit && FMath::Abs(Hit.ImpactPoint.Z-Z)<1.f);
        }
        for (float Side : {-1.f,1.f})
        {
            FHitResult Hit;
            TestTrue(FString::Printf(TEXT("Step %d guard %.0f blocks exit"),Step,Side),
                World->LineTraceSingleByChannel(Hit,FVector(X,250,Z+60),FVector(X,250+Side*110,Z+60),ECC_Visibility));
        }
    }
    for (FVector Point : {FVector(200,250,320),FVector(310,250,320),FVector(310,40,320),FVector(-320,40,320)})
    {
        FHitResult Hit;
        TestTrue(TEXT("Landing support is continuous"),World->LineTraceSingleByChannel(Hit,Point+FVector(0,0,5),Point-FVector(0,0,5),ECC_Visibility));
    }
    return true;
}
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FWDRoundLifecycle, "WaitingForDawn.Rules.StoryDawnAndEscape",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FWDRoundLifecycle::RunTest(const FString& Parameters)
{
    UWorld* World=nullptr;for(const FWorldContext& C:GEngine->GetWorldContexts())if(C.WorldType==EWorldType::Editor)World=C.World();
    if(!World){AddError(TEXT("Editor world required"));return false;}
    auto* State=World->SpawnActor<AWDGameState>();State->Phase=EWDRoundPhase::Lobby;
    State->StartRound(EWDDifficulty::Hard,false);TestTrue(TEXT("Play begins story"),State->Phase==EWDRoundPhase::Introduction);
    State->IntroRemaining=0;State->Tick(.01f);TestTrue(TEXT("Skip enters gameplay"),State->Phase==EWDRoundPhase::Playing);
    State->AddKey(TEXT("Ignition"),TEXT("test"));TestFalse(TEXT("Car cannot cross closed garage"),State->CanEscape());
    State->bGarageUnlocked=true;TestTrue(TEXT("Both final requirements allow escape"),State->CanEscape());
    State->EndRound(true,TEXT("Escaped"));TestTrue(TEXT("Escape wins"),State->Phase==EWDRoundPhase::Escaped);TestFalse(TEXT("Ended game rejects key grants"),State->AddKey(TEXT("Nursery"),TEXT("test")));
    State->bRoundEnded=false;State->Phase=EWDRoundPhase::Playing;State->SecondsRemaining=.001f;State->Tick(.02f);TestTrue(TEXT("Dawn loses"),State->Phase==EWDRoundPhase::Lost);
    State->Destroy();return true;
}
#endif
