# Dědictví tvrze — prototyp 0.1

Vlastní středověká hra z první osoby pro budoucí Android verzi. Tvrz je první oblast plánovaného otevřeného světa. Prototyp má jednoduchou blokovou grafiku; nejde o dokončenou mobilní hru.

## Spuštění

Otevřete `project.godot` v Godotu 4.6.3 a stiskněte F6/F5. Z příkazové řádky: `godot --path cesta/k/dedictvi-tvrze`.

WASD: chůze, myš: rozhled, E: interakce. Podržení levého tlačítka natáhne luk, uvolnění vypustí šíp. Esc uvolní kurzor. Dotyk: levá část displeje ovládá pohyb, pravá rozhled; AKCE používá předmět, LUK se drží a pustí. Schodiště do ložnice začíná u jižní hradby před věží.

## Implementováno

- Nádvoří, kovárna, kuchyň, hodovní síň s krbem, věž s přístupnou ložnicí.
- Chůze, kolize, schody a dotykové ovládání.
- Luk, nátah, gravitace šípů, kolize s terči, počítání zásahů.
- Jedno vylepšení kovárny: pracovní stůl bez materiálové ekonomiky.
- Uložení spánkem, posun čísla dne, obnovení u postele po spuštění.
- Atomické přepsání uložené hry přes dočasný soubor a záloha předchozího spánku.
- Načítání a uvolňování pěti oblastí podle vzdálenosti s hysterezí.

## Zatím není hotovo

Android APK, test na telefonu, inventář, kování a vaření, vyzvedávání šípů, animace spánku, denní cyklus, tři pozice uložení, přerušovací uložení, gamepad, zvuky, stahování balíčků a průchod za bránu. Záloha je zatím určena k ruční obnově. Oheň je statická geometrie a světlo.

## Android

Projekt používá renderer Compatibility a orientaci na šířku. Pro export potřebujete Android SDK, JDK a exportní šablony pro Godot 4.6.3. V Godotu nastavte Android export preset, unikátní identifikátor aplikace a SDK cestu; pro zkušební instalaci exportujte debug APK. Distribuční AAB vyžaduje vlastní podpisový klíč. APK zatím nebylo sestaveno; mobilní výkon a ovládání nejsou ověřené na zařízení.

## Ověření

`godot --headless --path . --script res://tests/smoke.gd`

Test používejte s odděleným `XDG_DATA_HOME`, aby nepřepsal vaši rozehranou hru. Ověřuje zásah letícím šípem, průchod schodištěm, dosažitelnost postele, uložení a obnovení postupu a načítání/uvolňování oblastí.
