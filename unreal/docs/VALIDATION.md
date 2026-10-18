# Unreal rebuild checkpoint — 2026-10-18

This records the new Unreal project only. **This is a tested development section, not the completed game or an Android release.** Godot results are not Unreal evidence.

| Check | Result | Evidence / limit |
|---|---|---|
| Installed toolchain | PASS | Unreal 5.7.4, VS Build Tools 17.14.42, MSVC 14.44.35229, Windows SDK 22621, .NET Framework 4.8 SDK |
| Game/editor C++ builds | PASS | windows-game-build.log and windows-editor-build.log; real UnrealHeaderTool/MSVC builds |
| Source/export checks | PASS | 2,586 mathematical support probes; 13 FBXs; 33,506 static triangles |
| Blender round trip | PASS | All 13 exports reopened; ghost has 42 bones including a new master root, retaining the original 41 |
| Unreal asset import | PASS | Saved assets and StairHall.umap; static mesh dimensions checked within 1 cm. FBX smoothing-group warnings remain |
| Native automation | PASS, 3/3 | Difficulty, noise deadline, 104 real engine collision rays on stairs/guards/landings; native-tests.json |
| Actual CharacterMovement | PASS on scripted route | 16 waypoints up/down stairs and across landing, no fall recovery; headless at a 60 FPS cap and D3D12 at a 20 FPS cap |
| Cupboard/key | PASS | Actual Use selection, opening, exposed key, shared inventory and closing; hollow interior/key inspected in Unreal capture |
| Closed door collision | PASS for doorway ray | Closed moving door blocks the doorway. Chase/doorway-jamming stress tests remain |
| Noise investigation | PASS | Real door use emits noise; ghost moves over five metres and searches near source while player waits unseen upstairs |
| Local two-process multiplayer | PASS, bounded case | Listen server and separate client: remote Use opens cupboard, pickup is server-authorized, inventory/discovery reaches client; network-server.json and network-client.json |
| Windows visual capture | INSPECTED, development art | unreal-stairs.png and unreal-cupboard-key.png; RTX 3050/D3D12, 1280×720. This is not final art approval |
| Audio/touch/extended multiplayer | NOT VERIFIED | No headphone listening, physical touch, four-player session, late join, disconnect, long chase or hiding tests yet |
| Android/iOS | NOT BUILT | No Unreal APK/IPA; Android toolchain and real ARM64 phone testing remain; iOS also needs Apple build/signing setup |
| Final room art approval | NOT REQUESTED | Technical section only; full house composition and final visuals remain unfinished |

Evidence files are under docs/evidence. Both installers completed successfully. Unreal is installed at D:\UE_5.7 and C++ tools at E:\WaitingForDawnTools\VS2022. Generated caches and binaries are excluded from source control.

Real testing found and corrected UE 5.7 build settings, replication macro parameter names, module header paths, a multi-root ghost skeleton, unsaved FBX dependencies, unattended Interchange import crashes, missing commandlet audio-decoder initialization, 100× mesh scale errors, Python rotator argument order, crouch eye-height mismatch, and an arrival check that could leave the ghost stopped outside its searching state. The traversal probe freezes the ghost before movement; the noise phase restores normal AI. Screenshots come from the game renderer, not Blender.

Remaining game scope: full multi-floor house and room dressing, final home/lobby/icon UI, twelve-key progression, garage/car escape and ending, hiding/peek animations, revive, story introduction, final ghost/art/audio work, mobile controls and device performance. **No claim of a complete game, final graphics or phone readiness is made.** The existing Godot release is unchanged.

Reproduce with tools/Build.ps1 actions Editor, Tests and Gameplay, plus tools/Test-Network.ps1. The map builder refuses to overwrite an authored map; use a new WD_MAP_NAME when regenerating. Test drivers are opt-in and their flags cannot activate them in Shipping builds.
