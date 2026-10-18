using UnrealBuildTool;
public class WaitingForDawn : ModuleRules
{
    public WaitingForDawn(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        PublicDependencyModuleNames.AddRange(new string[] {
            "Core", "CoreUObject", "Engine", "InputCore", "AIModule", "NavigationSystem", "NetCore"
        });
    }
}
