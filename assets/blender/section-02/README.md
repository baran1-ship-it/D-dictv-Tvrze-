# Část 02 — fasáda a navazující místo v nádvoří

Navazuje na část 01 a na schválený celkový výtvarný návrh. Není určena k opakování po celé tvrzi. Jde o konkrétní výřez fasády obytného křídla se vstupem a navazující povrchy nádvoří. Rozměry dveří, okna, podlah a cílová poloha zůstávají stejné jako v části 01; hlavní fortress_builder ani ovládání nebyly změněné.

## Změny

- Odstraněné pravidelné kamenné řady. Každý kámen má vlastní polygonální tvar, obroušené hrany, jinak široké spáry a mělkou vystupující plochu; geometrie zasahuje pouze několik centimetrů před jádro; kameny mají také mírně zaoblená čela.
- Větší souvislé plochy vápenné omítky s místními nepravidelnými ztrátami. Hrubší sokl je místy tmavší od vlhkosti, nikoli po celé fasádě stejně.
- Nádvoří 9 × 5,9 m má zeminu, nepravidelné kamenné cesty, desku u prahu a menší zelené trsy mimo hlavní průchod. Dlažba nepokrývá celou plochu, její výška se mírně mění. Jednoduchá plynulá kolize nebrzdí hráče o každý kamínek.
- Původní funkční křídlo, pant, madlo, tween, ochrana před zavřením přes hráče a rozměry průchodu zůstávají zachované.

## Soubory a ověření

`section-static.glb`, `section-lod1.glb`, `door-leaf.glb`, samostatná scéna `scenes/blender/section_02.tscn`, její adapter a test; nativní model a tři kontrolní PNG v `source_art/blender/section-02`. Cycles náhledy byly vizuálně zkontrolované. Podle první kontroly byly upravené rozestupy a hrany kamenů, doplněný vlhčí sokl a opravené zahrnutí zeminy i trávy do GLB. Další kontrola vedla ke změkčení kamenných čel a k menším prohnutým travním lístkům.

Test Godotu 4.6.3 prošel: import, poloha a rozměry křídla vůči pantu/kolizi, obě dráhy otevírání, průchod kapsle, zavření, ochrana před zavřením přes hráče, zábrana v okně, kolize nového terénu, oba LOD a hysteréze. Exportované materiály skutečně zahrnují hlínu, zeleň i vlhčí sokl.

Počty jsou v geometry-report.json. Počet materiálových ploch není měřením draw calls na tabletu. Neproběhlo měření FPS na Xiaomi Pad 8 ani render nové části v Godotu. Zeleň je zatím jednoduchý model; kresba omítky, kámen a celkový stupeň realismu vyžadují další výtvarné posouzení. Model není označený za finální grafickou kvalitu celé hry.

## Materiály a reprodukce

Kámen, omítka a dřevo vycházejí z původních CC0 map Poly Haven: Rock Face 03 (Dario Barresi, Rico Cilliers), Plastered Wall (Amal Kumar), Roof Planks (Rob Tuytel). Mapy jsou vložené v GLB/Blenderu a originály i odvozené mapy v textures. Zemina má vlastní deterministické 512px albedo, normal, roughness a AO; nejde o fotku dlažby obarvenou nahnědo. Dřevěné albedo má ztlumenou sytost a jas; vlhký kámen je další barevnou úpravou původní CC0 fotografie. Přesné zdroje a SHA původních map obsahuje sources-section.json.

```sh
python3 tools/fetch_materials.py
python3 tools/blender/prepare_section_02.py
blender --background --factory-startup --threads 4 --python tools/blender/section_02.py
godot --headless --editor --import
godot --headless --script tests/blender_section_02.gd
```

Python příprava používá Pillow a NumPy. Práce a vykreslení proběhly v cloudu, uživatel nepotřebuje PC. Main scéna se tímto balíčkem nemění; při budoucím vložení se má odpovídající původní fasáda i dlažba nahradit, nikoli překrýt. Cílový střed fasády `(8,0,8)`, natočení Y `-90°`. Předchozí část je zachovaná na záložní větvi i jako samostatný soubor.
