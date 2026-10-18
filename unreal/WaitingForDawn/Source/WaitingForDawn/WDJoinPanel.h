#pragma once
#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "WDJoinPanel.generated.h"
class UEditableTextBox;
class UTextBlock;
UCLASS()
class WAITINGFORDAWN_API UWDJoinPanel : public UUserWidget
{
    GENERATED_BODY()
protected:
    virtual void NativeOnInitialized() override;
    UPROPERTY() TObjectPtr<UEditableTextBox> Address;
    UPROPERTY() TObjectPtr<UTextBlock> Status;
    UFUNCTION() void Connect();
    UFUNCTION() void Host();
    UFUNCTION() void Back();
};
