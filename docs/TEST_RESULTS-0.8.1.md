Historical 0.8.1 evidence. Runtime was approved by the user, then superseded by reported playtest defects; this candidate was not published.

# Waiting for Dawn 0.8.1 validation � 18 October 2026

## Local candidate

Signed Android APK: **105,034,370 bytes**, version code **9**, version **0.8.1**. Package `org.hollowhouse.lastride`, minimum SDK 24, target SDK 35, arm64-v8a and x86_64. APK SHA-256: `f93f10bbc39de07c06a52314dbce6f3b19690e15b4d0e7f7c2a020888224a5a2`. Windows executable SHA-256: `560afa153f52b243aafb50819849ae2e2c15e0d7bb77b4d0a38ed386d735e52d`.

`apksigner verify --print-certs` passed; retained certificate SHA-256 `a60346ef9fa95c931ce67f3774d9d8bba44e02bf3c1c7a7f8e526f3a2b74bb76`. [Build metadata](docs/validation-0.8.1/build.json), [signature](docs/validation-0.8.1/signature-081.txt), [manifest](docs/validation-0.8.1/manifest-081.txt). Human Runtime approval is pending before publication.

## Executed checks

The complete `scripts/test.ps1` regression completed with exit code 0. [Full log](docs/validation-0.8.1/tests-081-final.log). It covers rules, two/four-process ENet matches, movement, ready state, departures, capacity, version mismatch, connection timeout, late joining, repeated rounds, shared key pickup, revival, team boarding, synchronized victory, all-down defeat, difficulty, stamina, noise timing, door physics/sight/ghost routes, hiding occupancy and witnessed capture, letters, scare lifecycle, 81 search locations, the twelve-key dependency chain, crypt locks, dawn timeout/reset and remote drawer replication. iOS checks cover configuration only.

New room checks verify 16 imported meshes, 12 native drawer bindings, both texture tiers, navigation to each dresser, partition occlusion, cupboard and bed entry/exit and camera positions, basement-only torch behavior, the keyboard F shortcut, and input before the bag exists.

[Physical traversal](docs/validation-0.8.1/traversal-081.log) walked a real CharacterBody3D through all twelve ordered keys, opened the garage and boarded the car, reaching `phase=escaping`. The fixture disables the ghost and extends the clock; this establishes collision/progression access, not human survival difficulty. Ending fixtures separately verify victory and failure.

## Final APK

Installed and launched the signed candidate on Wired_API35, Android 15, with the host GPU. The actual game viewport was captured using an in-game fixture and a loopback collector. Nursery, dresser, wardrobe slit, under-bed view and both texture tiers were visually inspected. The fixture rejects shader errors, missing images and flat/blank 3D captures. These checks use game test drivers, not a new manual touch playthrough.

![Android nursery](design/rooms/eleanors-nursery/runtime/nursery-view.png)

The final APK joined a Windows host through `10.0.2.2`. The Android client aimed at and opened a native nursery drawer through the normal action RPC, received the key, open state, teammate notification and shared clock, then verified duplicate protection, restart and departure. [Host](docs/validation-0.8.1/android-host.log), [client](docs/validation-0.8.1/android-client.log).

## Art and performance

Native Blender checks: 84,020 triangles, 204 opening/low-trim rays, 28 independent furniture collision pairs, floor/ceiling support checks, packed textures and 14 animation roots. Delivery: 83,876 triangles, 16 meshes, 4,463,300-byte GLB, shared geometry with 4096/2048 atlases. Hashes, UVs, mipmaps, VRAM compression settings and the fixture manifest passed [integrity checks](design/rooms/eleanors-nursery/runtime/integrity.json).

Static surfaces use combined baked color/light. Runtime practicals illuminate actors within the existing nearest-three-light budget. The room does not receive dynamic shadows or provide full native-Blender material parity. The 4096 atlas's 8-bit-per-pixel compressed upper bound including mipmaps is about 21.33 MiB; the whole game uses more memory.

Short 15-second samples after a three-second warmup: Windows RTX 3050 and the hardware-GPU Android emulator reported 900 and 901 frames respectively, p50/p95 16.67 ms (60 FPS), 105 draw calls in the fixed nursery view. Reported whole-game texture allocation was 131,409,235 bytes on desktop and 141,516,086 on Android. These capped, stationary samples are not sustained physical-phone benchmarks. [Desktop log](docs/validation-0.8.1/benchmark-081.log), [Android log](docs/validation-0.8.1/android-nursery-benchmark.log).

## Problems found and corrected

Boolean-cut wall trim left low collision bars; rebuilt trim segments and added near-floor ray checks. A 1.5 m navigation grid now reaches the offset internal openings, with capsule clearance pruning for flat room links. Stair connectors are preserved because their nav heights approximate the ramp. Trimmed a 0.2 m floor overhang that trapped the capsule at the stair landing. The full physical route passed after these changes. Early input now tolerates the bag not yet existing, and F actually invokes the flashlight action.

SwiftShader emulator rendering failed with shader-link errors and blank frames. It was rejected, not counted as a visual pass. Switching the emulator to the host GPU resolved the captures; a recoverable shader-cache recompile warning remained. This corresponds to an [upstream SwiftShader compatibility issue](https://github.com/godotengine/godot/issues/109550), not a claimed engine fix.

## Remaining qualification

No physical-phone performance, thermal/battery, headphone listening or phone-to-phone Wi-Fi qualification. No signed/tested iOS binary. This upgrade covers the nursery wing; other rooms, the adapted creature and the narrated in-engine opening retain their existing art. No Internet matchmaking or host migration. No commercial-quality or five-star certification is claimed.

Historical evidence: [0.8.0](docs/TEST_RESULTS-0.8.0.md), [0.7.0](docs/TEST_RESULTS-0.7.0.md).
