# Waiting for Dawn 0.8.3 validation — 18 October 2026

## Gameplay and networking

The [full regression suite](docs/validation-0.8.3/full-suite.log) passed on the final gameplay code. It covers two/four-player ENet sessions, movement, pickup races, revival, ready/start/retry, departures, version rejection, capacity, timeouts, endings, four difficulties, hiding, clues, 81 search compartments, twelve key dependencies and the dawn deadline. Door fixtures now aim toward the real handle instead of issuing Use while looking away. These are local automated peers, not four physical phones.

The [new repair checks](docs/validation-0.8.3/repair-083.log) start from Play and Skip with normal default doors and grace. A controlled noise is generated inside a closed room; the ghost must approach, retain that destination for 60 seconds, remain outside the door and enter/catch the exposed player after the normal Use action opens it. The fixture positions the player for this check; it is not an unassisted human survival playthrough.

Floor checks cast **5,137 support probes** across the ground floor and seven upper/basement rooms. Three real CharacterBody3D walks push sideways at formerly exposed landings. A separate forced-fall check verifies recovery to the last grounded position. The exact hole reported by the user remains unidentified; these checks cover the implemented floor/edge repair rather than claiming an exact-location reproduction. A [surface diagnostic](docs/validation-0.8.3/floor-surface-audit.log) also confirms that sampled native nursery floor points had collision even without the added backup slab.

[Earlier-feature regressions](docs/validation-0.8.3/repair-regressions.log) cover intro/skip/retry, cross-floor ghost navigation, cupboard/bed cameras, flashlight, garage shutter, boarding, car departure and reset. Closed room doors intentionally stop entry; the ghost waits outside and can follow once opened. Noise delay is followed by actual travel time, not teleportation.

The [all-floor physical walk](docs/validation-0.8.3/walk-all-floors.log) reached both upper wings and both basement routes. The [twelve-key traversal](docs/validation-0.8.3/twelve-key-traversal.log) collected all keys and reached the car's escape state. These route fixtures disable the ghost and extend the clock to test access; they do not measure human survival balance.

## Android and asset verification

The signed APK is **0.8.3**, code **11**, package `org.hollowhouse.lastride`, minimum API 24, target API 35, arm64-v8a and x86_64. [Manifest](docs/validation-0.8.3/manifest.txt), [signature](docs/validation-0.8.3/signature.txt) and [hashes](docs/validation-0.8.3/build.json). The existing signing certificate is retained.

The signed candidate installed over the previous build on the Android 15 Wired_API35 emulator. All **13 scripted 2400×1080 views** completed without script/fatal errors: home, parlour, kitchen, garage, open drawer, stairs, exterior, native nursery, cupboard, bed, open nursery drawers, low-detail nursery and a nursery performance sample. [Run log](docs/validation-0.8.3/android-render-run.log). Selected actual captures are shown in [runtime review](design/repair-083/runtime-review.html). These are Android game renders, not Blender previews.

A subsequent visual check found the handle ring inside the door leaf. Its offset was corrected, the repair regression rerun, and the final APK rebuilt. That final APK was reinstalled and checked with door/parlour captures and Android-to-Windows networking. The earlier 13-view APK hash was `4df45b1bfbf9234d1424446d36e4f5327eb7d0511df67a4a56fe063f5c047510`; final hashes are in build.json. This last change affects the ring position, not room geometry, gameplay or furniture.

An Android client joined a Windows host and passed native-drawer opening/key collection, replicated state, duplicate protection, restart and disconnect checks. [Run](docs/validation-0.8.3/android-network-run.log), [host](docs/validation-0.8.3/host.log), [client](docs/validation-0.8.3/client.log).

The 15-second stationary nursery sample reported **874 frames, p50 16.67 ms, p95 20.69 ms, 556 draw calls and 158,242,256 texture bytes**. [Log](docs/validation-0.8.3/nursery-benchmark.log). This uses an emulator backed by an RTX 3050; it is not a phone performance/thermal result.

Blender source reopened with **120 editable parts, 138 modifiers and two packed images**. All five GLBs reimported successfully with measured dimensions and triangle counts. Their total file size is 980,252 bytes; runtime materials reuse shared textures. [Reimport report](design/repair-083/reimport-check.json). No paid or third-party game assets were acquired for this repair.

## Limits and failed attempts

An earlier test run exposed the old test's missing handle aim and was corrected. A later run overlapped asset regeneration and failed on stale imported texture dependencies; it was discarded. The complete suite was rerun after imports were stable. The emulator's stale snapshot initially stayed offline, so it was cold-booted before final APK checks.

The Computer plugin was used to launch the released baseline and inspect Play entering the story/game. It was not used for a complete manual touch playthrough of this candidate. Physical-phone touch ergonomics, real-phone Wi-Fi, headphone mix, sustained performance and the precise reported fall remain unverified. No iOS binary or Unreal build was produced. The assets remain modest mobile art, not the photographic reference quality. No claim of an 11/10 rating or absence of all bugs is made.
