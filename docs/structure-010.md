# Structure and surfaces 0.10

Continues Godot 4.6.3 Compatibility and the existing fortress layout. Backup:
`backup/before-corridors-and-surfaces-2026-10-09` at f57c6d9.

- North-east wall-walk floor now reaches and overlaps the adjoining east floor. Guards against solid rear walls removed.
- Two continuous stone ground passages beneath the north/east curtain walks, with closed stone vault geometry (4.50 m crown).
- Four complete weathered plaster tower partitions and animated doors separate rooms from the stairwell. Ground room stone vault retained; partition plaster is intentional.
- Ordinary leaves 1.10 x 2.10 m, adjusted lintels/jambs/hardware. Large paired gate preserved.
- Four tone-matched rock / individual stone surface patches in a single diffuse/normal/roughness/AO atlas, randomized per stone rather than alternating square tiles. Seeded stone sizes and shifted vault joints.
- Continuous yard-wide soil map; damp patches, three shallow irregular puddles with soft shorelines, existing irregular paved routes and edge vegetation.
- Floors use low-relief closed individual stones over uninterrupted collision slabs.

Verification: smoke script checks touch/Xbox mapping, door/hand animations, actual capsule stair traversal, tower doors, both ground passages, whole wall walk in both directions, floor footprints at the NE corner, door swings and thresholds. Visual script renders 14 actual Godot review views. CI builds and verifies signed APK. No tablet FPS measurement claimed. Blender source work remains unchanged; these corrections use the current Godot construction scripts.
