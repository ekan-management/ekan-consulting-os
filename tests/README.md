# Tester

Pester-baserade tester för PowerShell-skripten.

## Installera Pester

```powershell
Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force
```

## Kör alla tester

```powershell
Invoke-Pester -Path tests\
```

## Kör enskild testfil

```powershell
Invoke-Pester -Path tests\ekan-setup.Tests.ps1
```

## Status

| Testfil | Täckning |
|---|---|
| `ekan-setup.Tests.ps1` | Legacy-detektion, idempotens, installation av ramverk |
| `session-start.Tests.ps1` | CLAUDE.md-autosynk, update-ping, JSON-output |
| `encoding.Tests.ps1` | UTF-8 BOM och parsbarhet för alla `.ps1` |
| `jobb.Tests.ps1` | Öppna uppgifter: underrubriker, avslut på samma nivå, `[x]`/`[~]` |
| `version.Tests.ps1` | VERSION, `plugin.json` och CHANGELOG hänger ihop, och aktuell version har `### För konsulten` |
| `uppdateringsnotis.Tests.ps1` | Uppdateringsnotisen: klarspråksrader ur CHANGELOG och nya skills |
| `onboarding.Tests.ps1` | Onboarding-prompten: flaggor som finns i setup, ingen intern adress, versionsrad |

## End-to-end

`e2e.ps1` går igenom hela konsultflödet mot en isolerad hemkatalog — installation,
projektstart, to-do-lista, sessionsstart, CLAUDE.md-synk och migrering från den
gamla installationen. Utskriften är skriven för att kunna läsas utan att granska
koden, så den fungerar som slutkontroll före release:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\e2e.ps1
pwsh       -NoProfile -ExecutionPolicy Bypass -File tests\e2e.ps1
```

Fler tester (nytt-projekt, jobb) är under utveckling — se `ROADMAP.md`.

## Kör i båda PowerShell-värdarna

Hookar, kommandon och skills startar alla skripten med `powershell` (Windows
PowerShell 5.1). Kör ändå testerna i båda värdarna innan du släpper,
eftersom kodningsfel bara syns i 5.1. Kör med stdin stängd (`< NUL`), annars kan
ett barnskal vänta på inmatning:

```powershell
powershell -NoProfile -Command "Invoke-Pester -Path tests\"
pwsh       -NoProfile -Command "Invoke-Pester -Path tests\"
```
