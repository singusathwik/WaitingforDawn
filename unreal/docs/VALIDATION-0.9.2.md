# Unreal 0.9.2 validation — 2026-10-18

This is an art update to Eleanor in the existing Unreal development preview. The results below were executed on the delivered model and APK. They are automated checks and rendered captures, not a physical-phone certification or an unassisted human playthrough.

## Executed for 0.9.2

| Check | Evidence and scope |
|---|---|
| Blender character | `evidence/blender-character-092.json`: 30,499 triangles, 42 bones, 42 skinned mesh objects, every vertex weighted, outward-facing facial polygons and packed source/baked images. The saved Blender file's hash is recorded. |
| Source/export/import | `evidence/source-validation-092.json`: 23 existing FBX exports plus the new character, two baked maps and generated asset hashes. The five repaired animation clips and skeleton retain their hashes. `../../design/eleanor-092/unreal-import.json` records the actual map mesh, materials, shared physics asset and bind bounds. |
| Android package | UE 5.7.4 ARM64/ASTC cook and Gradle build succeeded. Version 0.9.2/code 11; APK v2 signature verified. `evidence/apk-manifest-092.json` records bytes and SHA-256. Installed over the previous Unreal preview on the API 35 emulator. |
| Windows encounter | `evidence/threat-win64-092.json`: 8 checks passed using the final mesh, with actual offscreen rendering. Screenshots are in `evidence/windows-screens-092/`. |
| Android encounter | `evidence/threat-android-092.json`: the same 8 checks passed in the installed ARM64 APK. Actual 2400 × 1080 captures of approach, chase, ceiling pose and capture are in `evidence/android-screens-092/`; all four were visually inspected. |
| Android campaign | `evidence/campaign-android-092.json`: 67 checks passed, twelve visible keys, dependency locks, duplicate pickup prevention, wardrobe/bed hiding, letter, navigation to all four floors, noise-driven pursuit/door opening and garage/car ending. Three stair flights were walked in both directions with zero fall recoveries. |
| Android/Windows co-op | `evidence/network-android-windows-092.json`: the packaged Android client joined a Windows host through Home → Join with friends → entered IP → Join house. Remote use/pickup, shared state, hiding, ghost/door state receipt and disconnect cleanup passed over the emulator's virtual network. No protocol override was used. |

The Android emulator uses ARM64 translation and host Vulkan graphics. Its rendering and timings are not measurements of physical-phone performance.

## What these checks establish

The encounter probe exercises actual chase AI and character movement over more than eight metres, a visible attack wind-up and sprint movement out of reach. Ceiling positioning and capture framing use controlled fixtures; those parts do not prove unrestricted wall climbing or an emergent attack at every location. The campaign uses real interaction/lock/pickup code while teleporting between room fixtures; it physically walks the stair flights. It does not establish that every route was exhaustively walked or that a new player can solve the game without assistance.

The delivered mesh has a modeled face, recessed eyes, hair, sleeves, layered dress, nails and keepsake. The generated face source is projected and baked into the face UVs in Blender. Runtime screenshots confirm that the actual animated geometry is present in the APK, rather than relying on a Blender preview. Hair and cloth are weighted geometry without simulation. Eight opaque material slots avoid alpha-blended hair, but this is an asset budget decision, not a measured phone performance claim.

## Issues caught before release

- Legacy skeletal FBX reimport alternated between metre and centimetre bounds. The importer now recreates only the generated mesh and checks bind scale/transforms before saving the map.
- Automatic physics fitting of the clothing produced partial bounds that failed the encounter regression. The new mesh now reuses the existing compatible rig's full-body physics asset; the gameplay capsule is unchanged.
- Facial polygons initially faced inward. Unreal's backface culling exposed internal mouth/eye geometry, despite the two-sided Blender preview looking intact. The final export has outward facial winding, checked by the Blender validator and by the actual Windows/Android close-ups.
- The face texture initially repeated on the neck. The neck now uses a cloth collar, with internal sockets and teeth positioned behind the facial surface.

## Earlier tests and remaining limits

The gameplay C++ is unchanged from 0.9.1. The five native automation tests, Windows campaign and four-process Windows network run recorded in [VALIDATION-0.9.1.md](VALIDATION-0.9.1.md) were not rerun for this art update. They are historical evidence, not additional 0.9.2 test passes. Current Android campaign/encounter and Android-to-Windows results are listed above.

No physical Android phone, multi-phone Wi-Fi session, sustained thermal/battery test or iOS build was available. Audio/narration was not changed or re-evaluated in this update; the narrator remains synthesized. Ceiling crawling remains a visual pose over ground navigation. Fixed key locations, no save/resume, no revive, no internet relay and no host migration remain. Co-op bodies remain Epic template mannequins. The house geometry was retained.

See [../README.md](../README.md) for controls and build instructions, and [../../ASSETS.md](../../ASSETS.md) for provenance and licenses.
