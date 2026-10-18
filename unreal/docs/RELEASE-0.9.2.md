Waiting for Dawn 0.9.2 replaces Eleanor's bald zombie appearance with a new Blender-authored mourning apparition.

- Gaunt textured face, recessed eye sockets, uneven teeth and dark tear staining.
- Long layered 3D hair, a torn nightdress, narrower arms, hooked nails and a worn keepsake.
- Materials tuned for corridor visibility, with the same animated pursuit, floating/ceiling poses and face-framed capture introduced in 0.9.1.
- The actual house map uses the new skeletal mesh. The editable packed Blender file, FBX, baked maps and source-generation prompt are included in `design/eleanor-092`.

The model has 30,499 triangles, 42 bones and eight opaque material slots. The facial source texture was generated with OpenAI's built-in image tool and projected/baked in Blender; the ghost is animated 3D geometry. The existing credited arm geometry, rig and five repaired clips are retained. Hair and cloth are weighted geometry, without physical simulation.

Repeated FBX imports are guarded against unit changes. The importer verifies bind transforms, reuses the existing rig's full-body physics bounds, and verifies unchanged hashes for the skeleton and animation clips. No gameplay difficulty, key progression or escape rule changed in this art update.

APK: ARM64, version 0.9.2/code 11, package `org.waitingfordawn.unrealpreview`, minimum Android API 26. Development build and development signing. It installs over the previous Unreal preview.

Executed validation: 8 encounter checks on Windows and 8 in the Android APK; 67 Android campaign checks including all twelve keys, stairs, hiding, noise pursuit and car escape; Android-to-Windows co-op through the actual mobile Join interface; Blender skinning/normals and asset-integrity checks. Actual Android screenshots and detailed test scope are in `unreal/docs/VALIDATION.md`.

Physical-phone performance and multi-phone Wi-Fi testing remain outstanding. The existing synthesized narration and mannequin co-op characters remain; this update focuses on Eleanor. iOS is not built.
