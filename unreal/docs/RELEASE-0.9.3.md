Waiting for Dawn 0.9.3 makes the team escape explicit and fixes issues found by a broader gameplay audit.

- Four separate car seats. Use near the car boards a seat; the cabin interface shows the team count, Start Engine and Get Out.
- Starting requires the ignition key, the fully raised garage door and every living, connected teammate aboard. Merely standing near the car no longer wins. Caught and disconnected survivors do not hold the team hostage.
- The server moves the car and synchronizes departure. Seated players travel with it. The win screen follows the departure; the dawn timer can still defeat a team waiting in the parked car.
- Passenger updates follow vehicle movement, avoiding a frame of cabin-position lag on slow devices.
- The departure camera fills wide mobile screens instead of forcing a 16:9 frame.
- Simultaneous boarding no longer rejects teammates through a shared furniture cooldown.
- Corrected car orientation, cleared the garage dresser from its route and cut the skirting across the garage opening.
- Both key portraits now swing into the room, keeping their close handles accessible.
- Fixed crouched movement after the round ends, caught survivors retaining occupied hiding spots, stale touch movement when opening panels, and gameplay actions accepted outside the playing phase. Retry is limited to completed rounds; joining an already-ended match is rejected.
- Join accepts strict IPv4 with an optional port and explains local versus private-VPN addresses. There is no new built-in internet matchmaking service. See [remote-play setup](https://github.com/singusathwik/WaitingforDawn/blob/main/unreal/docs/REMOTE-PLAY.md).

Eleanor's 0.9.2 Blender redesign, the existing house artwork, story and audio are retained.

Install the attached ARM64 APK over the previous Unreal preview. Version **0.9.3 / code 12**, package `org.waitingfordawn.unrealpreview`, minimum Android API 26. This remains a Development build with development signing.

Passed: six native rule tests; 275 component checks on both Windows and Android; the 73-check twelve-key campaign on both platforms; nine Android car-touch checks; eight Android ghost-encounter checks; four-process team departure, repeated with 100 ms packet delay and 2% loss; Android joining a Windows host through the real join interface and escaping together. The Android APK's signature and SHA-256 are recorded with the evidence.

The exact executed checks and their scope are recorded in [VALIDATION.md](https://github.com/singusathwik/WaitingforDawn/blob/main/unreal/docs/VALIDATION.md). Automated fixtures use real gameplay code but teleport between room setups; they are not an unassisted human playthrough. Four local processes are not four physical phones. Physical-device Wi-Fi, sustained performance and actual cross-location VPN sessions remain untested. iOS, save/resume, revive and host migration are not implemented.
