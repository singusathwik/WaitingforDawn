# Waiting for Dawn launcher artwork, 0.9.4

Created on 2026-10-19 with the built-in OpenAI image generation tool. No reference images were supplied. `launcher-source.png` is the unchanged generated master. Godot's offline image converter only resizes it into Android density resources and a 512-pixel adaptive layer; it does not run the game or modify its content.

## Exact generation prompt

Use case: stylized-concept.
Asset type: final square Android launcher icon artwork for the original 3D horror survival game Waiting for Dawn.
Primary request: a genuinely creepy, premium horror game app icon, replacing a simplistic cartoon house. One unforgettable spectral female face is the dominant silhouette, Eleanor, a gaunt mother haunting an abandoned house: bone-pale weathered skin, hollow nearly black eye sockets with tiny cold catchlights, unnervingly direct stare, severe expression and slightly parted dark lips, long tangled black hair dissolving into the shadows. Original character art, not a copy of a film or existing game character.
Composition: 1:1 square, full bleed opaque artwork. The face is centered and large, all essential facial features safely within the central 60 percent of the canvas, so circle and rounded-square launcher crops work. A small looming abandoned Victorian house silhouette sits low beneath her face, with just one dim amber doorway and a very thin dying dawn glow. The face remains the clear focal point even at 48 pixels. Bold readable masses, restrained fine detail, no clutter.
Style: high-quality cinematic horror illustration with realistic sculpted form and tactile skin, dramatic cold side lighting, deep charcoal and desaturated blue shadows, aged ivory face, subtle dark crimson haze and a restrained amber horizon. The face must stay bright enough to read on a phone, truly menacing rather than cute, spooky or Halloween-cartoon style.
Constraints: single finished icon, not a phone mockup, not a grid, no lettering, no title, no initials, no logo, no watermark, no decorative border, no pre-rounded corners, no transparent background, no graphic gore.

## Android integration

The Android manifest uses `@drawable/icon`. Seven PNG fallback sizes and an API 26+ adaptive icon are provided. The adaptive icon uses the original illustration as its background with a transparent foreground; Android applies the launcher mask. The face is centered and the artwork is full bleed, without baked corners or lettering. There is no separately authored monochrome themed-icon layer.

Source guidance: [Android adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).

Recreate exports from the project root:

```powershell
godot --headless --path . --script unreal/tools/export_android_icon.gd
```
