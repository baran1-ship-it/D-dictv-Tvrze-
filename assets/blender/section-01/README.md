# Reprezentativní část 01 — obytné křídlo směrem do nádvoří

Výstup z Blenderu 3.6.23; Godot zůstává 4.6.3 Compatibility. Jde o první samostatný díl k vizuálnímu hodnocení, nikoli o dokončenou rekonstrukci celé tvrze nebo tvrzení o kvalitě KCD2.

## Umístění a návaznost

Sedmimetrový výřez existující západní fasády obytného křídla; výška 7,2 m, tloušťka kolizního jádra 0,6 m. Při budoucím vložení má střed `(8,0,8)` a natočení kolem Y `-90°`. Přízemní otvor je 2,26 × 2,72 m, křídlo dveří 2,1 × 2,65 m. Okenní otvor v patře je 1,32 × 1,30 m a má střed ve výšce 5,57 m. Podlahy navazují na výšky 3,6 a 7,2 m. Tyto hodnoty byly převzaté z fortress_builder.gd, nikoli odhadnuté z obrázku.

Hlavní scéna tvrze není upravená. Nový díl je v `scenes/blender/section_01.tscn`. Nepřekrývat ho se současným procedurálním zdivem: před vložením je potřeba nahradit odpovídající střední výřez původní fasády a zachovat její zbývající části. Tato náhrada v hlavní scéně ještě neproběhla. Vyčnívající hrany podlah a krátký úsek okapu slouží k ověření návaznosti; nejsou celým krovem.

## Soubory

- `section-static.glb`: zdivo, ostění, okno, okenice, podlahové hrany a krátký okap s jednotlivými překrytými taškami.
- `section-lod1.glb`: vzdálená varianta stejných dílů.
- `door-leaf.glb`: samostatné dveřní křídlo; nula modelu je v pantu, šířka vede v +X a výška v +Y.
- `scripts/blender_section_01.gd`: kolizní jádro, původní FortressDoor a přepínání LOD s hysterézí.
- `source_art/blender/section-01/section-01.blend`: upravitelný zdroj s vloženými texturami a kontrolním osvětlením. `source_art/.gdignore` brání automatickému importu .blend do Godotu.
- Čtyři PNG v source_art jsou skutečné Cycles rendery, nikoli snímky Android hry.

## Materiály

Texturovaný kámen, dřevo a omítka mají albedo, OpenGL normal, roughness a AO. GLB obsahuje potřebné obrázky. Železo, malta, sklo a tašky používají jednoduché fyzikální materiály. Použité fotografované mapy mají 1024 × 1024 px, původní URL a SHA-256 jsou v `sources-section.json`.

| Materiál | Zdroj | Autor | Licence |
|---|---|---|---|
| Kámen a ostění | https://polyhaven.com/a/rock_face_03 | Dario Barresi, Rico Cilliers | CC0 |
| Vápenná omítka | https://polyhaven.com/a/plastered_wall | Amal Kumar | CC0 |
| Vlákna dřeva | https://polyhaven.com/a/roof_planks | Rob Tuytel | CC0 |

Dřevěné albedo bylo ztlumené v sytosti a jasu. Fotografie prken se nepoužívá přes celé dveře: UV vybírají různé úzké pruhy mezi fotografickými spárami, vlákna vedou podél dílu. Kameny mají vlastní prostorový tvar, ustupující maltu a nejvýše přibližně 3,4 cm vystupování před jádro. Rozložení tvoří 426 individuálních kamenů, nikoli opakovaný prefabrikát či textura celé zdi.

Pro typologii zdiva a vápenné omítky byl použit veřejný průvodcovský sylabus Švihova: https://www.hrad-svihov.cz/pamatky/svihov/-provadeni/HradSvihov_Sylabus2024_v240322.pdf. Nejde o kopii Švihova; fotografie památek nejsou herními texturami. Omítka, přímé řady a míra opotřebení zůstávají předmětem vizuálního hodnocení.

## Ověřeno 9. října 2026

- Čtyři kontrolní pohledy byly dávkově vykreslené a prohlédnuté. Po první kontrole byly opravené hrany omítky, opakování prken, nesprávné UV kamenného ostění a hustota modelu.
- GLB import proběhl v Godotu 4.6.3. Normální mapy, AO a mapa drsnosti jsou také ověřené v exportovaných glTF materiálech.
- Automatický test: skutečná kolize zavřených dveří, rozměry a poloha modelu vzhledem k pantu, dráha kolizního křídla v obou směrech, průchod kapsle hráče, zavření a zabránění zavření přes hráče, překážka v okně, oba LOD i hysteréze.
- Původní test procházky prošel: pohyb, více dotyků, mapování ovladače, animace dveří, kolize, pavlač a patra věže.
- Statický detail: 39 218 trojúhelníků v 6 materiálových plochách. LOD1: 12 018 trojúhelníků. Dveře: 2 076 trojúhelníků ve 2 plochách. To nejsou měřené draw calls na tabletu.
- Nebyl změřen výkon Xiaomi Pad 8 ani připojen skutečný Xbox ovladač. Nebyl pořízen render této části z Godotu; vzhled v mobilním rendereru je nutné ověřit po vložení. Cycles osvětlení se nepřenáší automaticky do hry.

## Reprodukce v cloudu

Po instalaci Blenderu 3.6+ a Pythonu s Pillow:

```sh
python3 tools/fetch_materials.py
python3 tools/blender/prepare_section_textures.py
blender --background --factory-startup --threads 4 --python tools/blender/section_01.py
godot --headless --editor --import
godot --headless --script tests/blender_section.gd
```

Nábytek, inventář, NPC a úkoly nebyly přidané. Samostatné soubory a scéna umožňují další díly bez zásahu do ovládání. Veškeré renderování proběhlo v cloudovém prostředí, není potřeba počítač uživatele.
