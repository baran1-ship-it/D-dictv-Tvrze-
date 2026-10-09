# Otevřený svět a rozšíření

## Směr

Tvrz je začátek společného světa s navazující krajinou. Otevření brány nemá přepnout hru do samostatné minihry. Svět postupně doplní podhradí, les a osada. První prototyp záměrně drží hráče uvnitř tvrze.

## Současný základ

`content/world.json` definuje oblasti se stabilními ID, verzí, středem a dosahem. `world_stream.gd` načítá okolní oblasti a vzdálené uvolňuje. Dvě různé vzdálenosti zabraňují neustálému načítání na hranici. Zatím jsou oblasti generované synchronně; tento postup stačí pro blokovou scénu, nikoli velký detailní svět.

Uložená hra obsahuje verzi schématu a stav hráče, nikoli kopii modelů světa. Vylepšení kovárny se obnoví nad výchozím obsahem. První verze ukládá jednu pozici spánku a záložní soubor.

## Než otevřeme krajinu

- Nahradit generátory samostatnými scénami a načítat je asynchronně s předstihem.
- Každému měnitelnému objektu přidělit stabilní ID, které přežije úpravu scény. Ukládat změny podle ID i pro právě nenačtené oblasti.
- Zavést migrace uložených her a kontrolu kompatibility balíčků. Odebrání potřebného balíčku nesmí tiše odstranit hráčův postup.
- Naplánovat souvislé cesty a hranice terénu; současné okolí je vizuální maketa.
- Profilovat skutečný Android telefon: paměť, stínování, dosah vykreslení, počet objektů a délku načítání. Zavést LOD a instancování vegetace.

## Obsahové balíčky

Plánovaný balíček má ID, verzi, minimální verzi aplikace, závislosti, velikost, kontrolní součet a seznam oblastí. Základ tvrze se dodává s aplikací a funguje offline. Další obsah se stáhne nejdřív do dočasného umístění, ověří a teprve potom aktivuje. Je potřeba obnova přerušeného stahování a kontrola volného místa.

Godot umožňuje distribuovat obsahové PCK balíčky. Budoucí stahované balíčky mají obsahovat schválená data a scény; nové herní mechanismy a spustitelné skripty budou vydávány aktualizací aplikace. Samotné PCK není bezpečnostní hranice; před aktivací je nutné ověřit původ a podpis. V prototypu zatím není downloader ani PCK loader.

## Vývojové etapy

1. Ověřit ovládání a střelnici na telefonu; doladit rozměry a schodiště.
2. Zavést inventář, materiály a první řemeslný postup; vylepšení tvrze navázat na práci a zásoby.
3. Přidat skutečný cyklus dne, spánek a více uložených pozic.
4. Otevřít bránu do malé navazující krajiny a ověřit asynchronní streaming.
5. Přidat první obsahový balíček a migraci uložené hry, teprve pak obyvatele a širší příběh.
