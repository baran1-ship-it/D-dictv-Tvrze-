# Materiály a předloha pro 0.5

Jedna předloha: schválené nádvoří s nepravidelným lomovým kamenem, světlým spárováním, dřevěnou pavlačí a obranným ochozem. Kameny nemají tvořit pravidelné kvádrové řady. Opracované kameny patří k ostění, nikoli na celé stěny.

## Převzaté assety — skutečně používané ve scéně

| Asset | Autor | Použití | Licence |
|---|---|---|---|
| [Stone Wall](https://polyhaven.com/a/stone_wall) | Charlotte Baglioni, Dario Barresi | Zdi, hradby, štíty | CC0-1.0 |
| [Cobblestone Floor 04](https://polyhaven.com/a/cobblestone_floor_04) | Rob Tuytel | Nerovná dlažba nádvoří | CC0-1.0 |
| [Roof Planks](https://polyhaven.com/a/roof_planks) | Rob Tuytel | Vlákna jednotlivých dřevěných šindelů; UV vynechávají spáry fotografie | CC0-1.0 |
| [Rock Face 03](https://polyhaven.com/a/rock_face_03) | Dario Barresi, Rico Cilliers | Povrch prostorových kamenů hradeb, ostění a kamenného ochozu | CC0-1.0 |
| [Plastered Wall](https://polyhaven.com/a/plastered_wall) | Amal Kumar | Vápenná omítka | CC0-1.0 |

[Licence Poly Haven](https://polyhaven.com/license) dovoluje užití, úpravy a redistribuci včetně komerčního projektu. Převzaté JPEG mapy nejsou generované AI. Každá má pevnou URL a kontrolní součet v `assets/materials/pbr/sources.json`. `python3 tools/fetch_materials.py` stáhne přesné soubory před importem; Actions to dělá automaticky. APK obsahuje mapy a za běhu nic nestahuje.

Materiál, normal mapa, drsnost, AO a geometrický reliéf sdílejí souřadnice. Výšková mapa skutečně tvaruje síť stěny/dlažby/střechy. Hlavní kameny ani spáry nevznikají pravidelným vrstvením kvádrů. Ostění, trámy, prkna, stupně a jejich nosníky zůstávají samostatné díly.

## Prohlédnutá řešení na GitHubu — inspirace, nikoli importované závislosti

- [Malcolm Snap Castle](https://github.com/Malcolmnixon/Malcolm-Snap-Castle), MIT: návazné stavební díly a ovladatelné dveře. Používá starší API Godotu; celý addon není přidaný do naší scény.
- [Rock Wall Builder](https://github.com/wildartworks/Rock_Wall_Builder), CC0: alternativní postup stěn ze samostatných náhodně natočených a škálovaných kamenů. Pro naši předlohu byla vybrána fotografovaná stěna s odpovídajícím reliéfem místo jeho výchozího rozmístění koulí.

## Odmítnuté varianty

`medieval_wall_02` má i cihlové opravy; `rustic_stone_wall_02` má dlouhé ploché kameny. Názvy assetů samy o sobě neurčují vhodnost. Nevytváříme směs odlišných hradních stavebnic. Základní okolní vegetace a některé díly zůstávají prototypové a nejsou na úrovni KCD2.

## Konstrukce a rozlišení částí v 0.5

Hradby mají uzavřené nepravidelné kameny z Voronoi buněk, zkosené hrany a čela různě vystupující 7–18 cm. Kameny mají vlastní fázi textury a jemnou barevnou odchylku. Rozložení se neopakuje po jednom čtverci a boční i horní plochy cimbuří mají skutečný objem. Palác má menší lomový kámen a části vápenné omítky, věž hrubší zdivo s jiným měřítkem a odstínem. Ostění používá skálu bez namalovaných spár mezi kameny.

Šindele mají jednotlivé obrysy, tloušťku a překrytí řad. Fotografovaná prkna dodávají pouze vlákna; mezery mezi prkny nejsou promítnuté přes šindele. Celý typ krytiny je dřevěný, nikoli došky ze slámy. Předloha: [Kašperk — šindelová krytina věže](https://www.kasperk.cz/zachrana-strechy), a [historie a rekonstrukce](https://www.kasperk.cz/o-kasperku/historie-a-rekonstrukce). Fotografie hradu slouží pouze ke studiu, nejsou použité jako herní textury.

Severní a východní hradby mají kamenný ochoz; východní zeď je odsunutá kvůli skutečné šířce průchodu. Okna paláce a obytného křídla směrem do hradeb jsou odstraněná, stejně jako všechna východní okna věže. Nové dveře a vnitřní schody spojují patro věže s ochozem. Nábytek, pece, postele, kovadlina a sudy jsou odebrané ze scény. Světla a omítka zůstávají součástí stavby.
