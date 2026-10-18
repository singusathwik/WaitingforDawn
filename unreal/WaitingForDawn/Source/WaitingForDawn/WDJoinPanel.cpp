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
    AddText(TEXT("JOIN WITH FRIENDS\n\nSame Wi-Fi: enter the host's local IP. Different locations: connect a private VPN, then enter the host's VPN IP.\nNo automatic internet matchmaking. The host must keep this game open.\n"));
    bool CanBind=false; auto IP=ISocketSubsystem::Get(PLATFORM_SOCKETSUBSYSTEM)->GetLocalHostAddr(*GLog,CanBind);
    AddText(TEXT("This device: ")+IP->ToString(false)+TEXT("\n"));
    Address=WidgetTree->ConstructWidget<UEditableTextBox>(); Address->SetHintText(FText::FromString(TEXT("Host IPv4, e.g. 192.168.1.20 or VPN IP; optional :7777")));
    Address->SetForegroundColor(FLinearColor(.06,.05,.04));
    Column->AddChild(Address);
    auto AddButton=[&](const FString& Label){ auto* B=WidgetTree->ConstructWidget<UButton>(); B->SetBackgroundColor(FLinearColor(.09,.07,.055)); auto* T=WidgetTree->ConstructWidget<UTextBlock>(); T->SetText(FText::FromString(Label)); T->SetColorAndOpacity(FSlateColor(FLinearColor(.95,.88,.75))); T->SetMargin(FMargin(16,10)); B->AddChild(T); Column->AddChild(B); return B; };
    AddButton(TEXT("JOIN HOUSE"))->OnClicked.AddDynamic(this,&UWDJoinPanel::Connect);
    AddButton(TEXT("HOST A HOUSE"))->OnClicked.AddDynamic(this,&UWDJoinPanel::Host);
    AddButton(TEXT("BACK"))->OnClicked.AddDynamic(this,&UWDJoinPanel::Back);
    Status=AddText(TEXT("\nMaximum four players. Shared keys. Everyone alive must board the car to escape.\nPrivate VPN setup is explained in the release's REMOTE-PLAY guide. UDP 7777 by default."));
}
bool UWDJoinPanel::NormalizeAddress(const FString& Input,FString& Output)
{
    Output.Empty();const FString Value=Input.TrimStartAndEnd();TArray<FString> Host;
    Value.ParseIntoArray(Host,TEXT(":"),false);if(Host.Num()<1 || Host.Num()>2)return false;
    auto Number=[](const FString& Part,int32 Digits,int32 Max){if(Part.IsEmpty() || Part.Len()>Digits)return false;for(TCHAR C:Part)if(C<'0'||C>'9')return false;return FCString::Atoi(*Part)<=Max;};
    TArray<FString> Parts;Host[0].ParseIntoArray(Parts,TEXT("."),false);if(Parts.Num()!=4)return false;
    for(const FString& P:Parts)if(!Number(P,3,255))return false;
    const int32 First=FCString::Atoi(*Parts[0]);if(First==0 || First>=224)return false;
    if(Host.Num()==2 && (!Number(Host[1],5,65535)||FCString::Atoi(*Host[1])==0))return false;
    Output=FString::Printf(TEXT("%d.%d.%d.%d"),First,FCString::Atoi(*Parts[1]),FCString::Atoi(*Parts[2]),FCString::Atoi(*Parts[3]));
    if(Host.Num()==2)Output+=FString::Printf(TEXT(":%d"),FCString::Atoi(*Host[1]));return true;
}
void UWDJoinPanel::Connect()
{
    FString Value;
    if (!NormalizeAddress(Address->GetText().ToString(),Value)) { Status->SetText(FText::FromString(TEXT("Enter a four-part IPv4 address, optionally followed by :port (1-65535)."))); return; }
    AWDPlayerController::LastNetworkError.Empty();
    Status->SetText(FText::FromString(TEXT("Connecting..."))); GetOwningPlayer()->ClientTravel(Value,ETravelType::TRAVEL_Absolute);
}
void UWDJoinPanel::Host()
{
    auto* PC=Cast<AWDPlayerController>(GetOwningPlayer());
    UGameplayStatics::OpenLevel(this,TEXT("House"),true,FString::Printf(TEXT("listen?Difficulty=%d"),PC?PC->SelectedDifficulty:1));
}
void UWDJoinPanel::Back() { RemoveFromParent(); if(auto* PC=Cast<AWDPlayerController>(GetOwningPlayer())) PC->ClosePanels(); }
