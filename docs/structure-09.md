# Dědictví tvrze 0.9 – výšky, klenby a tesařské spoje

Záloha původní 0.8: backup/before-vaults-and-joinery-2026-10-09, commit 417edfac3526842b36466cd15933f323af55928b.

## Výšky

Vrchol líce přízemních kamenných segmentových valených kleneb: 4,50 m. Skořepina 0,20 m. První kamenná podlaha má pochozí úroveň 5,00 m a tloušťku 0,26 m. Nad vrcholem klenby zbývá 0,04 m pod spodkem podlahové desky.

Palác a obytné křídlo: první patro má čistou výšku 3,00 m pod dřevěným stropem. Věž: pochozí úrovně 0 / 5,00 / 8,26 / 11,52 m; kamenné stropní desky dávají mezi horními patry 3,00 m světlé výšky. Poslední dřevěný strop má spodní líc 14,52 m. Schodišťový prostor věže má otevřené výřezy; klenba zakrývá hlavní přízemní místnost, nikoliv schodišťovou šachtu.

Všechny pavlače a obranné ochozy: 5,00 m, hradby 6,10 m + merlony. Venkovní schody mají 25 stupňů po 0,20 m, nášlap 0,32 m, délku 8,00 m. Vnitřní věžové schody přizpůsobeny jednotlivým výškovým rozdílům.

## Zapsané opravy podle screenshotů

35244: prkna všech pavlačí orientována od zdi k zábradlí. 35245: příčné nosné trámy pod podélnými, mírný přesah konce, vzpěry končí uvnitř trámu. 35246: uzavřené návratové plochy zdiva na rozích; zábradlí u zadní stěny odstraněno. 35248/35239 a 35249: horní madlo překrývá sloupek, sloupek končí uvnitř; společné rohové sloupky a překrytí madel. 35250–35252: souvislé napojení ochranných hran, odstranění vnitřních a zdvojených zábran, průchozí spojení podest s ochozy. 35253: dvoukřídlá vstupní vrata (dva synchronizované listy), otvor 5 m, výška 3,75 m. Vzpěry u vrat posunuty na x ±4,70 m; prostor vedle ostění zůstává volný pro budoucí louče. Louče zatím nepřidány.

## Kontrola

Automatické testy používají skutečnou hráčovu kapsli: stoupání a sestup venkovních schodů, všechny věžové stupně, celý obvod hradeb, přechody a návraty u problémových podest, dveře a společné otevírání/zavírání vrat. Paprsky kontrolují skutečný líc klenby a světlou výšku věžových pater. Obrazová kontrola probíhá v Godot rendereru ve stejném projektu, který se exportuje do APK; nejde o snímky z Android zařízení. CI ověřuje podpis a verzi APK. Fyzický Xbox ovladač a FPS na Xiaomi Pad 8 nelze v cloudu změřit.
