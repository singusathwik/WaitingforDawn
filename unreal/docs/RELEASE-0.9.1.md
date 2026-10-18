Waiting for Dawn 0.9.1 repairs the invisible-ghost encounter reported in 0.9.0.

The imported animations replaced Eleanor's master-root scale of 395.7522 with 1.0. Her collision stayed full-sized while her animated body shrank almost out of sight. All five clips now preserve the bind transform, and regression checks reject an undersized animated body.

- Visible corridor pursuit with a 1.8-second spotting pause and a cancellable 0.95-second attack wind-up. Sprinting can create escape distance.
- A 2.3-second face-framed capture using the actual animated head, with local fill lighting. The loss screen follows the visible encounter.
- Slow, audible opening of unlocked room doors. Key-locked progression gates and hiding furniture remain protected; ordinary closed doors buy time to hide.
- A translucent red wash across the screen and distance-based breathing on the same floor.
- Full-sized floating movement and scripted hallway ceiling crawling. She descends before attacking. This is a visual traversal along floor navigation, not unrestricted wall-climbing AI.
- New locally generated British narration, recorded human breath/scream source material, and more readable ghost materials. The narrator remains synthesized.
- The four-floor house, twelve shared keys, difficulty settings, dawn deadline, hiding and garage/car ending remain included.

The APK installs over the Unreal preview as version 0.9.1/code 10. Package `org.waitingfordawn.unrealpreview`, Android ARM64, minimum API 26. It is development-signed. See `unreal/docs/VALIDATION.md` for executed tests and real Android screenshots.

Executed validation: 5 native automation tests; 67 campaign checks and 8 encounter checks on both Windows and the Android emulator; four-process Windows co-op; Android-to-Windows joining through the actual mobile Join interface. Campaign fixtures cover all keys, stairs, hiding, noise-driven door opening and car escape. Network fixtures cover replication and remote interactions; they are not a human four-phone play session.

Physical Android phone performance, thermal behavior, multi-phone Wi-Fi and headphone balance remain unverified. iOS is not built. No save/resume, internet relay or host migration is included.
