# Waiting for Dawn 0.8.3 repair

This is a repair of the existing Godot Android/Windows game. No Unreal build has been produced. The installed Unreal plugin points to localhost:8000/mcp, but that endpoint did not respond, no Unreal MCP tools were exposed, and no engine installation or .uproject was found. Blender 4.3.2 is available. Game Development Studio's `game-dev` CLI was unavailable, so no result is attributed to that CLI.

## Research translated into original mechanics

- [Eyes, publisher's Google Play description](https://play.google.com/store/apps/details?id=com.eyesthegame.eyes&hl=en) emphasizes learning routes, listening for danger and recognizing nearby-monster signs. Our application: directional ghost footsteps, physical-position light flutter and slight toy movement, while preserving quiet player steps. No Eyes art, characters or Eye rune ability was copied.
- [Amnesia: The Bunker, Frictional Games' Steam description](https://store.steampowered.com/app/1944430/Amnesia_The_Bunker/) describes a persistent threat reacting to actions and sound. Our application: drawers, doors and visible debris trigger a remembered investigation; a closed room remains safe, but opening it restores the ghost's route. The sound acknowledgment comes from the ghost's position rather than the drawer.

These are design inferences from official descriptions, not claims that either game was installed or played during this repair.

## Runtime changes

- Complete waypoint following avoids nearest-node corner cutting. Reachability chooses a temporary approach without overwriting the remembered noise destination. Door state changes invalidate the route; the ghost can wait and knock outside.
- Door prompts and actions share the same handle target, with a 3-metre range, broad view cone and wall occlusion. A small ring identifies the reachable handle. Interaction prompts take precedence over temporary noise notices.
- The native nursery receives a continuous structural collision slab. Exposed stair/bridge edges receive physical guards, rendered together using a MultiMesh. The last grounded position recovers an unexpected fall after a two-metre drop.
- Five new original Blender clusters: upholstered sofa with a draped throw, dining table with linen/plates/cutlery, broken crockery/books/boards, a coherent fallen chair, and nursery toys/rag doll. Large objects have collision; thin litter does not snag the player. Broken-edge damp/grime patches and reduced timber reflection age the surfaces.

## Editable assets

`decay-furniture.blend` retains 120 editable component objects and modifiers, with image dependencies packed. `scripts/build_decay_assets.py` regenerates it and exports the runtime GLBs under `assets/models/decay/`. Export copies are evaluated and joined; the editable originals are retained. The existing credited wood/fabric textures are reused. See `asset-metrics.json` for triangle counts. A Blender source file is not evidence of Android integration; Android captures and test logs are recorded separately under `docs/validation-0.8.3/`.

## Scope of the floor diagnosis

The user did not supply the exact hole location during this repair. The implementation covers all room floors and exposed stair/bridge edges rather than claiming a confirmed reproduction of their exact fall. Tests include floor-support grids, off-centre physical walking and fallback recovery. Continued device play can still uncover routes these tests do not cover.
