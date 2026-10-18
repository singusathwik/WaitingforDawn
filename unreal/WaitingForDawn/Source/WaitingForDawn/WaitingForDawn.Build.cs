using UnrealBuildTool;
public class WaitingForDawn : ModuleRules
{
    public WaitingForDawn(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        PrivateIncludePaths.Add(ModuleDirectory);
        PublicDependencyModuleNames.AddRange(new string[] {
            "Core", "CoreUObject", "Engine", "InputCore", "AIModule", "NavigationSystem", "NetCore"
        });
    }
}
