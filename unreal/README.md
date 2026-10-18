# Waiting for Dawn — Unreal 0.9.2

A playable Unreal Engine 5.7.4 horror survival development preview for Android ARM64 and Windows. Explore Eleanor's house, collect twelve shared keys, open the ground-floor garage and bring the surviving team to the car before dawn. This is the Unreal rebuild; the earlier Godot game remains at the repository root.

## The house and game loop

- Basement, ground floor, nursery floor and bedroom floor: 16 rooms and three physical stair flights, with collision guards and landings.
- Original Blender furniture, hollow animated drawers, wardrobes, beds, cradle, armchair, keeper, kitchen, car, portraits, carpets and scattered debris. Imported assets are saved in the actual Unreal map.
- Twelve keys with dependencies, 96 drawers and two hinged portraits. Key locations are authored, not randomized. Opening a container exposes its key; taking it is a separate interaction. The shared bag and discovery messages update for the team.
- Sixteen wardrobe hiding spots and four under-bed spots. The camera enters the hiding space with a restricted view. Hiding before being seen matters; a closed room door buys time while the ghost rattles and opens it. She cannot unlock progression gates or open hiding furniture.
- Noise investigation, patrol, search and chase. Repeated sounds cannot indefinitely postpone the ghost's response. Door/drawer actions, thrown bottles and loose boards attract attention. Ordinary footsteps are silent; board creaks require distance travelled and an uneven-floor zone.
- Full-sized animated ghost, a visible spotting pause, corridor pursuit and a cancellable attack wind-up. Sprinting is faster than her chase on all difficulties. She floats slightly and sometimes crawls beneath hallway ceilings; this is a visual pose over ground navigation, not arbitrary wall traversal.
- Eleanor's 0.9.2 Blender redesign replaces the old head and body with a gaunt face, long layered hair, ragged nightdress and hooked nails. Her credited arm geometry and animation rig are retained. The 30,499-triangle mesh uses eight opaque material slots and two baked 1K maps; the face source texture was generated and projected in Blender.
- A 36-second narrated, skippable in-engine opening, with no ghost reveal. The keeper's letter appears in an aged-paper journal. Retry skips the introduction.
- Flashlight on every floor, a dark basement, intermittent light flicker, recorded-source proximity breathing and a translucent full-screen red danger wash. A face-framed capture precedes the loss screen. Catching the last survivor or reaching dawn loses the round; the garage and ignition keys enable the car ending.
- Easy, Normal, Hard and Extreme: 40, 32, 26 and 20 minutes; initial noise response delays of 6, 4.5, 3 and 2 seconds.

## Play

Android uses a left joystick, right-side look dragging, circular action buttons, bag/journal controls and a stamina bar. The home screen offers Play, Join with friends and Exit. Pick difficulty before Play. For LAN co-op, one player hosts, and the others enter that host's local IP while connected to the same Wi-Fi or hotspot. Android and Windows use UDP port 7777. There is no internet relay, NAT traversal or host migration.

Windows: WASD move, mouse look, E use, F flashlight, Left Ctrl crouch, Left Shift sprint, Q throw, I bag, J journal, Escape menu. Click Play/Join on the home screen. Start, skip and retry are controlled by the host.

The Android preview uses package `org.waitingfordawn.unrealpreview` and installs separately from the legacy Godot app. It is a Development build with development signing, not a Play Store submission. ARM64, Android 8/API 26 or newer, and a compatible Vulkan or OpenGL ES 3.2 GPU are required. The packaged manifest and tested emulator are recorded in the validation report; minimum API is not a promise of acceptable performance on old phones.

## Build

Requires UE 5.7.4 with Android support, VS 2022 C++ tools and Windows SDK 22621. Android uses OpenJDK 21, SDK 35, build-tools 35.0.1 and NDK 27.2.12479018. Configure tool locations in `tools/Build.ps1` for another computer.

```powershell
./unreal/tools/Build.ps1 -Action Check
./unreal/tools/Build.ps1 -Action Editor
./unreal/tools/Build.ps1 -Action Tests
./unreal/tools/Build.ps1 -Action Campaign
./unreal/tools/Test-HouseNetwork.ps1
./unreal/tools/Build.ps1 -Action Android
```

`Content/Maps/House.umap` and imported assets are committed and can be opened directly. To regenerate art, run Blender with `tools/prepare_assets.py` and `tools/prepare_nursery_props.py`, then `tools/Rebuild-House.ps1`. Export staging is generated and ignored. Run one map rebuild at a time. Use the saved map for ordinary builds.

The rebuild wrapper also restores the ghost's master-root bind scale in all five animations and imports the 0.9.1 materials/audio. Do not reimport the original animation clips without this repair. Narration and sound provenance are in `Audio/provenance.json`; `tools/prepare_audio_091.py` documents optional regeneration using an external Kokoro model. The already generated audio is included, so that model is not required to build the game.

The wrapper then imports the 0.9.2 ghost from `../design/eleanor-092/SK_EleanorDread.fbx`. To regenerate that character, run Blender 4.3.2 in background mode with `tools/sculpt_eleanor_092.py`, then run `tools/import_eleanor_092.py` through Unreal's Python commandlet. The packed editable `.blend`, generated face source, baked maps and exact texture prompt are in the art folder. The importer recreates only the generated mesh, checks centimetre bounds/bind transforms and verifies that the five existing animation clips and skeleton retain their hashes. It reuses the rig's established full-body physics bounds. This avoids unit conversion changes in legacy FBX reimport and partial bounds from automatically fitting the new clothing.

## Validation and limits

See [VALIDATION.md](docs/VALIDATION.md) and the checked-in evidence. The campaign probe exercises the real interaction code and physically walks all stairs in both directions, but teleports between room fixtures; it is not an unassisted human playthrough. Network probes use separate processes and check authoritative use, shared state, late joining and disconnect cleanup.

Physical-phone Wi-Fi sessions, touch comfort, sustained performance, thermals and device compatibility still need real-device testing. iOS has not been built or tested. There is no save/resume, revive system or internet matchmaking. Co-op bodies use recognizable Epic template mannequins, the narration is synthesized, hiding entry uses a camera transition, and the artwork remains an independently produced development preview rather than photorealistic commercial character art.

Asset provenance and licenses: [ASSETS.md](../ASSETS.md). No commercial horror-game assets or reference screenshots are bundled. Epic template examples retain Epic's license.
