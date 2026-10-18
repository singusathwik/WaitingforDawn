# Unreal 0.9.1 validation — 2026-10-18

These results describe the Unreal development preview. Automated checks and actual rendered Android captures are recorded separately; they are not a physical-phone certification or an unassisted human playthrough.

## Executed checks

| Check | Evidence and scope |
|---|---|
| Build/package | UE 5.7.4; VS 2022/MSVC 14.44; SDK 22621; real Win64 editor and Android ARM64 builds, ASTC cook and Gradle packaging. APK version 0.9.1/code 10, signature verified. See `evidence/apk-manifest-091.json`. |
| Source/export | `evidence/source-validation-091.json`: 23 verified FBX exports, 65,744 triangles across unique static exports; four floors, 16 rooms and the twelve-key dependency graph. This is not the rendered scene triangle count. |
| Native automation | `evidence/native-tests-091.json`: 5 successes, 0 failures. Difficulty, earliest noise deadline, story/dawn/escape rules, stair collision and cancellable attack timing. |
| Windows campaign | `evidence/campaign-win64-091.json`: 67 checks; twelve keys, all three stair flights physically walked both ways, zero fall recoveries, hiding and car ending. |
| Android campaign | `evidence/campaign-android-091.json`: the installed ARM64 APK passed the same 67 checks on API 35 with host Vulkan graphics, including the ghost opening a closed room door and entering to search after a noise. |
| Ghost encounter | `evidence/threat-win64-091.json` and `evidence/threat-android-091.json`: 8 checks on each platform. Full-sized animated body, more than 8 metres of actual corridor pursuit, attack wind-up, actual sprint movement out of reach, ceiling bounds, face-framed capture and subsequent loss. |
| Android visual inspection | `evidence/android-screens-091/`: actual 2400 × 1080 emulator captures of approach, chase, ceiling pose and capture. These are game renders, not Blender images. |
| Four-process co-op | `evidence/network-win64-091/`: host and three independent Windows clients. Remote drawer/key use, hiding, shared inventory, late join, ending replication, disconnect cleanup and new ghost/door state replication passed. |
| Android/Windows co-op | `evidence/network-android-windows-091.json`: packaged Android client joined a Windows host through Home → Join with friends → entered IP → Join house. Actual remote use, pickup, hiding, ghost/door state receipt and disconnect cleanup passed without a protocol override. |
| Audio production | `../Audio/provenance.json`: source licenses/hashes, four output hashes, durations and bounded waveform peaks. The 36-second introduction uses Kokoro narration; the narrator is still synthetic. Breath/scream effects use processed CC0 human recordings. |

## What the tests establish

The campaign uses the real Use selection, locks and pickup code, checks visible keys and duplicate prevention, enters/leaves both hiding types, reads the keeper's letter and validates navigation to all floors and key approaches. A noise attracts Eleanor to a closed room; she must wait, open its door, enter and search. The test then exercises garage gating and the car escape. It teleports between room fixtures while physically walking each stair flight. It does not establish that every route has been exhaustively walked or that an unaided player can solve the game.

The encounter probe runs actual chase AI and CharacterMovement during the approach and sprint escape. Ceiling positioning and capture framing then use controlled fixtures; those portions do not prove unrestricted climbing or an emergent attack at every location. Separate native assertions cover attack timing. Network probes use controlled host fixtures for ghost appearance flags and the ending; the campaign exercises the complete key/garage/car sequence. The four-process test is loopback, and Android/Windows uses the emulator's virtual network.

## Root cause and repairs

In 0.9.0, all five animation clips overwrote Eleanor's master-root bind scale (395.7522) with 1.0. The animated body shrank almost 396 times while the collision capsule remained full-sized. The previous static ghost-art view disabled animation ticking, so it failed to detect this. `evidence/ghost-animation-scale-091.json` records the before/after correction. The new encounter test rejects an animated body smaller than human scale.

The repaired encounter includes a 1.8-second spotting pause, slower-than-sprint chase, a cancellable 0.95-second attack wind-up, a 2.3-second face-framed capture, slow audible door opening, full-screen danger tint and same-floor proximity breathing. Skin and fabric retain texture in low light. The Android compiler also caught ambiguous indentation in the new camera block; explicit braces fixed it before the successful package.

## Limits and earlier evidence

No physical Android phone, multi-phone Wi-Fi session, sustained thermal/battery test or iOS build was available. Emulator graphics use the host GPU and ARM64 translation; these results are not phone performance measurements. Headphone listening balance and whether the new synthetic voice meets the player's preference remain subjective and unverified.

Ceiling crawling is a visual pose beneath traced hallway ceilings over the existing ground navigation; it is not arbitrary wall-climbing AI. The game has fixed key locations, no save/resume, no revive, no host migration and no internet relay. Co-op models remain Epic template mannequins, the ghost is an adapted credited model, and hiding uses a camera transition and view mask. The accepted house geometry was retained in this repair.

Files without the `091` suffix include historical 0.9.0 results. In particular, the older static ghost-art, full room-tour and touch-smoke evidence must not be used to claim that the old animated ghost was visible. The current Android join flow and new animated encounter were exercised again for 0.9.1.

See [../README.md](../README.md) for controls, build steps and device requirements.
