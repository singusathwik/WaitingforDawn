# Waiting for Dawn 0.8.3

The 0.8.3 repair adds a continuous nursery collision slab, exposed-landing guards and last-grounded fall recovery. Door selection now uses the visible handle with a wider range and a single target for both the prompt and action. Ghost navigation follows complete waypoints, retains a sound behind a closed room and reroutes when a door opens; blocked patrol choices no longer strand it.

Five new original Blender asset clusters are placed in the playable rooms: sofas, draped dining settings, fallen chairs, broken crockery/books/boards and nursery toys. The 120-part editable source is packed and its five exports were reimported for dimensional/topology checks. Shared texture bindings avoid duplicate texture memory. Debris disturbance, spatial ghost steps, nearby light flutter and subtle toy movement provide additional cues; they do not reveal key locations.

The exact floor hole from the user's report was not located from a supplied room coordinate. Broad floor-grid, exposed-edge and recovery coverage addresses multiple potential fall routes. The ghost's prior behavior varied with door state; a controlled fresh-match regression now verifies closed-room approach, retained investigation and entry after opening. These checks do not prove every device playthrough is bug-free.

Unreal Engine was requested, but no installed engine, .uproject or live editor connection was available. This deliverable continues the existing Godot project. It is not an Unreal migration. Research and tool availability are recorded in `design/repair-083/README.md`.

## Existing game systems

This repair replaces the old entry dialog with a home screen, expands the viewport, fixes intro dismissal/skip/retry and removes the monster from the opening. Narration is a 34.74-second synthesized male voice. The flashlight now works on every floor.

The house has a ground floor with garage, a nursery level, top bedrooms, boiler/service basements and a crypt. Enclosed stairs and flat landings are shared by collision geometry and navigation. The existing native Blender nursery is repositioned into this stack. Original exported Blender assets replace more cabinets, hollow trays, wardrobes, beds, doors, car and exterior surfaces. The runtime uses these GLBs; the editable source is included.

Ordinary movement no longer emits per-step clicks. Only marked uneven boards can creak after 20–50 travelled steps; door, drawer, glass and furniture noises still attract investigation. The ghost starts in a connected hallway and has enough investigation time to follow multi-floor routes. Closed entrances remain barriers. Wails, breathing and visual warnings remain active.

Storage is a synchronized open/close state. Opening reveals a physical key; taking it is a separate use action. Twelve dependent keys, 81 compartments, 17 hiding places, a shared bag, teammate discoveries, revival, four difficulties and the dawn deadline remain implemented. The final garage key opens the outside shutter, and boarding with the ignition key triggers a visible car departure. Both failure and victory support reset.

Limits: the car and secondary geometry remain modest mobile models, not photoreal scanned assets. Some architecture and clutter remain procedural; every loose object is not physically simulated. The ghost remains an adapted credited rig. The opening is an in-engine cinematic, not a prerendered film or human voice performance. Key dependencies form a fixed chain with randomized assigned storage, not a branching puzzle generator. Keys are shared automatically, not manually transferred.

Testing is described in TEST_RESULTS.md. Automated fixtures and Android-emulator captures do not establish sustained physical-phone performance, headphone balance, manual touch usability or real-phone Wi-Fi reliability. No signed/tested iPhone binary, Internet relay or host migration is included.
