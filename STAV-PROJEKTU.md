# Procházka 0.5 — ověřené sestavení

Opravy podle deseti fotografií z tabletu: podesty u zdí, účinné zábradlí u podest i šikmých schodů, směr otevření horních dveří, kamenná cesta za věží a severními budovami, odebraná okna do hradeb a vybavení místností. Prostorové kameny hradeb, různé měřítko a odstín zdiva paláce a věže, vápenná omítka a dřevěné šindele.

## Výsledek ověření

- Zdroj APK: commit `b140eda664fbf45d05c596243bafc90e5cf6d8c2`.
- [Úspěšné sestavení a kontroly](https://github.com/baran1-ship-it/D-dictv-Tvrze-/actions/runs/37936358978), 9. října 2026.
- Android: `cz.dedictvitvrze.prochazka`, versionCode 5, versionName 0.5.0; podpis APK ověřen. Stejný balíček a podpis jako 0.4.
- SHA-256 APK: `468b6fc8eb7c4bcd835e56359bba401cebbf300ac34b07f56236fe4c88720e1c`.
- Automaticky ověřeno: průchod osmi schodišti, patry věže i všemi čtyřmi stranami ochozu; podesty u zdí; zábradlí; podlahy na obou stranách prahů; celá dráha horních dveří bez střetu se stavbou. Celkem 19 dveří.
- Kontroly dotykového ovládání, mapování ovladače a animace ruky prošly. Připojení skutečného Xbox ovladače a výkon na Xiaomi Pad 8 nebyly v tomto prostředí změřeny.
- Vykresleno 15 pohledů přímo ze scény. Před předáním byly vizuálně prohlédnuty; snímek `door-swing` nezachycuje otevřené dveře, proto není předkládán jako jejich vizuální důkaz.
- Diagnostika scény: 17 573 uzavřených kamenů hradeb, 19 376 šindelů, 719 154 buněk stavebních sítí a dlažby; 385 vykreslovacích volání v diagnostickém pohledu. Statické díly jsou sloučené.

Kameny hradeb mají skutečný objem, ale jejich obrysy jsou zatím hranatější než fotografická předloha. Okolní vegetace a ruka zůstávají prototypové. Výsledek není označený za grafiku na úrovni KCD2.
