# Hollow House 0.7.0 validation — 18 October 2026

Release Android version code 7; minimum SDK 24, target SDK 35, arm64-v8a and x86_64. All multiplayer peers must use 0.7.0. The previous release signing certificate is retained.

## Executed checks

- Full automated regression suite: input bounds/ownership, shared objectives, two/four ENet peers, departure, mismatch/late join/capacity/timeout, repeat matches, four-player pickup race/revive/boarding/victory/restart, defeat, all four difficulty settings, scares and imported animation rig. Evidence: artifacts/test-070-final.log.
- 77 compartments were individually aimed at and opened through the use action. All three concealed keys were recovered. Sound reaction delays checked just before and after 6 / 4.5 / 3 / 2 seconds. Pending noise queue bounded at eight and cleared on restart. Evidence: artifacts/exploration-070.log and artifacts/tests/exploration.log.
- Real ENet drawer fixture: remote client aim and use opens the selected drawer, obtains one shared key, replicates opened state, cannot duplicate the key, and sees restart clear searched compartments. Evidence: artifacts/tests/search-host.log and search-client.log.
- Existing paper/door/cupboard/bed fixtures pass, including closed-door physics/line of sight, witnessed hiding, single occupancy and state reset. Final focused rerun after geometry changes: artifacts/interactions-070-final.log.
- CharacterBody3D physically walked to all three randomized key locations, aimed/searched their containers, unlocked the garage and entered the escape phase with three keys. Ghost disabled in this traversal fixture. Evidence: artifacts/traversal-070.log.
- Separate physical walkthrough reached the east wing, attic, service-stair landing, service basement, original boiler room and ground floor. Evidence: artifacts/estate-walk-070.log.
- Android API 35 emulator: signed update installed; circular controls, journal, opening subtitles and normal solo launch rendered. Actual touch started solo, moved and opened the journal. Render fixtures stage the journal with all papers found for presentation review; that is not a human discovery playthrough.
- Final signed APK, Android client plus desktop host: actual right-look drags and circular hand-button taps recovered a concealed key and synchronized the drawer; duplicate use and restart passed. A first input sequence tapped Ready before the connection completed; the corrected sequence waits for the lobby. Evidence: artifacts/android-search-host-070.log.
- Android basement fixture: captured darkness with torch off, then actual torch-button tap illuminated the storage and the host received light=true. Evidence: artifacts/android-basement-dark-070.png, android-basement-light-070.png and android-light-host-070.log.
- Final paper layout re-rendered after adding margins. Signature and manifest verified in artifacts/apk-signature-070.txt and apk-manifest-070.txt; SHA-256 checksums in artifacts/SHA256SUMS-0.7.0.txt.
- Introduction, wail, breath and creak WAV files checked for non-silent samples and peaks below full-scale clipping. Narration is 34.52 seconds of offline synthesized speech; intro lasts 36 seconds. Evidence: artifacts/audio-070.json. Emulator runs with audio output disabled, so this is not a listening test.
- iOS configuration checks pass; this does not validate iPhone runtime or Apple signing.

## Fixes found during this update

Awaited furniture/navigation initialization before allowing matches to begin, excluded storage obstacles from routes, repaired a railing obstruction at the service stair and aligned its navigation with the actual slope. Changed old fixture assumptions for multiple room entrances and explicit aiming beside storage. Corrected centered icon alignment and moved the aiming dot to the actual camera center. Extended introduction timing so narration is not cut off; added journal text margins after render inspection.

## Scope and limits

The new floor plan has nine cupboards, five beds, ten room doors and 77 search compartments. Each key family has 12 candidate compartments; the other compartments are decoys. Room doors block the ghost, but rooms with multiple entrances require all entrances to be shut. A delayed sound triggers investigation, not teleportation or a guaranteed arrival time. A visible player may be chased immediately. Opening storage during the initial grace period does not summon the ghost.

This remains a playable alpha. No physical-phone thermal/battery/performance test, phone-to-phone Wi-Fi qualification, audible headphone review, exhaustive human balance playthrough or App Store build was performed. Automated fixtures use known positions and some staged state; they are not evidence of an unaided human completion. Furniture is modeled with existing PBR textures and the prior imported ghost model is retained; there is no new bespoke maternal ghost mesh or physics simulation for every decorative object.
