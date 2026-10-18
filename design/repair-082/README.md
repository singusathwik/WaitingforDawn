# 0.8.2 playable repair assets

`repair-assets.blend` contains the original authored prop set and facade. Regenerate with Blender 4.3.2:

```powershell
blender -b --python scripts/build_repair_assets.py
```

Exports go to `assets/models/repair/`; per-model vertex/triangle counts are in `asset-metrics.json`. `repaired_art.gd` loads the GLBs and applies shared textures/materials. `estate_layout.gd` supplies collision and navigation for the stacked house and enclosed stairs. The native nursery package remains in `design/rooms/eleanors-nursery/` and `assets/models/nursery/`.

The drawer is an open tray, and the wardrobe has separate hollow case and slotted leaf meshes. Runtime tweens move these components; key meshes rest inside opened compartments. Door and car controls remain host-authoritative. Furniture collision is deliberately simpler than its render mesh.

`assets/ui/manor.png` and `assets/textures/worn-oak.png` are original generated bitmap assets. Other applied maps retain the credits in ASSETS.md. The user-provided stock images were visual references, not copied into the APK. The car is an original mobile mesh, not a claim of photorealism.

See docs/validation-0.8.2 for captures from the actual APK and test logs. These are runtime evidence, not Blender preview renders.
