# Dědictví tvrze — procházka 0.2

Offline Android prototyp pro průzkum české středověké tvrze z první osoby. Výtvarný směr vychází ze schválené realistické předlohy inspirované Suchdolem; současná scéna je původní model, nikoli kopie herních assetů KCD2. Grafika využívá nové obrazové materiály kamene a dubového dřeva, reliéf povrchů, sloučené statické modely, stíny a přirozenou oblohu. Kvalita ani výkon nebyly dosud potvrzeny na fyzickém tabletu.

## První procházková verze

- Propojený severní palác s kovárnou, kuchyní a hodovní síní; pavlač a obytné východní křídlo.
- Věž: přízemí a tři patra, vnitřní dvojramenné schodiště s podestami.
- Jediná interakce: 17 dveří s kováním. Ruka dosáhne na madlo, dveře se otevřou nebo zavřou. Zavření se odmítne, stojí-li hráč přímo v průchodu.
- Bez luku, terčů, bodování, vylepšování a ukládání spánkem. Nábytek je pouze součást prostředí.

## Ovládání

Tablet: levý viditelný joystick ovládá chůzi, tažení vpravo rozhled, tlačítko DVEŘE interakci, horní tlačítko pauzu. Současný pohyb, rozhled a interakce mají oddělené dotyky.

Xbox ovladač: levá páčka chůze, pravá rozhled, A dveře, Menu pauza, A/B návrat z pauzy. Podpora využívá standardní mapování Godotu a Androidu; skutečné Bluetooth/USB spojení je třeba ověřit na zařízení. Ovládání se přepne na dotyk při použití obrazovky. Odpojení ovladače zastaví pohyb.

PC: WASD, myš, E nebo levé tlačítko, Esc pauza.

## Sestavení a ověření

Godot 4.6.3, renderer Compatibility. GitHub Actions importuje scénu, testuje skutečné kolize, schody a animované dveře, prověřuje dotyky a mapování tlačítek, vytváří dvě kontrolní fotografie běžící scény a ověřuje podpis APK. Výstup je `dedictvi-tvrze-prochazka`.

Procházka používá samostatné ID `cz.dedictvitvrze.prochazka`, aby první novou verzi bylo možné instalovat vedle původního prototypu. Debug podpisový klíč pro následující sestavení se uchovává v cache Actions. Jde o testovací podpis, nikoli distribuční klíč pro obchod.

Obrazové materiály vznikly generováním obrázků pro tento projekt. Kód vlastní scény a ovládání je v `scripts/fortress_builder.gd`, `fortress_door.gd`, `exploration_controls.gd` a `game.gd`. Staré skripty pro ukládání a streaming nejsou v procházkové scéně aktivní.
