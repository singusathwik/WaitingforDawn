# Playing with friends in different locations

Waiting for Dawn 0.9.3 uses Unreal's direct-IP listen server. It has no built-in public lobby, invite codes, relay, account service or NAT traversal. A home Wi-Fi address such as `192.168.1.20` normally cannot be reached from another location.

## Private VPN option

An external private mesh VPN can provide a route between the devices. Tailscale documents [sharing a private game server](https://tailscale.com/docs/use-cases/personal-or-at-home-use/share-private-game-server) and has an [Android app](https://tailscale.com/docs/install/android). This is an optional third-party service, separate from the game.

1. Install the same game version on every device. Configure the VPN so all players can reach the host; use your own accounts and the service's sharing/access controls.
2. Connect the VPN on each device. Permit game traffic to the host on **UDP 7777**. On a Windows host, allow the game through its firewall for the VPN connection.
3. The host opens **Join with friends → Host a house** and keeps the game in the foreground.
4. Friends open **Join with friends**, enter the host's **VPN IPv4 address**, then select **Join house**. Obtain that address from the VPN app; the game's “This device” address may show the Wi-Fi interface instead.
5. The host waits for the team count, selects difficulty and presses Play. Maximum four players including the host.

The address field accepts IPv4 and an optional port, for example `100.90.10.2:7777`. The example is not a live server. The normal Host button uses port 7777. Host departure ends the session; host migration and rejoining into a preserved character are not implemented. A returning player starts as a new survivor and must board before departure.

## What has and has not been tested

See [VALIDATION.md](VALIDATION.md) for the exact local process and Android emulator tests. No independent second internet connection or physical remote phone was available. The VPN route is a documented setup option, **not a verified cross-location playtest** of this APK. Connection reliability and latency depend on the VPN and networks. No accounts, VPN configuration or public firewall changes were made for you.

## Escaping together

Collect the twelve shared keys through their dependencies. Use the garage key plate to raise the door. Each surviving player approaches the car and presses the hand/Use button to board a separate seat. The car shows **aboard / surviving players**. You can Get Out before departure. Once everyone alive is seated, the garage is fully open and the shared bag contains the ignition key, any seated player can press **Start Engine**. The car leaves and the team receives the ending. Caught players do not need to board; disconnected players do not retain a seat. The dawn deadline continues while waiting in the parked car.
