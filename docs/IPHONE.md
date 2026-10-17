# iPhone preparation (not yet an iOS release)

The source now includes an iOS export preset and mobile input support for iPhone. No signed IPA or TestFlight build has been produced. The existing APK remains Android-only.

## Player requirements

- Planned minimum: iOS 15.0 on a 64-bit iPhone. This is the configured deployment target, not a measured performance guarantee; minimum practical hardware remains to be established.
- Install the future signed build through TestFlight or the App Store, or a development build provisioned for your device.
- For multiplayer, use the same Wi-Fi and game version (protocol 0.6.0) on every device. Android and Windows use the same ENet protocol; mixed iPhone sessions still need device validation.
- Allow Local Network access. If denied, enable Waiting for Dawn in Settings > Privacy & Security > Local Network, then retry joining.
- A player selects HOST ROOM and shares the IPv4 address shown in the lobby. Others enter it and select JOIN IP. Ready up, then the host starts. Up to four total players.
- iOS automatic nearby discovery is disabled. Direct IP avoids broadcast operations requiring Apple's multicast entitlement. No Bonjour services are used.
- Stay in the foreground. Backgrounding disconnects the session; leaving as host ends the room. Guest Wi-Fi with client isolation will prevent play.

## Build on a Mac

1. Install Xcode and its iOS SDK, accept its license, and verify `xcode-select -p` selects Xcode. Install Godot 4.5.2 and matching export templates.
2. Copy this complete source project to the Mac, open `project.godot`, and allow imports.
3. In Project > Export > iOS, supply your real 10-character Apple team ID. The repository intentionally leaves it blank. Use a bundle identifier registered to that team (default `org.hollowhouse.lastride`). Do not commit signing credentials.
4. Export to a new empty directory using a filename without spaces, such as `HollowHouse.zip`. Export Project Only is enabled; open the resulting Xcode project.
5. Set the signing team/provisioning profile in Xcode and connect a physical iPhone. Build and run there. Verify the generated Info.plist contains `NSLocalNetworkUsageDescription` from the preset. No multicast entitlement is needed for this direct-IP implementation.
6. Complete the device checks below before archiving a distribution build. TestFlight/App Store distribution requires Apple Developer Program access and the corresponding App Store Connect setup. Review generated privacy manifests, app icons, age rating and store submission requirements for the actual build.

Godot 4.5's documented iOS export workflow requires macOS/Xcode; its iOS simulator export is not supported. This Windows workstation cannot complete that build or substitute for physical iPhone testing.

## Local regression commands

On Windows, run `scripts/test.ps1` with the pinned Godot executable. On any supported development host, the configuration check is `godot --headless --path . --script tests/ios_configuration.gd`. These verify shared gameplay and configuration, not UIKit, Apple signing or iPhone networking.

## Required device qualification (all pending)

Record model, iOS version, build, network and outcome for each test:

- Fresh install, permission allow/deny/re-enable and retry; solo remains usable without LAN access.
- Android host + iPhone join, iPhone host + Android join, and four mixed players. Confirm shared pickup races, revival, twelve linked keys, garage, all-player boarding, victory and restart.
- Wrong IP/version, fifth player, join after start, dropped Wi-Fi, host exit, lock screen and background/foreground recovery.
- Movement + look + action simultaneously; every button; keyboard dismissal; notch/home-indicator spacing in both landscape orientations; largest touch-size setting.
- Imported materials, ghost skeletal animations, scares, settings persistence, speaker/headphone audio and interruptions.
- Full playthrough and at least 20 minutes sustained play: frame rate, memory, temperature and battery on the oldest intended device. Select minimum hardware from these results.
- Two real phones on a router and on the intended hotspot. Simulator/desktop networking does not establish phone Wi-Fi compatibility.

## References

- [Godot 4.5 iOS export](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_ios.html)
- [Godot iOS export options](https://docs.godotengine.org/en/4.5/classes/class_editorexportplatformios.html)
- [Apple local network privacy](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy)
