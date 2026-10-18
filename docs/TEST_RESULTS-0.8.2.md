# Waiting for Dawn 0.8.2 validation — 18 October 2026

## Executed gameplay checks

The [full regression suite](docs/validation-0.8.2/full-suite.log) passed during this repair. It covers rules; two/four-peer ENet sessions; ready state; movement; departures; version mismatch; capacity; timeouts; late joining; repeated rounds; shared pickup races; revival; all-survivor boarding; synchronized victory; defeat; difficulty/stamina; doors; hiding; clues; 81 compartments; twelve dependent keys; crypt access and dawn timeout/reset.

After changing the garage exit, the [four-peer ending/restart fixture](docs/validation-0.8.2/four-peer-coop.log) and [full twelve-key physical route](docs/validation-0.8.2/twelve-key-traversal.log) passed again. The route drives a CharacterBody3D through the actual stairs and furniture layout and reaches `phase=escaping`. It opens approach doors, disables the ghost and extends the clock; it establishes access, not a balanced human survival playthrough. [All-floor traversal](docs/validation-0.8.2/walk-all-floors.log) includes both directions and the crypt.

[Repair regressions](docs/validation-0.8.2/repair-regressions.log) verify Play closes the menus, the ghost stays hidden throughout the opening, Skip restores controls/grace, retry does not replay the story, the ghost leaves its spawn, a noise attracts it into the hallway, it follows open stairs to nursery/bedrooms/basement, closed doors block it, cupboard/bed entry and cameras work, the upstairs torch works, the basement is dark without it, the outside garage key plate raises the shutter, side boarding triggers escape, the car drives outside, and retry resets car/locks. Separate search tests exercise opening, closing, reopening and visible-key collection.

## Android package and rendering

Package `org.hollowhouse.lastride`, version **0.8.2**, code **10**, minimum SDK **24**, target **35**, arm64-v8a and x86_64. Size/hashes are in [build.json](docs/validation-0.8.2/build.json); [manifest](docs/validation-0.8.2/manifest.txt) and [signature](docs/validation-0.8.2/signature.txt) record final package verification. The signing certificate is retained, so it can update the previous signed build.

The APK installed and ran on Wired_API35 / Android 15 using the host GPU. In-game fixtures captured **2400×1080** images for the home, kitchen, garage, hollow drawer/key, stairs, exterior, native nursery, cupboard slit, under-bed view and both nursery texture tiers. The viewport expands to 20:9 rather than rendering fixed-aspect sidebars. The collector checks dimensions, errors, image delivery and nonblank 3D content. Captures were visually inspected; these are scripted game-camera views, not a manual touch playthrough.

The last change added texture and exterior ribs to the shutter. That final APK was reinstalled and its exterior capture and Android-to-Windows network fixture rerun. Earlier captures cover the same 0.8.2 gameplay/room assets; build.json records the earlier full-render APK hash separately.

The Android client joined a Windows host, aimed at and opened a native drawer through the action RPC, received the key/open state/team notification/shared clock, then verified duplicate protection, restart and host departure. [Host](docs/validation-0.8.2/host.log), [client](docs/validation-0.8.2/client.log), [run](docs/validation-0.8.2/android-network-run.log).

## Rendering and performance limits

The 15-second stationary nursery sample reported 864 frames, p50 **16.67 ms**, p95 **20.83 ms**, 510 draw calls and 158,242,256 bytes of reported texture allocation. It ran on the hardware-GPU emulator backed by an RTX 3050; it is not a physical-phone benchmark. [Log](docs/validation-0.8.2/nursery-benchmark.log). A recoverable cached-shader warning caused recompilation; no blank viewport or fatal/script error was accepted.

Desktop flashlight shadow maps produced diagonal self-shadow bands on thick walls. This build uses the same shadowless camera spotlight on desktop and Android, plus bounded practical lights; exterior moonlight affects exterior-layer meshes without brightening the basements. The nursery retains baked color/light and does not have full dynamic-shadow parity with Blender.

The new original GLBs and editable Blender source are included in [the repair package](design/repair-082/README.md). Their modest mobile geometry, including the car, does not match the photorealism of the supplied references.

## Not verified

No physical-phone manual playthrough, sustained thermal/battery profiling, headphone listening or phone-to-phone Wi-Fi/hotspot test. No signed or tested iPhone binary; [iOS checks](docs/validation-0.8.2/ios-config-only.log) verify configuration only. No Internet relay or host migration. The automated route and network passes do not prove every possible movement sequence or subjective visual quality.

Historical evidence: [0.8.1](docs/TEST_RESULTS-0.8.1.md), [0.8.0](docs/TEST_RESULTS-0.8.0.md).
