# Dědictví tvrze — procházka 0.5

Offline Android procházka původní českou tvrzí z první osoby. Podoba navazuje na schválený realistický návrh inspirovaný Suchdolem a KCD2; nepoužívá assety této hry. Kvalita obrázkového konceptu není zárukou stejné kvality běžící scény.

## Přestavba

Propojený palác a obytné křídlo, věž s přízemím a třemi patry. Kompaktní kryté U schodiště u pavlače, schody ve věži u zdi, obranný ochoz podél západních a jižních hradeb a kamenná cesta podél severních a východních hradeb včetně průchodu nad bránou, přístup z paláce a nádvoří. Horní dveře obytného křídla do prázdna jsou nahrazené oknem.

Kameny, dlažba a překrývající se dřevěné šindele mají skutečný prostorový reliéf. Dlažba má pod viditelnými kostkami plynulou kolizní plochu. Prkna, trámy, stupně, nosníky, zábradlí a podpěry jsou samostatné díly se směrem vláken podél dřeva a čely s letokruhy. Zdivo má zapuštěné spáry, okna mají skutečné otvory s ostěním, příčkami a okenicemi. Část interiérů má vápennou omítku. Zdivo, dlažba, střechy a omítka využívají fotografované PBR mapy Poly Haven pod CC0. Výškové mapy jsou převedené na skutečný reliéf sítí. Podrobné zdroje a výběr: [Materiály a zdroje](docs/MATERIALY-A-ZDROJE.md).

Před lokálním otevřením spusť `python3 tools/fetch_materials.py`. Actions mapy stáhne a ověří automaticky. APK je obsahuje a funguje offline.

## Ovládání

Dotyk: levý joystick chůze, tažení vpravo rozhled, DVEŘE interakce, horní tlačítko pauza. Xbox: levá páčka chůze, pravá rozhled, A dveře, Menu pauza, A/B návrat. PC: WASD, myš, E, Esc.

Jedinou interakcí jsou dveře. Madla a upevňovací destičky jsou na obou stranách dveřního křídla. Pro dosažení rukou je nutné přistoupit blízko. Zavření je blokováno, stojí-li hráč v průchodu. Střelnice, bodování ani jiné akce nejsou aktivní.

## Sestavení a testy

Godot 4.6.3 Compatibility, Android ID `cz.dedictvitvrze.prochazka`, verze 0.5.0. APK aktualizuje předchozí procházku a ponechává původní střelecký prototyp zvlášť. Podepisovací debug klíč používá cache Actions; nejde o distribuční klíč pro obchod.

Actions importuje projekt, ověří dotyky, tlačítka ovladače, animaci ruky, dveře a kolize, kontrolu jejich celého otevření, výstup po všech schodištích, průchod po ochozu přes bránu a podporu podlahy na obou stranách každých dveří. Kontrolní snímky pokrývají nádvoří, východní střechy, ochoz, věžové schody a dveře. Skutečná Bluetooth/USB kompatibilita Xboxu a výkon na tabletu vyžadují uživatelskou zkoušku.

Statické povrchy jsou sloučené podle materiálu; výškové mapy tvarují jejich síť. Jemné detaily mají mipmapy, skutečné normal mapy, drsnost a AO. Výkon nelze odvozovat pouze z obrázku konceptu.

V 0.5 mají hradby vlastní prostorové kameny a střechy jednotlivé dřevěné šindele. Severní a východní kamenný ochoz je přístupný ze jižních hradeb i novými dveřmi z věže. Okna do hradeb a vybavení místností jsou odebrané. Rozšířené testy kontrolují viditelné podesty u zdi, ochranu otočných podest, pohyb po celé nové cestě a celý rozsah otevírání horních dveří proti zábradlím a stěnám.
