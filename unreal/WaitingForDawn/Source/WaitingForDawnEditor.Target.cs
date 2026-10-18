using UnrealBuildTool;
using System.Collections.Generic;
public class WaitingForDawnEditorTarget : TargetRules
{
    public WaitingForDawnEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_7;
        ExtraModuleNames.Add("WaitingForDawn");
    }
}
