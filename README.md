# Waiting for Dawn

Explore Eleanor's house with up to four survivors. Search the furniture, follow the keeper's letter, hide when she approaches, and unlock the garage and car before dawn.

The current project is the **Unreal Engine 5.7.4 rebuild, version 0.9.4** under [`unreal/`](unreal/README.md). It contains a four-storey house with 16 rooms, three physical stair flights, twelve dependent keys, animated containers, wardrobe/bed hiding, noise-driven ghost pursuit, a narrated skippable opening, four difficulty settings and a car escape ending.

Version 0.9.4 replaces the cartoon launcher icon with original cinematic horror artwork: Eleanor over the house at dawn. Android adaptive masking and all fallback densities are included. See the [icon release notes](unreal/docs/RELEASE-0.9.4.md) and [artwork source and prompt](design/icon-094/PROMPT.md).

Version 0.9.3 adds four car seats, explicit boarding and engine controls, team departure checks and synchronized vehicle movement. It repairs portrait hinges, the car's forward direction and garage clearance, and fixes state/input issues found in the component audit. Eleanor's Blender redesign is retained. See the [release notes](unreal/docs/RELEASE-0.9.3.md) and [editable art source](design/eleanor-092/).

## Android download

Get the ARM64 APK from the [Unreal 0.9.4 release](https://github.com/singusathwik/WaitingforDawn/releases/tag/unreal-v0.9.4). This is a development-signed preview, installed separately from the older Godot app. It requires Android 8 or newer and a supported Vulkan or OpenGL ES 3.2 GPU. Actual physical-phone compatibility and sustained performance still need testing.

## Play and build

- [Unreal controls, multiplayer setup and build instructions](unreal/README.md)
- [Executed validation and remaining limits](unreal/docs/VALIDATION.md)
- [Asset credits and licenses](ASSETS.md)

Co-op uses direct IPv4, normally over the same Wi-Fi or hotspot. A private VPN is an external option for friends in different locations; see [REMOTE-PLAY](unreal/docs/REMOTE-PLAY.md) for setup and the cross-location testing limit. There is no built-in internet matchmaking or host migration. Collect the twelve shared keys, raise the garage door, have every surviving teammate **board the car**, then press **Start Engine** before dawn. Get Out remains available before departure. Key locations are fixed.

The earlier Godot implementation remains in the repository for history and source assets. Its documentation is preserved in [LEGACY_GODOT.md](LEGACY_GODOT.md); its APKs and test results do not describe the Unreal rebuild. iOS has not been built or tested for the Unreal version.
