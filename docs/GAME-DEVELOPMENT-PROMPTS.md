# Prompts for building a game like Waiting for Dawn

[← Back to the game](../README.md)

These are reusable briefs for a coding assistant, with separate prompts for Blender and image tools. Replace the values in `[brackets]`. Start with the master brief, then use one focused stage at a time. Each stage should produce something you can run and inspect before the next one expands it.

The prompts describe **goals for a new project**, not a claim that every suggested feature already exists in Waiting for Dawn. Use your own story, characters and art direction.

| I want to… | Use this prompt |
| --- | --- |
| Start a similar horror game | [1. Master brief](#1-master-brief) |
| Get a small game working first | [2. First playable version](#2-first-playable-version) |
| Expand the house without broken stairs or locks | [3. House and key progression](#3-house-and-key-progression) |
| Make furniture that actually opens | [4. Blender assets](#4-blender-assets) |
| Build a frightening but fair enemy | [5. Ghost behavior](#5-ghost-behavior) |
| Improve story, light and sound | [6. Atmosphere](#6-atmosphere) |
| Make the phone controls usable | [7. Mobile interface](#7-mobile-interface) |
| Add friends and a team ending | [8. Multiplayer and escape](#8-multiplayer-and-escape) |
| Reproduce and fix a bug | [9. Focused repair](#9-focused-repair) |
| Test, package and publish | [10. Release audit](#10-release-audit) |
| Create visual references and an icon | [11. Art prompts](#11-art-prompts) |
| Try another setting | [12. Other game concepts](#12-other-game-concepts) |

## 1. Master brief

Use this as the first message in a new game project.

```text
Build an original first-person cooperative horror escape game called
[GAME NAME] in Unreal Engine, targeting Android ARM64 and Windows.
My target phone is [MODEL / RAM / ANDROID VERSION]. The repository is
[PATH OR URL]. Use the compatible engine version installed here; inspect
the existing project and tools before changing anything.

Premise: four students enter an abandoned family house at midnight.
They become trapped, discover a dead keeper and a letter, and must
uncover the house's history and escape together before dawn. Create
an original antagonist and story rather than copying another game's art.

The intended game includes a multi-floor house, physical stairs, hollow
searchable furniture, dependent keys, a shared bag, wardrobe and under-bed
hiding, noise-driven enemy investigation, visible pursuit, four difficulty
settings, and a garage/car ending requiring all surviving teammates aboard.

Start by implementing one complete playable slice: four rooms, one stair
flight, three keys, one hiding place, one enemy and a working ending.
Use readable temporary art where necessary and identify it clearly.
Do not expand the entire house until this loop works in a packaged build.

Use host-authoritative gameplay for up to four players. Define measurable
performance targets for my actual phone, then measure them when available.
Keep editable source assets, asset licenses and repeatable build scripts.

Implement the work, run the available engine and gameplay checks, and show
actual runtime screenshots. Report what passed, what failed and what could
not be tested. Preserve unrelated local changes. Do not claim a working APK,
online multiplayer or device performance unless you have verified it.
```

**Look for:** a runnable small game with a win and a loss, not just a design document or room render.

## 2. First playable version

```text
Implement the first complete playable loop in [PROJECT PATH]. Keep scope
to four rooms, one connected stair flight, three keys and one enemy.

Add first-person movement, usable doors, a drawer with a visible pickup,
a shared inventory, one wardrobe hiding space, a countdown and an exit.
Opening a door or drawer emits a noise event. The enemy investigates it,
spots visible players, chases, and only captures them after a visible wind-up.
Hiding must move the camera inside the wardrobe, leave a viewing gap and
offer a reliable exit interaction.

Implement Home -> Play -> optional skippable introduction -> Playing ->
Victory/Defeat -> Retry/Home. Block gameplay inputs outside Playing.
Retry must reset keys, doors, timers, enemy state and hiding occupancy.

Walk the stairs in both directions without teleporting. Complete the three
key pickups and reach the ending through normal interactions. Also test
capture, timer expiry, hiding exit and retry. Give me a runnable build,
screenshots, the results and the remaining issues.
```

**Look for:** working state transitions and actual interaction tests before more rooms are added.

## 3. House and key progression

```text
Expand the verified playable slice into a four-level house: dark basement,
ground-floor kitchen/lounge/garage, nursery floor, and upstairs bedrooms.
Give rooms distinct silhouettes and landmarks so players can learn routes.
Add shortcuts and loops without making every room look identical.

Before building geometry, document the room connectivity and an acyclic
dependency graph for 10-12 keys. No key may be behind its own lock. Include
garage and ignition keys at the end. Every objective must remain reachable.

Build real stairs with continuous collision, guard rails and clear landings.
Use the player's capsule dimensions to check doors, furniture gaps and
stairs. Keep clutter out of required walking routes and the car exit path.
Do not conceal a floor hole with a recovery teleport; fix its geometry.

Place keys in authored searchable drawers, boxes and behind hinged portraits.
Make opening and picking up separate readable interactions. Provide indirect
environmental clues tied to the story, without exact-location quest markers.

Test the complete lock graph, stairs both ways, all doors, every hiding exit
and a car-sized sweep through the garage route. Capture the finished rooms
inside the game, including the upper floors and basement.
```

**Look for:** a floor plan, a solvable key graph and evidence that the imported house is traversable.

## 4. Blender assets

Use with Blender access and the existing project's import tools.

```text
Create and integrate a small furniture set for [ROOM / ART DIRECTION].
Inspect the target game's scale, lighting and asset budget first.

Make a weathered cupboard, a six-drawer dresser, a bed with usable clearance,
and a small clutter set. Model actual hollow interiors, shelves, drawer boxes,
handles and hinges. Put each moving part at the correct pivot. Keep the front
recognizable from a player's eye height. Wear should follow edges, damp areas
and repeated handling; avoid uniform dirt on every surface.

Create UVs, coherent PBR materials, collision meshes and suitable LODs.
Set triangle, material and texture budgets for the target phone and report
actual counts. Preserve editable .blend files and source textures. Record
the licenses and origin of any imported material or model.

Export, import and place the assets in the saved Unreal map. Wire the real
open/close/hide interactions and expose pickups inside opened containers.
Check scale, normals, material appearance, collision, pivots and animation
in a packaged runtime. Show both Blender views and matching in-game views,
clearly labeled. A Blender render alone does not complete integration.
```

**Look for:** open interiors, reliable pivots and the same furniture visible in the playable build.

## 5. Ghost behavior

```text
Improve [ENEMY NAME] so the player can understand and fear the threat.
Inspect existing AI, navigation, replication and animations before editing.

Implement explicit patrol, investigate, search, chase, attack and recovery
states. Noise should carry a location, loudness and time. Repeated noises
must not indefinitely postpone the response. The enemy must navigate from
its actual position, including stairs and ordinary doors; do not teleport
it onto the player to simulate pursuit.

Use line of sight for detection and attack. Show a brief spotting reaction
and an attack wind-up that can be interrupted by sufficient distance or
cover. Make sprinting provide a real chance to escape. Hiding before being
seen should work; entering a hiding place while watched should be remembered.
Define how locked progression doors and occupied hiding places are handled.

Make proximity readable through spatial footsteps/breathing, animation and
a subtle full-screen danger effect. Add an option to reduce flashing effects.
Use rare scares with cooldowns instead of constant loud sounds.

Test sound investigation, blocked paths, closed doors, lost sight, hiding,
stairs, simultaneous players, capture and retry. Record actual approach and
chase footage so visibility, animation scale and attack fairness can be judged.
```

**Look for:** the enemy visibly traveling toward a sound and a player successfully escaping a chase.

## 6. Atmosphere

```text
Give [PROJECT] a consistent abandoned-house atmosphere while preserving
playability on [TARGET PHONE]. First inspect current runtime screenshots.

Use damp plaster, worn rugs, old photographs, broken crockery and believable
furniture arrangements. Leave navigation and interactable handles readable.
Build contrast between dim warm rooms, cold corridors and a very dark
basement. The flashlight should reveal nearby detail with controlled falloff.
Use occasional fixture flicker, with a reduced-flashing option.

Make audio communicate gameplay: localized door/drawer sounds, rare creaks
only on marked loose boards, directional enemy cues and quiet ambient layers.
Avoid a repetitive click on every step. Give voice, effects and ambience
separate volume controls. Check for clipping and excessive repeated sounds.

Create a concise skippable opening: students enter, the exit shuts, they find
a keeper, and the letter raises questions about the house. Do not reveal the
monster in the introduction. Add subtitles and skip on retry. Use licensed
or original voice/audio; label synthesized narration honestly.

Import all assets into the real build, record their provenance, and capture
the same scenes before and after. Measure the performance cost on available
hardware and state clearly when a physical-phone test is unavailable.
```

## 7. Mobile interface

```text
Refine the Android interface for landscape play on [TARGET PHONE].
Use a large left thumbstick, right-side look dragging and readable circular
Use, Crouch, Run and Throw controls. Put Menu and Journal near the top left,
Bag near the top right, and a green stamina bar near the bottom centre.
Keep the dawn clock visible without filling the screen with status text.

Show the Use affordance when the player is close enough to a valid handle,
including handles on opened doors and drawers. Explain locked interactions.
Prevent touches on UI from also rotating the camera or moving the player.
Clear stale touch state when menus open, the app loses focus or a round ends.

Support display cutouts and different aspect ratios without side bars or
clipped buttons. Provide sensitivity and control-size settings. Verify
multi-touch movement plus looking plus an action on the actual build.
Test opening/closing menus, joining, story skip, bag, hiding and car controls.
Report emulator checks separately from physical-device comfort testing.
```

## 8. Multiplayer and escape

```text
Implement and verify 1-4-player co-op in [PROJECT]. The host must authorize
key pickups, doors, enemy decisions, hiding occupancy, car seats and outcomes.
Replicate state so late joiners see the correct world. Handle simultaneous
interactions, disconnections and rejected joins with clear feedback.

Create four distinct car seats with Board, Get Out and Start Engine controls.
Starting requires the ignition key, a fully raised garage door and every
living connected teammate aboard. Show the boarding count and missing
requirements. Caught/disconnected players must not occupy required seats.
Keep the deadline running while seated. Replicate the departure and victory.

Test four separate processes and at least one Android-to-host connection
when available. Exercise simultaneous boarding, leaving a seat, disconnects,
late joins, missing keys, blocked start, victory, loss and retry. Repeat key
network scenarios with simulated latency and packet loss.

Document LAN setup precisely. If different-location play is required, inspect
the available online service, relay or VPN setup before implementing it.
A room code alone does not provide internet connectivity. Do not describe
loopback or a single-machine emulator test as a real cross-location test.
Report what works, the connection method and the untested boundaries.
```

## 9. Focused repair

Use this when something breaks. Include a screenshot, game version and room name where possible.

```text
Fix this bug in [PROJECT / VERSION]: [OBSERVED BEHAVIOR].
Expected behavior: [EXPECTED RESULT].
Reproduction: [NUMBERED STEPS / ROOM / DEVICE / HOST OR CLIENT].

Reproduce it before changing the code. Inspect the relevant asset, collision,
state and network behavior. Identify the cause and implement the smallest
complete fix while preserving unrelated work. Do not mask the symptom with
a teleport, permanent invulnerability or removal of the feature.

Verify the original reproduction and nearby failure cases. For a stair hole,
walk the entire flight and both landings in both directions, crouched and
running, and test the railing edges and client movement where applicable.
Add a regression check only where it meaningfully catches this failure.

Return the cause, changed files, actual checks and an updated runnable build
if packaging is available. State any remaining reproduction or device limits.
```

## 10. Release audit

```text
Audit [PROJECT] for release [VERSION]. Build a checklist from the implemented
features and track each result as passed, failed, blocked or not tested.

Exercise normal UI flow, touch input, every door/container/hiding space,
stairs in both directions, every key dependency, enemy noise and pursuit,
timer loss, capture, the complete escape ending and retry. Complete a normal
playthrough where possible; label any cheats, teleports or granted keys used
by automated fixtures instead of calling those an unassisted playthrough.

Run multiplayer checks with separate players/processes, including latency,
packet loss, simultaneous use, late join and disconnect cleanup. Test real
phones and independent internet connections only if those devices are
available, and state when they are not.

Fix reproducible blockers and rerun the affected checks. Package Android,
verify package/version/signature, install it, launch it from its icon and
test upgrade from the prior release. Measure frame pacing, memory, audio
and thermal behavior on the stated hardware without inventing benchmarks.

Update README, release notes, asset credits, genuine gameplay screenshots,
setup instructions, known limitations and APK checksum. Publish the relevant
source and APK to [MY GITHUB REPOSITORY], excluding credentials, signing keys,
caches and unrelated files. Verify the remote commit and download links.
Do not describe the game as bug-free or certify devices you did not test.
```

## 11. Art prompts

These prompts create **visual references**, not automatically usable 3D models or proof of in-game graphics. Model, import and inspect assets separately using prompt 4.

### Creepy launcher icon

```text
Create an original square Android horror-game icon for [GAME NAME].
A gaunt spectral mother emerges from deep shadow above a small decaying
manor. Long dark hair frames an unnaturally still pale face; hollow eyes,
cracked skin and a restrained expression create dread. A thin band of amber
dawn behind the roof contrasts with charcoal, bone white and muted burgundy.
Strong central silhouette, readable at 48 pixels, one clear focal point.
Keep all essential features inside the central safe area for circular and
rounded-square launcher masks. Full-bleed background, no text, no border,
no watermark, no resemblance to a known film or game character.
```

### Furniture modeling reference

```text
Create a clean modeling reference sheet for an original old nursery wardrobe.
Show aligned front, side and three-quarter views, plus a separate open-door
view revealing the interior shelves and a person-sized hiding cavity.
Dark worn timber, tarnished brass handles, visible joinery, chipped paint
near the base and restrained damp staining. Consistent dimensions across
views, neutral studio light, plain background, no dramatic shadows, no text.
The doors and hinges must be mechanically plausible for animation.
```

### Haunted room concept

```text
Design an original abandoned nursery for a first-person mobile horror game.
Show the room from adult eye height: a worn crib, low dresser, wardrobe,
faded family photographs, damaged rug, scattered wooden toys and a partly
open door into a colder corridor. Dampness collects beneath the window;
wear and clutter tell a family story. A weak warm ceiling light contrasts
with cold moonlight. Preserve a clear walking route and readable handles.
Atmospheric, grounded proportions, no character, no UI, no text or logos.
This is a mood reference for a room that will be modeled separately.
```

## 12. Other game concepts

Use one of these premises with the master brief and the same staged checks.

**The Last Ward — abandoned hospital**

```text
Build an original 1-4-player horror escape game in a closed rural hospital.
A night inspection traps the team inside as the backup generator fails.
Recover patient records, restore isolated circuits and reach the ambulance
bay before power runs out. An unseen former orderly becomes a visible
pursuer after hearing metallic equipment. Use curtains, lockers and service
routes for hiding and escape. Begin with one ward, one enemy and a complete
ambulance ending before expanding the hospital.
```

**Night Signal — mountain relay station**

```text
Build an original cooperative survival mystery at a remote mountain relay
station during a storm. Repair three linked transmitters, decode fragments
of a distress call and signal a rescue vehicle before the road floods.
A creature follows light and radio interference, so communication creates
tradeoffs. Start with the station, one outside route and a working rescue
ending. Make visibility and audio cues fair before adding a larger forest.
```

**Platform Thirteen — deserted railway depot**

```text
Build an original cooperative horror escape game in a decaying railway depot.
The team must locate maintenance keys, reconnect track power and board a
service locomotive before the last safe departure window closes. Machinery
and rolling objects attract a roaming caretaker. Use workshops, sleeping
carriages and service pits for exploration, with safe collision and clear
routes. First deliver one platform, one workshop and a playable train escape.
```

The most useful follow-up is specific: “The ghost did not react when I opened the nursery drawer on Normal as a joining player,” with a clip and build version. That gives the assistant something it can reproduce, fix and verify.
