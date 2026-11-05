# Roadmap — Ekans Consulting OS

Planerade förbättringar och skill-kandidater. Levande dokument — uppdateras löpande av repo-ansvarig och bidragande konsulter.

---

## Strategisk riktning

### ~~Hybriddistribution — Claude Code plugin + setup-script~~ ✅ Avvecklad 3.0.0

Hybrid-fallbacken infördes i 2.0.0 för Desktop/IDE-användare som antogs sakna plugin-stöd. Antagandet höll inte: desktop-appen och VS Code-extensionen har egna plugin-hanterare, och JetBrains når `/plugin` via IDE-terminalen. `setup.ps1`, `update.ps1` och `lib/install-lib.ps1` togs bort i 3.0.0 — plugin-distribution är enda vägen.

### Cross-platform (Mac)

Distributionen är plattformsoberoende sedan hybrid-skripten försvann. Kvar är hookarna: `ekan-setup.ps1`, `session-start.ps1`, `jobb.ps1` och `nytt-projekt.ps1` är PowerShell och körs via `powershell`/`pwsh` i `hooks/hooks.json`. Mac-stöd kräver antingen `pwsh` som förutsättning (PowerShell 7 finns för macOS) eller portning till `sh`. Första steget är att avgöra vilket — inte att skriva ett `setup.sh`.

### ~~Döp om repot~~ ✅ Slutfört 2.0.0

Repot heter nu `ekan-consulting-os` (marketplace-ref) — plugin-arkitekturen gör det äkta. Namespace-prefix `/ekan:` löser kollisioner naturligt och junctions behövs inte längre.

---

## Skill-kandidater

| Skill | Status | Beskrivning | Mall finns? |
|---|---|---|---|
| `konsultcv` | Under utveckling | Uppdaterar konsult-CV vid projektavslut | — |
| `/slutrapport` | Graduation-kandidat | Stöder `Mall Slutrapport.docx` respektive små uppdrag — finns lokalt som `personal-slutrapport`, ska upp i plugin | ✅ |
| `2c8-process-modeling` | Graduation-kandidat | Processmodellering för 2c8-kunder — finns lokalt, ska upp i plugin | — |
| `/motesanteckningar` | Graduation-kandidat | Skriver protokoll mot `Mall Minnesanteckningar.docx` — finns lokalt, ska upp i plugin | ✅ |

**Avslutsflöde:** `/ekan:slutrapport` + `/ekan:konsultcv` är ett orkestreringspar — när konsulten avslutar projekt erbjuder Claude sekvensen sammanfattning → CV-uppdatering → arkivering (se `consulting/CLAUDE.md` 6.2). De bör prioriteras tillsammans.

---

## Strukturella initiativ

| Initiativ | Status | Anteckning |
|---|---|---|
| Migration till `ekan-*`/`personal-*` namnrymd | Pågår | Steg 1 klart (dokumentation). Steg 2 (prefix befintliga skills) öppet. |
| Eliminera junction `~/.claude/skills` → `~/consulting/skills` | Planerad | Del av Steg 2 |
| Uninstall-skript (`uninstall.ps1`) | Ej påbörjad | Rensa `~/.claude/hooks/*`, `~/.claude/skills/*` utan att röra konsultens `consulting/`-mapp |
| Omfångsmätning i `session-start.ps1` | Planerad | Hooken scannar redan `projects/*/CLAUDE.md`. Låt den rapportera radantal och nämna filer som passerat 500 rader. Gör den osynliga kontextkostnaden synlig; botar inget själv. |
| Skill `claude-md-vard` | Planerad | Kurerar en projekt-CLAUDE.md: mäter, klassificerar avsnitt på datum och ersättning, föreslår flytt till `CLAUDE-historik.md` och `underlag/`. **Krav:** visa vad den vill flytta innan den flyttar, och verifiera konservation mekaniskt. Vid uppstädningen 2026-09-18 svepte ett mekaniskt script 16 punkter som inte var avklarade in i historiken; femton var märkta "skippad" och hörde dit, en var genuint öppen och hittades bara genom att räkna checkboxar före och efter. |
| Plugin-CLAUDE.md uppgraderad till rik standard | ✅ Slutfört 2026-04-27 | Refaktorering till 8 sektioner + nya standarder för konsultarbete (källförankring, projektdokument, filhantering, beteenden) |

---

## Kodkvalitet — uppföljning

Följande granskningspunkter identifierades vid review (april 2026) men är ej åtgärdade här. Prioritera vid behov:

| Punkt | Fil | Anteckning |
|---|---|---|
| ~~`update.ps1` raderar inte föråldrade filer~~ | — | ✅ Bortfallen 3.0.0 — `update.ps1` finns inte längre. Plugin-uppdatering ersätter hela plugin-katalogen, så sync-semantiken ägs av Claude Code. Legacy-städning av oprefixade kommandon sker i `ekan-setup.ps1` (`$legacyCommands`). |
| ~~Två nära färger i `consulting/CLAUDE.md`~~ | `consulting/CLAUDE.md` | ✅ Åtgärdat 2026-04-27 — konsoliderat till `#8B2E2E` (Mörkröd/vinröd). |
| ~~`settings.json`: `Skill(projektdirektiv)`~~ | `config/permissions-template.json` | ✅ Avgjort 2026-06-09 — `Skill(namn)` är korrekt syntax för exakt match (`Skill(namn *)` för prefix, per officiell docs). Alla fyra skills tillagda i allow-listan i 2.4.0. |
| Fler Pester-tester | `tests/` | `nytt-projekt.ps1` och `jobb.ps1` saknar tester. |
