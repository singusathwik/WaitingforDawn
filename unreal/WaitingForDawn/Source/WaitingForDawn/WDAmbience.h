#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "WDAmbience.generated.h"
UCLASS()
class WAITINGFORDAWN_API AWDAmbience : public AActor
{
    GENERATED_BODY()
public:
    AWDAmbience();
    virtual void Tick(float DeltaSeconds) override;
private:
    TArray<TWeakObjectPtr<class APointLight>> Fixtures;
    float Accumulator=0;
};
