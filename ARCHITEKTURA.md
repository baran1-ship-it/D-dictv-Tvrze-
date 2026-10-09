# Architektura procházky 0.4

`game.gd` vytváří CharacterBody3D, kameru, cílení, animaci ruky a HUD. `exploration_controls.gd` zpracovává nezávislé dotyky a standardní mapování Xboxu. `fortress_builder.gd` sestavuje propojenou architekturu, kolize, materiály a dekorace. `construction_mesh.gd` vytváří uzavřené zkosené díly s vlastním směrem vláken. `fortress_door.gd` spravuje dveřní křídlo, dvě upevněná madla, kolizi a animaci.

Základní kolize zdí a podlah jsou oddělené od drobného reliéfu; schody mají skutečné kolizní stupně. Zábradlí má ochranné kolize, žádné horní dveře nesmějí vyústit do prázdna. `scanned_surface.gd` převádí výškové mapy CC0 materiálů na síť se skutečným reliéfem, normálami a tangenty. Diffuse, normal, roughness a AO sdílejí souřadnice s geometrií. Statické povrchy jsou sloučené podle materiálu. Kolizní jádro zdí a plynulá podlaha nádvoří zůstávají jednoduché. Trámy a prkna mají lokální UV.

Testy ověřují skutečný pohyb kapsle a návaznost průchodů včetně průchodu horními dveřmi v obou směrech. Více kontrolních snímků prověřuje střechy z obou směrů a hlavní přístupy. Staré skripty ukládání/streamingu nejsou aktivní součástí procházkové scény.
