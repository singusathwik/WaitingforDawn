#include "WDJoinPanel.h"
#include "WDPlayerController.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/VerticalBox.h"
#include "Components/Button.h"
#include "Components/TextBlock.h"
#include "Components/EditableTextBox.h"
#include "Kismet/GameplayStatics.h"
#include "SocketSubsystem.h"
#include "IPAddress.h"
void UWDJoinPanel::NativeOnInitialized()
{
    // Build the tree before RebuildWidget selects its Slate root.
    Super::NativeOnInitialized();
    auto* Border=WidgetTree->ConstructWidget<UBorder>(); Border->SetBrushColor(FLinearColor(.025,.02,.025,.97));
    Border->SetPadding(FMargin(60)); WidgetTree->RootWidget=Border;
    auto* Column=WidgetTree->ConstructWidget<UVerticalBox>(); Border->AddChild(Column);
    auto AddText=[&](const FString& Value){ auto* T=WidgetTree->ConstructWidget<UTextBlock>(); T->SetText(FText::FromString(Value)); T->SetAutoWrapText(true); Column->AddChild(T); return T; };
    AddText(TEXT("JOIN WITH FRIENDS\n\nUse the same Wi-Fi or phone hotspot. One player hosts; the others enter that device's local IPv4 address.\nInternet matchmaking is not available.\n"));
    bool CanBind=false; auto IP=ISocketSubsystem::Get(PLATFORM_SOCKETSUBSYSTEM)->GetLocalHostAddr(*GLog,CanBind);
    AddText(TEXT("This device: ")+IP->ToString(false)+TEXT("\n"));
    Address=WidgetTree->ConstructWidget<UEditableTextBox>(); Address->SetHintText(FText::FromString(TEXT("Host address, e.g. 192.168.1.20")));
    Address->SetForegroundColor(FLinearColor(.06,.05,.04));
    Column->AddChild(Address);
    auto AddButton=[&](const FString& Label){ auto* B=WidgetTree->ConstructWidget<UButton>(); B->SetBackgroundColor(FLinearColor(.09,.07,.055)); auto* T=WidgetTree->ConstructWidget<UTextBlock>(); T->SetText(FText::FromString(Label)); T->SetColorAndOpacity(FSlateColor(FLinearColor(.95,.88,.75))); T->SetMargin(FMargin(16,10)); B->AddChild(T); Column->AddChild(B); return B; };
    AddButton(TEXT("JOIN HOUSE"))->OnClicked.AddDynamic(this,&UWDJoinPanel::Connect);
    AddButton(TEXT("HOST A HOUSE"))->OnClicked.AddDynamic(this,&UWDJoinPanel::Host);
    AddButton(TEXT("BACK"))->OnClicked.AddDynamic(this,&UWDJoinPanel::Back);
    Status=AddText(TEXT("\nMaximum four players. Keys are shared with the whole team."));
}
void UWDJoinPanel::Connect()
{
    FString Value=Address->GetText().ToString().TrimStartAndEnd();
    TArray<FString> Parts; Value.ParseIntoArray(Parts,TEXT("."),false);
    bool Valid=Parts.Num()==4;
    for (const FString& Part:Parts) Valid &= !Part.IsEmpty() && Part.IsNumeric() && FCString::Atoi(*Part)>=0 && FCString::Atoi(*Part)<=255;
    if (!Valid) { Status->SetText(FText::FromString(TEXT("Enter the host's four-part IPv4 address."))); return; }
    Status->SetText(FText::FromString(TEXT("Connecting..."))); GetOwningPlayer()->ClientTravel(Value,ETravelType::TRAVEL_Absolute);
}
void UWDJoinPanel::Host()
{
    auto* PC=Cast<AWDPlayerController>(GetOwningPlayer());
    UGameplayStatics::OpenLevel(this,TEXT("House"),true,FString::Printf(TEXT("listen?Difficulty=%d"),PC?PC->SelectedDifficulty:1));
}
void UWDJoinPanel::Back() { RemoveFromParent(); if(auto* PC=Cast<AWDPlayerController>(GetOwningPlayer())) PC->ClosePanels(); }
