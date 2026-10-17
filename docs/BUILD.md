# Reproducible toolchain and exports

Pinned engine: **Godot 4.5.2 stable official, commit 6ce3de25a**, standard GDScript build. Matching template identifier: **4.5.2.stable**. Compatibility renderer (OpenGL ES 3.0 on Android), one shadowless camera spotlight, imported skeletal meshes and bundled PBR textures.

Official downloads:

- https://godotengine.org/download/archive/4.5.2-stable/
- https://github.com/godotengine/godot-builds/releases/download/4.5.2-stable/Godot_v4.5.2-stable_win64.exe.zip
- https://github.com/godotengine/godot-builds/releases/download/4.5.2-stable/Godot_v4.5.2-stable_export_templates.tpz
- Export reference: https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_android.html

Existing tools reused: OpenJDK 17.0.20.1+1, Android SDK platform/build-tools 35 and platform-tools. Standard APK template export does not need a custom Gradle or NDK build. The package manifest resolves to minimum SDK 24, target SDK 35. The APK includes arm64-v8a and x86_64 (the latter enables emulator testing); 32-bit-only phones are not supported.

## Fresh machine

1. Download the pinned editor and matching export templates. Install the templates through Godot's template manager, or extract `templates/*` into `%APPDATA%/Godot/export_templates/4.5.2.stable/`.
2. Install OpenJDK 17 and Android SDK platform-tools/build-tools 35/platform 35. Set Godot **Editor Settings → Export → Android → Java SDK Path / Android SDK Path**.
3. Open `project.godot`, allow import, then run it. The source has no third-party add-ons or asset downloads.
4. Export Android using the `Android` preset. For a CLI development build:

```powershell
.\scripts\build.ps1 -Godot 'C:\tools\Godot_v4.5.2-stable_win64_console.exe'
```

On the original workstation, editor and template archives are cached under `%USERPROFILE%/.cache/hollow-house/`; SDK/JDK are under `%USERPROFILE%/.cache/wired-android/`. The build script does not download or install dependencies.

## Distribution signing

The release keystore and its password file are outside this project at `%USERPROFILE%/.cache/hollow-house/signing/`. Back them up securely to preserve update compatibility. Do not distribute them with the source or APK. The local key alias is `hollowhouse`.

Set these environment variables in the build process, then call `scripts/build.ps1 -Release`:

- `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`
- `GODOT_ANDROID_KEYSTORE_RELEASE_USER`
- `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`

The script requires all three for release mode and never stores them in the export preset. Android's `apksigner verify --print-certs` verifies the result. `Get-FileHash -Algorithm SHA256` generates the checksum. Signing is for local APK distribution, not Play Store publication.

## Verification commands

```powershell
.\scripts\test.ps1 -Godot 'C:\tools\Godot_v4.5.2-stable_win64_console.exe'
& 'C:\tools\Godot_v4.5.2-stable_win64_console.exe' --headless --path . -- --test=traverse
& 'C:\tools\Godot_v4.5.2-stable_win64_console.exe' --path . -- --test=benchmark
```

Run host-based suites **sequentially**: all intentionally use UDP 28741. The traversal fixture drives a real CharacterBody3D through all twelve randomized objective locations and the exit, with the ghost disabled and time accelerated. The benchmark is a short stationary rendered desktop sample, not an Android performance qualification.

The server simulates at the Godot physics tick. Clients submit bounded input at 20 Hz; the server sends 20 Hz ordered unreliable movement snapshots. Important progress/door/outcome events are reliable. Movement is interpolated without client prediction, favoring correctness on a local network over latency masking. The host owns keys, AI, doors, outcomes and bottle counts; clients cannot submit arbitrary positions or noise radii.

## Art source rebuild

Runtime GLBs and all texture maps are included; ordinary Godot export does not need Blender or network access. To regenerate art, run Blender 4.3.2 in background mode with `--python scripts/convert_character.py`, then `--python scripts/build_architecture.py`. The character script reads the included `source_art/rosswet` files. Poly Haven downloads can be reproduced with `python scripts/fetch_art.py` (requests required). Asset attribution must accompany redistributed builds and source.

## iOS

See [iPhone build and device qualification](IPHONE.md). The iOS preset requires your Apple team ID and a Mac with Xcode. Windows regression tests do not qualify an iOS release.
