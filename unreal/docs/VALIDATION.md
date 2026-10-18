# Unreal rebuild checkpoint — 2026-10-18

This records the new Unreal project only. Godot 0.8.3 test results are **not** Unreal evidence.

| Check | Result | Evidence / limit |
|---|---|---|
| Project descriptor and Python authoring syntax | PASS | `evidence/source-validation.json`; no Unreal compilation implied |
| Stair/landing support model | PASS | 2,586 mathematical support probes along the route, including side samples; engine collision pending |
| Blender conversion | PASS | 13 actual FBXs; 33,506 static triangles; ghost retains 41 bones |
| FBX reimport | PASS | All 13 exports reopen as meshes; static dimensions agree within 1 cm; `evidence/roundtrip-audit.json` |
| Editable furniture file | PASS | Reopened in Blender 4.3.2 with scripts disabled; separate shell and hinged leaves present |
| Furniture visual inspection | PASS for hollow interior only | `evidence/cupboard-inspection.png` is a **Blender inspection image**, not an Unreal capture or final art approval |
| Ghost scale | CORRECTED IN IMPORTER, NOT RUNTIME VERIFIED | Measured source height is over eight metres; importer targets 235 cm and compensates the feet origin |
| UnrealHeaderTool / MSVC compile | NOT RUN | Engine download unfinished; Microsoft installer exited `0x80070642` at Windows administrator elevation; relaunch requested from user |
| Native difficulty/noise/stair automation | NOT RUN | Test source exists; engine/toolchain required |
| Actual CharacterMovement on stairs | NOT RUN | Must pass before claiming the reported stairs defect is resolved in Unreal |
| Ghost navigation, door blocking, audible warnings | NOT RUN | Requires generated navmesh and real gameplay |
| Multiplayer and touch controls | NOT RUN | Source replication and development controls exist; two-instance/device validation required |
| Android packaging / phone performance | NOT RUN | No Unreal APK produced; UE Android SDK/NDK/JDK must be configured separately |
| Room Function / Form / Runtime artistic gates | NOT REVIEWED | This is technical layout/asset preparation, not an approved final room or deployed art package |

Unreal 5.7.4 is downloading to `D:\UE_5.7`. The C++ toolchain is planned for `E:\WaitingForDawnTools\VS2022`. Paths can be changed through `tools/Build.ps1 -EngineRoot`.

The build script correctly rejects the incomplete engine installation. Nothing is labeled as a successful Unreal build, complete game or tested APK. The existing Godot release remains unchanged.

Next execution sequence: finish engine and C++ setup, compile, generate `StairHall`, inspect imports and materials, verify navmesh, run native tests, walk/drive actual gameplay inputs, then test two clients. Compile/import fixes may still be needed. The map builder refuses to overwrite an authored map; use a new `WD_MAP_NAME` revision when iterating.
