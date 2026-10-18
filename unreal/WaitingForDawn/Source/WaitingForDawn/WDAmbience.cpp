#include "WDAmbience.h"
#include "Engine/PointLight.h"
#include "Components/PointLightComponent.h"
#include "EngineUtils.h"
AWDAmbience::AWDAmbience(){PrimaryActorTick.bCanEverTick=true;bReplicates=true;bAlwaysRelevant=true;}
void AWDAmbience::Tick(float D)
{
    Super::Tick(D);Accumulator+=D;if(Accumulator<.15)return;Accumulator=0;
    if(Fixtures.IsEmpty())for(TActorIterator<APointLight> It(GetWorld());It;++It)if(It->ActorHasTag(TEXT("Flicker")))Fixtures.Add(*It);
    const float T=GetWorld()->GetTimeSeconds();
    for(int I=0;I<Fixtures.Num();++I)if(Fixtures[I].IsValid())
        Fixtures[I]->PointLightComponent->SetIntensity(FMath::Fmod(T+I*5.7f,23.f)>21.8f?12.f:60.f);
}
