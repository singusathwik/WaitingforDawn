# Waiting for Dawn 0.8.2

This repair replaces the old entry dialog with a home screen, expands the viewport, fixes intro dismissal/skip/retry and removes the monster from the opening. Narration is a 34.74-second synthesized male voice. The flashlight now works on every floor.

The house has a ground floor with garage, a nursery level, top bedrooms, boiler/service basements and a crypt. Enclosed stairs and flat landings are shared by collision geometry and navigation. The existing native Blender nursery is repositioned into this stack. Original exported Blender assets replace more cabinets, hollow trays, wardrobes, beds, doors, car and exterior surfaces. The runtime uses these GLBs; the editable source is included.

Ordinary movement no longer emits per-step clicks. Only marked uneven boards can creak after 20–50 travelled steps; door, drawer, glass and furniture noises still attract investigation. The ghost starts in a connected hallway and has enough investigation time to follow multi-floor routes. Closed entrances remain barriers. Wails, breathing and visual warnings remain active.

Storage is a synchronized open/close state. Opening reveals a physical key; taking it is a separate use action. Twelve dependent keys, 81 compartments, 17 hiding places, a shared bag, teammate discoveries, revival, four difficulties and the dawn deadline remain implemented. The final garage key opens the outside shutter, and boarding with the ignition key triggers a visible car departure. Both failure and victory support reset.

Limits: the car and secondary geometry remain modest mobile models, not photoreal scanned assets. Some architecture and clutter remain procedural; every loose object is not physically simulated. The ghost remains an adapted credited rig. The opening is an in-engine cinematic, not a prerendered film or human voice performance. Key dependencies form a fixed chain with randomized assigned storage, not a branching puzzle generator. Keys are shared automatically, not manually transferred.

Testing is described in TEST_RESULTS.md. Automated fixtures and Android-emulator captures do not establish sustained physical-phone performance, headphone balance, manual touch usability or real-phone Wi-Fi reliability. No signed/tested iPhone binary, Internet relay or host migration is included.
