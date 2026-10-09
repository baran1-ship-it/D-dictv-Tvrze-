# Nahrání z Android tabletu

1. Stáhněte ZIP a rozbalte ho ve správci souborů. GitHub samotný ZIP nerozbalí.
2. V prohlížeči otevřete svůj repozitář na účtu baran1-ship-it. Zapněte „Web pro počítač“, pokud potřebné ovládání není vidět.
3. Použijte Add file → Upload files. Nahrajte rozbalené soubory a složky do kořene repozitáře. `project.godot` musí být přímo v kořeni.
4. Ujistěte se, že se nahrála i skrytá `.github/workflows/android.yml`. Android výběr souborů někdy nezachová složky. Jestli to neumožní, použijte Add file → Create new file a napište celou cestu `.github/workflows/android.yml`. Obsah vložte z odpovídajícího souboru v ZIPu. Stejně lze vytvořit soubory `scripts/game.gd`, `scripts/world_stream.gd`, `scripts/save_store.gd`, `content/world.json` a `tests/smoke.gd`, pokud se nezachovaly jejich složky. Soubory `.uid` lze nahrát, ale pro spuštění nejsou nezbytné.
5. Potvrďte Commit changes do větve main nebo master. Workflow se spustí automaticky.
6. Otevřete Actions → Android APK → poslední běh. Pokud se automaticky nespustil, zvolte Run workflow.
7. Po zeleném dokončení stáhněte v části Artifacts balíček `dedictvi-tvrze-android`. Rozbalte jej a otevřete `dedictvi-tvrze.apk`.

Před sestavením musí být v repozitáři tyto cesty:

- project.godot
- main.tscn
- export_presets.cfg
- scripts/game.gd
- scripts/world_stream.gd
- scripts/save_store.gd
- content/world.json
- tests/smoke.gd
- .github/workflows/android.yml

Sestavení vyžaduje povolené GitHub Actions. Workflow obsahuje stažení Godotu 4.6.3, odpovídajících Android šablon, instalaci Android SDK, herní testy, export a kontrolu podpisu. Nevyžaduje vlastní token ani secrets. Vytváří debug APK; klíč je nově vytvořen při každém sestavení. Další APK proto může vyžadovat odinstalování předchozí verze, což odstraní její uložený postup.

Konfigurace a herní testy byly ověřeny lokálně. Skutečný Android export zatím na GitHubu spuštěn nebyl. Pokud selže, otevřete červený krok a pošlete jeho chybový výpis.
