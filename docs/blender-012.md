# 0.12 — native Blender architecture

112 closed manifold source meshes are generated with Blender 4.5.3: 32 rubble stones, 16 paving slabs, 12 hewn beams, 12 boards, 8 corner blocks, 12 shingles, 12 curved tiles and 8 lime fragments. The native `.blend`, GLB and source generator are delivered in the building-kit archive. `assets/kit/fortress-kit.json` stores the exact evaluated Blender triangles, compressed with zlib; all 112 source variants are used in the assembled fortress.

Variable-height bedded stone courses replace the large Voronoi wall stones. Rough timber, doors, quoins, individually overlapping roofs and paving use Blender meshes. Lime is a thick uneven mesh with damage-edge returns and independent volumetric flakes. Gables have real rubble geometry on a mortar backing. Photographic surface detail supplements the physical form.

`tests/bake.gd` creates the compressed assembled scene once during APK packaging. The mobile game loads that complete geometry and shared materials; temporary assembly vertex lists are released. Export includes both geometry and source fingerprint, with the source data retained for editing/rebuilding. The 0.11 collision layout, attic access, door/hand animation, touch input and controller mapping are preserved and exercised with the same physical capsule traversal test.

This is a mobile geometric overhaul, not a claim of Kingdom Come visual quality. Frame rate on the Xiaomi tablet still requires real-device measurement.
