# Waiting for Dawn

Explore Eleanor's house with up to four survivors. Search the furniture, follow the keeper's letter, hide when she approaches, and unlock the garage and car before dawn.

The current project is the **Unreal Engine 5.7.4 rebuild, version 0.9.1** under [`unreal/`](unreal/README.md). It contains a four-storey house with 16 rooms, three physical stair flights, twelve dependent keys, animated containers, wardrobe/bed hiding, noise-driven ghost pursuit, a narrated skippable opening, four difficulty settings and a car escape ending.

Version 0.9.1 fixes the animation scale that made the ghost almost invisible. She now visibly approaches, pauses before chasing, and winds up an attack you can escape by sprinting. She can slowly open unlocked room doors. The update also adds a full-screen red danger wash, hallway ceiling-crawl poses, revised narration and recorded-source horror sounds. See the [release notes](unreal/docs/RELEASE-0.9.1.md).

## Android download

Get the ARM64 APK from the [Unreal 0.9.1 release](https://github.com/singusathwik/WaitingforDawn/releases/tag/unreal-v0.9.1). This is a development-signed preview, installed separately from the older Godot app. It requires Android 8 or newer and a supported Vulkan or OpenGL ES 3.2 GPU. Actual physical-phone compatibility and sustained performance still need testing.

## Play and build

- [Unreal controls, multiplayer setup and build instructions](unreal/README.md)
- [Executed validation and remaining limits](unreal/docs/VALIDATION.md)
- [Asset credits and licenses](ASSETS.md)

Co-op uses the same Wi-Fi or hotspot and the host's local IP. There is no internet matchmaking or host migration. The timer ends the round at dawn; collect the garage and ignition keys and gather surviving friends at the car to escape. All twelve keys are shared in the team bag. Key locations are fixed in this version.

The earlier Godot implementation remains in the repository for history and source assets. Its documentation is preserved in [LEGACY_GODOT.md](LEGACY_GODOT.md); its APKs and test results do not describe the Unreal rebuild. iOS has not been built or tested for the Unreal version.
