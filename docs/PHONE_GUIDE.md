# 0.8.2 touch controls

Install WaitingForDawn-0.8.2.apk over the previous signed release. All peers must use 0.8.2.

- Top left: menu, recovered papers, torch. The torch works on every floor; it starts switched off.
- Bottom left: drag the large circular joystick. Drag the right side to look.
- Bottom right: hand (use), crouching figure, running figure, throwing hand. Crouch/run are toggles; gold indicates active. Desktop uses E, Ctrl, Shift, Q; J opens papers and F toggles the torch.
- Bottom center: green stamina bar. Slow down or crouch to recover.
- Aim the central dot at one drawer, cupboard, box or cistern, then tap the hand. Each is separately searched. Open compartments reveal their contents. Aim and use again to take a visible key; further use closes/reopens the compartment. Open state is shared with teammates and keys cannot duplicate.
- Recover papers from the upstairs corpse and rooms. They suggest connections in the story, not exact map markers. Read in a safe room; the match keeps running while the journal is open.
- Opening a door or storage makes noise. Difficulty controls response delay, then the ghost follows the route. Close all room entrances before searching. Cupboards and beds are single-occupant hiding places; use again to exit. If the ghost saw you enter, hiding is unsafe.
- Top right: shared bag (B on desktop). Twelve linked keys unlock successive storage, the crypt, the garage and finally the car. Find both final keys and board together before the dawn timer expires. All survivors down also ends the round.

The opening story uses subtitled offline synthesized narration. Headphones are recommended for spatial sounds, but physical-phone sound quality has not been qualified. This APK cannot install on iPhone; Apple distribution still requires the separate iOS build/signing workflow in IPHONE.md.

Play starts solo immediately. Skip bypasses the opening, and Try again restarts a lost round without replaying it. Ordinary footsteps are silent; loose boards creak only after 20–50 travelled steps. Nursery is one level above the ground-floor garage; bedrooms are above the nursery. Use the enclosed stairs at the east side.

# Install and play on phones

1. Copy `WaitingForDawn-0.8.2.apk` to each device. Android 7.0/API 24 or newer and a 64-bit ARM device with OpenGL ES 3.0 are the package's technical baseline. No physical device has yet been performance-qualified. A 4 GB RAM mid-range phone is the intended test target, not a measured guarantee.
2. Open the APK and allow installation from the chosen file manager when Android asks. The package is `org.hollowhouse.lastride`. Install only builds whose checksum you trust. No microphone/storage permission prompt is required.
3. Put the phones on the same non-guest Wi-Fi network. Choose Join with friends, then HOST ROOM on one phone. It displays its candidate LAN IPv4 addresses. Enter the address associated with Wi-Fi on the other phones, then JOIN IP. VPN/virtual adapters may add extra addresses; disable the VPN or select the Wi-Fi address in Android network details.
4. Enter names, mark everyone ready and let the host press START. Maximum team size is four, including the host. Joining during a match is rejected. The host must return to the lobby after the match to accept new players.
5. For hotspot testing, enable one phone's hotspot, connect the others to it and use the address actually displayed by the host. There is no hardcoded hotspot gateway. Phone hotspot play has **not** been physically tested.

Nearby discovery uses UDP broadcasts on 28742. Some Android vendors, routers and hotspots filter broadcasts. If no room appears, manual IP joining on UDP 28741 can still work. Discovery is best effort; no Android multicast-lock plugin is bundled. The manifest declares INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE and CHANGE_WIFI_MULTICAST_STATE. These are install-time normal permissions for target SDK 35, not microphone or nearby-device scanning permissions.

Connection failures can mean an incorrect IP, a full room, guest-network/client isolation, a host that left, or a blocked UDP port. Check that both devices really share the same LAN. On a Windows host, permit the game through Windows Firewall on the private network. No firewall rules are installed automatically. The game displays an error after a ten-second connection deadline. A full transport can time out before the application handshake, so the message lists room capacity among possible causes.

Backgrounding the app deliberately disconnects that player. Backgrounding the host closes the room, and clients return to the menu. Keep the host in the foreground. There is no host migration and no mid-match reconnect. Shared essential key progress remains with the host when a client leaves.

If updating from a developer debug build to the distribution signing key, Android requires uninstalling the debug package first. This removes local settings. Subsequent builds signed with the same distribution key can update normally.

## Physical acceptance checklist — still required

- Two real phones: host and client roles on the same router, then repeat with a phone hotspot.
- Four real phones: complete a run, revive, simultaneous key attempts, disconnect one player after a pickup, repeat a match.
- Simultaneously move/look/use on touch; check cutouts, gesture navigation, small displays and control scaling.
- Host backgrounds, client backgrounds, Wi-Fi disabled, bad IP, version mismatch, fifth player and active-match join.
- Record 15-minute frame-time distributions, Android PSS/RSS, temperature and battery drain on the host and clients. Confirm sustained 30 FPS; desktop/emulator measurements do not satisfy this gate.

## Difficulty

Choose Easy / Normal / Hard / Extreme on the menu before starting Solo or hosting. Only the host can change it in a lobby; other players must ready again. Scroll the menu to reach settings on smaller screens. The dawn clock appears at the top center. Return to the lobby after winning or losing to change it.

## New horror interactions

- Find and USE the keeper's letter on the upstairs corpse, then follow the nursery diary and boiler log. CLUES opens the team journal; OK closes it. The match keeps running while reading.
- Approach the front of a cupboard or bed and press USE. Look through the slit or under-bed gap. USE again exits. One survivor per hiding place; hiding in sight of the ghost is unsafe.
- USE a room doorway to open/close it. Step clear of the threshold first. Closed doors block the ghost, but cannot protect you from one already inside.
- Listen for a wail after noise, then breathing and pursuit sound as it gets close. A visual warning also appears. Headphone/speaker levels still need physical-phone validation.

For lower texture memory use, enable **Lower texture detail** in Settings. This changes the new nursery atlas from 4096 to 2048 pixels; other assets retain their existing quality.
