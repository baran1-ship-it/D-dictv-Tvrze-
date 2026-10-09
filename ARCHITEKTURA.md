# Architektura procházky 0.3

`game.gd` vytváří CharacterBody3D, kameru, cílení, animaci ruky a HUD. `exploration_controls.gd` zpracovává nezávislé dotyky a standardní mapování Xboxu. `fortress_builder.gd` sestavuje propojenou architekturu, kolize, materiály a dekorace. `construction_mesh.gd` vytváří uzavřené zkosené díly s vlastním směrem vláken. `fortress_door.gd` spravuje dveřní křídlo, dvě upevněná madla, kolizi a animaci.

Základní kolize zdí a podlah jsou oddělené od drobného reliéfu; schody mají skutečné kolizní stupně. Zábradlí má ochranné kolize, žádné horní dveře nesmějí vyústit do prázdna. Opakované kameny, kostky a tašky sdílejí instancované sítě MultiMesh. Trámy a prkna mají lokální UV; zdivo používá triplanární jemnou strukturu.

Testy ověřují skutečný pohyb kapsle a návaznost průchodů. Více kontrolních snímků prověřuje střechy z obou směrů a hlavní přístupy. Staré skripty ukládání/streamingu nejsou aktivní součástí procházkové scény.
