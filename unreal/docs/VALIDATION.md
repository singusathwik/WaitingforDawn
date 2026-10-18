# Unreal 0.9.0 validation — 2026-10-18

These results describe the real Unreal rebuild. Godot results and Blender stills are not counted as Unreal gameplay evidence. This is a development preview, not a physical-device or store certification.

## Executed checks

| Check | Evidence and scope |
|---|---|
| Toolchain/build | Unreal 5.7.4, VS 2022/MSVC 14.44, Windows SDK 22621. Real editor and Android ARM64 C++ builds, UnrealHeaderTool, cook, ASTC packaging and Gradle assembly. |
| Source/export | `evidence/source-validation.json`: 23 verified FBX exports; 65,744 triangles summed across unique static exports, not the rendered scene. Four floors, 16 rooms, twelve-key dependency graph. |
| Native automation | `evidence/native-tests-090.json`: 4 successes, 0 failures. Difficulty, noise deadline, story/dawn/escape rules, and stair collision fixture. |
| Windows campaign | `evidence/campaign-win64.json`: 68 checks, twelve collected keys, all three stair flights walked both directions, zero fall-recovery teleports. |
| Android campaign | `evidence/campaign-android.json`: the actual installed ARM64 APK passed the same 68 checks, twelve keys, all stair flights both directions and zero fall recoveries on API 35 using host Vulkan graphics. |
| Four-process co-op | `evidence/house-net-*.json`: host plus three independent clients. Remote drawer/key use and hiding, shared inventory, collected-key/open-drawer/occupied-hide state on late join, replicated ending and disconnect cleanup. |
| Android/Windows co-op | `evidence/network-android-windows.json`: packaged Android client connected through Home → Join with friends → typed host IP → Join house, to a Windows Unreal host through the emulator network. Real remote use, pickup, hiding and disconnect cleanup passed; no protocol override was used. |
| Android rendered tour | `evidence/visual-android.json`: real home/opening, seven room views, journal, bag, ghost, capture and loss sequence. Selected actual emulator captures are in `evidence/android-screens/`. |
| Android touch smoke | `evidence/touch-smoke-android.json`: actual touch input for Play, story skip, bag/close, joystick movement, retry without story, journal/fold and menu/resume; rendered results inspected. |

The campaign uses the actual Use selection, lock and pickup code. It checks visible keys after opening, duplicate prevention, both hiding modes, the keeper's letter, real navigation paths between all floors and to each key approach, closed-door obstruction, noise-driven pursuit after opening, all room locks, garage gating and the car ending. It physically walks stairs but teleports between room fixtures. It does not establish that an unaided person can solve the whole game or that every route has been exhaustively walked.

Network ending replication uses a controlled host fixture. The separate campaign tests the complete key/garage/car sequence. The four-process network test is on loopback, not four physical phones.

## Problems caught and repaired

- Stair holes/landing gaps and exterior floor geometry blocking the basement: explicit floor cutouts, landing bridges, guard collision and repeated CharacterMovement traversal.
- Narrow doorways disconnecting the ghost's navigation: widened 150 cm openings, dynamic door navigation and actual closed/open pursuit tests.
- Repeated noises postponing pursuit: retained the earliest pending response deadline.
- Hidden collected keys missing for late joiners: always-relevant replicated interactables.
- Remote Use selecting a neighbouring drawer: the reliable action now includes the player's view direction, with authoritative reach, occlusion, availability and lock checks.
- Editor saves containing unfinished navigation tiles: runtime authority rebuilds navigation on load. An actual Android campaign exposed this after the original Windows run passed.
- Misplaced keeper import pivot and ghost cloth losing its material on repeat import: bounds-based placement and stable imported material-slot names.
- Skeletal materials falling back to the default checker and a broken cloth shader connection: explicit skeletal usage flags, asserted material connections, final packaging without material compile errors and rendered inspection.
- Canvas safe-zone offset leaving a strip and offsetting taps: common viewport coordinates for drawing and touch.
- Duplicate panel hitboxes and a Join panel initialized after Slate selected its root: unique close/resume hitboxes and initialization before widget rebuild.

## Limits

No physical Android phone, four-phone Wi-Fi session, sustained thermal/battery test or iOS build was available. Emulator rendering uses the host GPU and ARM64 translation; it is not a phone performance benchmark. Software-rendered emulator graphics did not meet this Unreal version's Vulkan/OpenGL requirements; the host Vulkan renderer was used instead.

The game has fixed key locations, no save/resume, no revive and no host migration or internet relay. Character art includes Epic template co-op mannequins, narration is synthesized, and the house/vehicle remain modest original game assets. Hiding uses a camera transition and view mask rather than a full first-person body animation. These limitations are not hidden behind automated pass counts.

See [../README.md](../README.md) for controls, supported package requirements and reproduction commands.
