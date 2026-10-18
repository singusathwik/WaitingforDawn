# Waiting for Dawn — Unreal rebuild

Target: **Unreal Engine 5.7**, Windows editor and Android ARM64. This is a new development project, not a renamed Godot APK. Released Godot 0.8.3 remains at the repository root.

The immediate milestone is one furnished two-level section: the parlour, stair hall and upper nursery landing. Establish movement, collision, interactions and noise-driven pursuit here before expanding the house. The user identified the fall-through near stairs on 2026-10-18.

## Implementation and validation

- First-person CharacterMovement, crouch, stamina, torch and view-based Use selection. Client and server select from the same reachable handles; the server authorizes actions.
- Replicated opening/closing doors and storage, exposed keys, shared discoveries and four-player admission limit.
- Ghost delay by difficulty, persistent noise destination, sight-based pursuit, dynamic navigation retries at closed doors, capture and search. Further noises cannot postpone an already pending investigation.
- Replicated time to dawn, difficulty rules, development HUD and basic touch actions. This HUD is deliberately marked as a development slice; the final icon interface has not been ported.
- Continuous ground support, solid stair risers, guarded landing edges and a separate unexpected-fall recovery. Geometry tests do not substitute for actual CharacterMovement traversal.
- Blender FBX preparation for the existing credited furniture/ghost plus newly authored human-scale hollow cupboard and door leaves. The importer creates actual Unreal assets and a saved map; it fails if required assets are missing.

Not yet ported: final home/lobby UI, full twelve-key dependency chain and car escape, hiding/peek animations, revive flow, cinematic introduction, full house art, optimized audio mix, final mobile controls, iOS. Existing Godot implementations remain available as references, not as Unreal features.

## Build sequence

Install UE **5.7.x** with Android target support. Install Visual Studio 2022 C++ Build Tools (MSVC 14.44, Windows SDK 22621 or newer), plus the **.NET Framework 4.8 SDK and targeting pack** required by the editor's Swarm module. The engine is configured separately from the existing Godot Android toolchain. UE 5.7 requires Android SDK 35, build-tools 35.0.1, NDK r27c and JDK 21. Use Epic Turnkey to validate these before packaging; do not replace the JDK used by Godot.

```powershell
# In repository root, using the installed Blender executable:
& 'C:/Users/Sathwik/.cache/hollow-house/tools/blender-4.3.2-windows-x64/blender.exe' --background --factory-startup --python unreal/tools/prepare_assets.py
python unreal/tools/validate_source.py
powershell -File unreal/tools/Build.ps1 -Action Check
powershell -File unreal/tools/Build.ps1 -Action Editor
powershell -File unreal/tools/Build.ps1 -Action Map
powershell -File unreal/tools/Build.ps1 -Action Tests
powershell -File unreal/tools/Build.ps1 -Action Gameplay
powershell -File unreal/tools/Test-Network.ps1
```

Open `WaitingForDawn/WaitingForDawn.uproject`, wait for shaders/navigation and play `StairHall`. WASD/mouse, E use, F torch, Ctrl crouch, Shift sprint. Choose difficulty with the map URL option `?Difficulty=0` (Easy) through `3` (Extreme). UI selection follows after gameplay validation.

`Gameplay` starts an opt-in development probe in the actual game world. It drives CharacterMovement up and down the stairs, uses the cupboard, collects its visible key and measures the ghost's noise investigation. Results go to `WaitingForDawn/Saved/Validation/gameplay-probe.json`; failure exits nonzero. It is disabled in Shipping builds. See [the validation record](docs/VALIDATION.md) for executed results and remaining gaps.

For local networking validation, start one instance with `/Game/Maps/StairHall?listen` and join another using `open 127.0.0.1`. Physical LAN tests must use two separate devices with the same Unreal build. Godot and Unreal clients are not protocol-compatible. Internet relay and host migration are not implemented.

`Build.ps1 -Action Windows` and `-Action Android` are Development packaging commands, gated on a generated map. They do not certify gameplay or sign a public release. The preview Android package is `org.waitingfordawn.unrealpreview`, so it does not overwrite the existing APK.

## Acceptance gates before a playable release

1. Compile with UnrealHeaderTool and MSVC; run the native automation checks.
2. Import all mesh/animation/material assets and verify centimetre scale, front direction, hinges and collision in-engine. Confirm the cupboard is visibly hollow and its key is reachable from the front.
3. Walk both stair edges, every landing corner, ascend/descend repeatedly and walk into rails. No unplanned falling or recovery log is allowed. Repeat at low frame rate.
4. Trigger a cupboard from an isolated room: ghost must start investigating after the configured delay, reach the closed door, retain the goal and enter only after opening. Repeat with rapid noises and with a client player.
5. Confirm prompts and actions agree; shut doors cannot appear through a character; key pickup races award one team item. Validate late join and disconnect.
6. Verify capture and dawn loss, all required input paths, no ghost revealed during the future intro, and a successful complete escape once the remaining game loop is ported.
7. Package, install and test an actual Android ARM64 phone; profile frame time, memory, thermals, touch and headphone spatial audio. Emulator or source checks do not satisfy this gate.

## Art and tools

Existing asset rights and source credits are retained in [ASSETS.md](../ASSETS.md). The ghost remains a CC BY 3.0 adaptation of Rosswet Mobile's Thin Zombie, submitted by dogchicken. No commercial horror-game assets were extracted. Blender sources/FBX staging are reproducible with the preparation script; `unreal/Staging` is generated and ignored. Unreal `.uasset` and `.umap` files are created only by the real editor.

The optional Unreal MCP plugin is not assumed to exist in every launcher engine. Enable ModelContextProtocol/AllToolsets only after checking those plugins are installed. This project can be compiled and imported without that optional connection.

Official setup references, checked 2026-10-18:

- [Install Unreal Engine](https://dev.epicgames.com/documentation/unreal-engine/install-unreal-engine)
- [UE 5.7 C++ tools](https://dev.epicgames.com/documentation/en-us/unreal-engine/setting-up-visual-studio-development-environment-for-cplusplus-projects-in-unreal-engine?application_version=5.7)
- [UE 5.7 Android requirements](https://dev.epicgames.com/documentation/en-us/unreal-engine/android-development-requirements-for-unreal-engine?application_version=5.7)
