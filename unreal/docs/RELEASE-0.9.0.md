Waiting for Dawn has been rebuilt in Unreal Engine 5.7.4. This Android ARM64 development preview contains the full four-storey house and a playable escape loop.

- Sixteen rooms: basement, ground-floor garage, nursery floor and bedroom floor; three physical stair flights.
- Twelve dependent, shared keys; hollow animated drawers and searchable portraits; bag and team discovery messages.
- Wardrobe and under-bed hiding; closed doors block the ghost; noise starts investigation, search and pursuit.
- Skippable narrated opening, keeper's letter, four difficulty settings, dawn deadline, capture/loss and garage/car escape.
- Fullscreen mobile controls, flashlight on every floor, dark basement, light flicker, breathing and danger cues. Actual Blender furniture, cradle, armchair, keeper and textured animated ghost are in the Unreal map.

Validation: 4 native automation checks; 68-check Windows and installed-Android campaign runs with twelve keys and zero stair recoveries; four-process multiplayer with late join/shared ending/disconnect checks; packaged Android client connected to a Windows host without a protocol override. Automated campaign runs walk the stairs and use real interactions, but teleport between room fixtures. See the repository's `unreal/docs/VALIDATION.md` and evidence for the precise scope.

Download `WaitingForDawn-Unreal-0.9.0-arm64.apk`. Package: `org.waitingfordawn.unrealpreview`, version 0.9.0/code 9. It installs separately from the old Godot game. ARM64 Android 8/API 26 or newer and compatible Vulkan or OpenGL ES 3.2 graphics are required. This is a development-signed APK, not a Play Store release.

Co-op: connect to the same Wi-Fi/hotspot. One player selects Join with friends → Host a house; the others enter the host's local IPv4 address. The host chooses Play. Maximum four survivors; gather living teammates at the car before escaping. There is no internet relay or host migration.

Physical-phone performance, thermals, touch comfort and multi-phone Wi-Fi compatibility remain unverified. Android testing used an API 35 emulator with ARM64 translation and host Vulkan graphics. iOS is not built. Character art still includes template co-op mannequins, narration is synthesized, and no save/resume or revive system is included. This release should not be mistaken for a finished commercial-quality or device-certified game.
