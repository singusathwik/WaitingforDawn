# Unreal 0.9.3 gameplay audit

These are bounded automated checks, not proof of a bug-free game, an unassisted human playthrough or physical-device certification. Prior evidence is preserved in [VALIDATION-0.9.2.md](VALIDATION-0.9.2.md).

## Executed checks

| Check | Evidence and scope |
|---|---|
| Native rules | `evidence/native-tests-093.json`: six passed, zero failed. Difficulty, noise deadlines, attack grace, story/dawn/end rules, stair collision and strict address parsing. |
| Source/assets | `evidence/source-validation-093.json`: four-storey layout, twelve-key dependency graph, 23 FBX exports and the ghost's mesh, textures and protected animation/skeleton hashes. |
| Windows component sweep | `evidence/component-audit-win64-093.json`: 275 checks. All 20 hiding spaces enter/exit; all 98 searchable drawers/portraits and all 16 room doors open/close. Lobby/story guards, bottle cooldown, blocked hide exit, caught occupancy cleanup and last-survivor loss. |
| Android component sweep | `evidence/component-audit-android-093.json`: the same 275 checks passed in the final APK, including every hiding space, searchable container and room door. |
| Windows campaign | `evidence/campaign-win64-093.json`: 73 checks, twelve actual pickups, three stair flights both directions, zero fall recoveries, all-floor navigation, noise pursuit/door opening, garage, boarding, blocked start, disembark/reboard and departure. |
| Four-player co-op | `evidence/network-four-process-093.json`: four separate Windows processes, remote drawer/key/hiding actions, late joins, unique seats, simultaneous boarding, no abandonment, disembark/reboard, replicated departure and disconnected passenger cleanup. |
| Network impairment | `evidence/network-four-process-093-lag.json`: repeated with 100 ms outgoing packet delay and 2% loss on each process, confirmed in engine logs. Loopback emulation, not an internet test. Rerun after the final passenger-update fix. |
| Map/rendered car | `evidence/map-repair-093.json` and `evidence/car-win64-093/`. Portrait hinges, garage clearance, final cabin and exterior rendered car captures. |
| Android package | `evidence/apk-manifest-093.json`: UE 5.7.4 ARM64/ASTC build, version 0.9.3/code 12, API 26 minimum/API 35 target, APK v2 signature verified and installed on the API 35 emulator. |
| Android car touch interface | `evidence/car-ui-android-093.json` and `evidence/car-android-093/`: actual Get Out, Board and Start Engine touches, moving departure and the victory screen; nine checks. Screenshots were visually inspected. |
| Android full campaign | `evidence/campaign-android-093.json`: 73 checks passed in the final installed APK, all twelve key pickups, three flights in both directions, zero fall recoveries, hiding, letter, navigation, ghost/door noise response, car-sized route clearance and the boarded-car ending. |
| Android ghost encounters | `evidence/threat-android-093.json` and `evidence/android-screens-093/`: eight checks for visible approach, cancellable attack wind-up, sprint escape, ceiling pose bounds and face-framed capture. Approach and capture screenshots were visually inspected. |
| Android to Windows co-op | `evidence/network-android-windows-093.json`: actual Home → Join with friends → entered host IP → Join house. Seven checks on each peer cover remote pickup, hiding, boarding, disembark/reboard and synchronized departure. Emulator virtual networking, not physical Wi-Fi. |
| Normal Android menus/story | `evidence/menu-smoke-android-093.json` and `evidence/menu-android-093/`: normal launch with no gameplay probe flags, difficulty cycle, Play, Skip Story, bag, journal, menu, Resume and Leave House. Actual touch inputs and visually inspected screens. |

The emulator uses ARM64 translation and host Vulkan graphics. These are not physical-phone performance measurements. Its logs contain occasional audio-buffer underruns and collision-trace budget warnings; sound smoothness and frame pacing still need physical-phone validation.

## Bugs corrected

The previous ending only required survivors within six metres of the car. Four replicated seats now provide Board, Start Engine and Get Out. The server requires all living connected players aboard, the ignition key and a fully raised garage door. Caught/disconnected players do not retain required seats. The parked car protects its occupants, but the dawn clock continues. Joining an ended match is rejected.

Car movement previously ran separately on every peer. It now runs on the server and replicates, with passengers following their seats. An Android test exposed one frame of passenger lag at lower frame rates; passenger ticks now follow the car and test probes sample after the passenger update. The imported mesh's forward axis and boarding handle were corrected. A dresser and continuous skirting strip blocked the exit route; both are cleared. The campaign sweeps a car-sized box through the departure route. The Windows campaign preceded the final 180-degree mesh-facing correction; a dedicated rendered car recheck passed afterward. The departure camera now fills wide mobile displays.

Both key portraits previously swung behind their wall, making their close handles unreachable. The component sweep reproduced and verified the repair. Other fixes stop crouched movement after defeat, free a caught survivor's hiding space even when its exit is blocked, discard stale joystick input when opening panels, reject gameplay actions outside Playing and limit retry to completed rounds. Separate players can board simultaneously without a shared furniture cooldown rejecting them.

## Test boundaries

The campaign uses real interaction/lock/pickup code and walks the stairs, but teleports between other room fixtures. The component sweep unlocks keys up front to inspect every searchable object. The network test earns its first key, then grants final keys to isolate boarding; it is not a four-human full campaign. Car visual/touch fixtures grant keys for inspection. These distinctions also apply to Android versions of the probes.

Physical Android phones, four-phone Wi-Fi, independent remote internet connections, sustained thermal/battery tests and iOS were unavailable. External VPN play is documented in [REMOTE-PLAY.md](REMOTE-PLAY.md), not verified across real locations. No built-in matchmaking/relay, host migration, save/resume or revive is implemented. Narration remains synthesized and existing art/audio are retained. Seated pawns occupy four positions; their standing meshes are hidden. Custom seated-body and door-entry animations are not implemented. Departure is scripted, not a player-drivable vehicle.
