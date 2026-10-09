# APK přes GitHub Actions

Projekt obsahuje `.github/workflows/android.yml` a Android export preset. Workflow se spustí po pushi na main/master nebo ručně v Actions → Android APK → Run workflow.

Nahrajte obsah této složky do kořene GitHub repozitáře včetně skryté `.github`. Soubor `project.godot` musí být v kořeni, nikoli v další vnořené složce. Pokud nahráváte přes web, nezapomeňte na workflow; ZIP se musí nejprve rozbalit.

Workflow nainstaluje Java 17, Android SDK a Godot 4.6.3 s odpovídajícími exportními šablonami. Ověří herní základ, vytvoří debug APK pro ARMv7/ARM64, zkontroluje podpis a uloží APK jako artefakt `dedictvi-tvrze-android`. Po úspěchu otevřete dokončený běh a stáhněte artefakt v části Artifacts. ZIP rozbalte a APK přeneste do telefonu.

APK je zkušební sestavení mimo Google Play. Telefon může požadovat povolení instalace z použitého zdroje. Debug klíč se generuje nově v každém běhu, proto může další instalace vyžadovat odinstalaci starší aplikace, která odstraní její uložený postup. Pro dlouhodobé testování potřebujeme stálý klíč v GitHub Secrets; pro vydání vlastní release podpis.

Workflow zatím nebylo spuštěno na GitHubu. Úspěšný lokální test nenahrazuje ověření Android exportu ani běhu na telefonu. Pokud běh selže, přesná chyba bude v logu příslušného kroku. Pro nahrání a spuštění z asistenta je potřeba připojený GitHub a cílový repozitář.
