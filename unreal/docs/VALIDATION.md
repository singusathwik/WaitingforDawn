# Unreal 0.9.4 icon update validation

This release changes Android launcher artwork and version metadata. Gameplay source and content have no changes from 0.9.3. The packaged `libUnreal.so` has exactly the same SHA-256 as the 0.9.3 APK. The broader gameplay, car escape and multiplayer evidence is preserved in [VALIDATION-0.9.3.md](VALIDATION-0.9.3.md); those suites were not unnecessarily repeated for this artwork update.

## Executed checks

- UE 5.7.4 Android ARM64/ASTC packaging completed successfully.
- APK version 0.9.4/code 13, API 26 minimum/API 35 target, original package name, and APK v2 signature verified. Development signing is retained.
- Decoded all seven packaged fallback icons (36, 48, 72, 96, 128, 144 and 192 pixels) and the 512-pixel adaptive artwork. Their RGBA pixels exactly match the exported resources.
- Inspected compiled adaptive-icon XML and confirmed Android resolves the application icon to it.
- Installed 0.9.3/code 12 on an isolated API 35 emulator, then upgraded to 0.9.4/code 13 with `adb install -r`; both succeeded.
- Visually inspected the actual launcher app-drawer icon at its circular display size. The face remains visible, with no old cartoon icon or baked border.
- Tapped that launcher icon, dismissed Android's first-run fullscreen tip, reached the home screen, pressed Play and Skip Story, and reached gameplay. Captured the launcher, home and running game.

Package hashes and resource checks: [apk-manifest-094.json](evidence/apk-manifest-094.json). Upgrade and startup record: [icon-launcher-094.json](evidence/icon-launcher-094.json). Actual emulator captures: [icon-android-094](evidence/icon-android-094/).

## Scope and limits

The emulator uses ARM64 translation and host Vulkan. This confirms the tested launcher and startup path, not every phone/OEM launcher or physical-device performance. No separate monochrome themed-icon layer is supplied. Existing gameplay, audio, iOS and cross-location multiplayer limits from the 0.9.3 report still apply.

The original generated master, exact prompt and reproducible export instructions are in [design/icon-094](../../design/icon-094/PROMPT.md). The built-in image generator created the illustration; Godot performs offline resizing only.
