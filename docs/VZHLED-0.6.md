# Dědictví tvrze 0.6 — celková zkouška vzhledu

Vychází z Blenderové části 02. Její konstrukční princip je přenesen do existujícího generátoru Godotu; celý modul se nekopíruje po tvrzi. Samostatný Blender model zůstává v původní výtvarné větvi.

- Hradby, palác a věž používají různé velikosti polygonálních kamenů a samostatné barevné materiály. Kameny jsou uzavřená geometrie s obroušenými hranami a vystupují přibližně 1–4 cm, místo původních až 18 cm.
- Obytné stěny mají souvislou vápennou omítku. Její poškození se řídí společným prostorovým polem i přes sousední díly a má interpolované nepravidelné okraje.
- Nádvoří používá globální nepravidelnou dlažbu podél tras mezi vstupy. Nevyužité části jsou hlína; drobná zeleň je mimo průchody. Kolize podlahy je stále hladká.
- Hlavní střechy mají samostatnou tlumenou hnědočervenou krytinu, kryté schodiště dřevěný šindel. Jde o současnou zjednodušenou zkoušku krytiny, nikoli finální detail historických tašek.
- Rozměry a dispozice, dveřní kolize a animace, podesty, schodiště, zábradlí, ovládání a save systém zůstávají zachovány.

Materiály vycházejí ze stejných zamčených CC0 PBR zdrojů uvedených v MATERIALY-A-ZDROJE.md a assets/materials/pbr/sources.json. Hlína je vlastní deterministický šum vytvořený v Godotu. Statická geometrie je sdružena po materiálech. Tato verze nemá nové vzdálenostní LOD pro celý model a výkon na Xiaomi Pad 8 nebyl změřen. Výtvarná kvalita je stále pracovní.

APK má versionCode 6 a versionName 0.6.0, stejný identifikátor balíčku. Před změnou existuje záložní větev backup/before-whole-fortress-art-2026-10-09. Test smoke prochází všemi osmi schodišti, propojeným ochozem, horními průchody, animací dveří, jejich kolizemi a dotykovým/ovladačovým mapováním. Vizuální skript pořizuje skutečné herní náhledy; nejde o Blender render ani koncept z imagegen.
