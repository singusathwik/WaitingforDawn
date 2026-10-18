# Eleanor's nursery wing — integrated 0.8.1 candidate

The user approved Function (layout, openings and references) and Form (textured native art) on 18 October 2026. The room is now exported, integrated and locally tested. **Human Runtime approval is pending before publication.** Open `runtime-review.html` for the current review. Earlier `review.html` and `form-review.html` retain their historical proposals. `design/.gdignore` excludes authoring files from the game.

`nursery-form.blend` is the packed, editable source. The 21 × 21 m upstairs bay now contains four rooms around a 3.42 m central passage. Internal openings are 2.4 m; original outer door anchors are retained. Blender `(X, Y, Z)` maps to Godot `(75 + X, 5 + Z, 9 - Y)`. The 0.05 m bed-to-dresser gap is not a walkway.

## Delivery

The modeled cradle, hollow wardrobe and two six-drawer dressers are native geometry, with shelves, beams and trim. Existing Poly Haven furniture and Rosswet character sources are credited in the root ASSETS.md. The keeper and mother character are still adaptations of the existing asset.

The runtime GLB has 16 meshes and 83,876 triangles. Twelve drawers and two wardrobe leaves animate independently; the search box has its own part. The 4096/2048 combined color/light atlases share geometry. Static surfaces use baked lighting and do not receive dynamic shadows. Five practical lights are read from the same source fixture manifest, with the existing nearest-three active budget for moving actors. Native watts are not directly treated as Godot energy values.

`runtime/export.json` records hashes and measurements; `runtime/integrity.json` validates them. `form-preflight.json` checks the reopened final native source: 84,020 triangles, 204 shell/low-trim opening rays, 28 furniture pair checks, packed images, support contacts and animation roots. Final gameplay, Android renders, Android-to-Windows multiplayer and physical twelve-key traversal are documented in the root TEST_RESULTS.md.

The stock room validator requires Meshy artifacts, pricing and positive credits even on the local-authoring route. Its failure output is preserved in `form-validation.txt`. No paid jobs or fabricated generation records were used. The native and runtime checks here are the project-specific adapter evidence.

## Runtime corrections

The approved layout is unchanged. Explicit segmented trim replaces Boolean trim bars inside doorways; the floor edge is flush with the existing stair landing. A denser navigation grid and capsule pruning resolve offset doors without removing tested stair connectors. These corrections and proposed lessons are recorded in `final-report.json`. Proposed lessons are pending, not auto-approved.

## Reproduce

Use Python with Pillow/OpenCV and Blender 4.3.2. Scripts are under the repository's `scripts/` folder. Rebuilding needs the existing original asset library; reviewing the packed scene does not.

1. `build_nursery_concept.py` rebuilds the source from room metadata. Do not overwrite the recorded approvals.
2. Run Blender with `finish_nursery_blender.py`, then `prepare_nursery_form_review.py`, to create textured native geometry, animation roots and inspections.
3. Run `repair_nursery_clearance.py` to create the segmented door trim. The floor width correction is in the source layout and finishing script.
4. Reopen the native file with `inspect_nursery_form.py`. The review writer refuses to overwrite approved Form evidence.
5. After Form approval, `export_nursery.py` bakes and exports the GLB, atlas tiers and shared fixture manifest. Retain the PNG `.import` files for VRAM compression/mipmaps. Run Godot import, then `check_nursery_export.py`.
6. Run `scripts/test.ps1`, the physical traversal fixture, and the signed APK checks with `check_android_nursery.py`. The Android helper requires the named emulator already running; use hardware graphics, not the known-failing SwiftShader driver.
7. `prepare_nursery_runtime_review.py` collects local evidence. It never grants human approval. Publication remains a separate approved step.

Physical-phone graphics, audio, thermal behavior and Wi-Fi, plus the iOS binary, remain unqualified.
