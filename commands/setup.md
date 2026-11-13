---
description: Kör Ekans setup — städa legacy, installera ramverk, mergea permissions
---

Kör Ekans setup-flöde: städa legacy-artifakter, installera ramverk, mergea permissions.

Kör via Bash-tool:

`powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/hooks/ekan-setup.ps1"`

Visa stdout i chatten så användaren ser vad som händer.

**Om utskriften listar legacy-artifakter och avbryts:** det är väntat. Skriptet körs via Bash-verktyget, som saknar konsol-stdin, så dess `Read-Host` kan inte besvaras — bekräftelsen måste ske här i chatten i stället.

Gör då så här:

1. Visa listan över artifakter som skriptet skrev ut, och tala om att de raderas från `~/.claude/` medan `~/consulting/` lämnas orört.
2. Fråga användaren om det ska genomföras.
3. Vid ja — kör om med bekräftelseflaggan:

   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/hooks/ekan-setup.ps1" -Yes`

Sätt aldrig `-Yes` i den första körningen, och aldrig utan att användaren sagt ja — flaggan hoppar över den enda spärren före radering.

Efter skriptets slut: be användaren starta en ny session med mappen `consulting` och skriva `/ekan:intro`.

Vill användaren peka ut en annan mallmapp än `~/consulting/templates`: kör om med `-Mallmapp "<mapp>"`. Vill användaren bara veta om miljön är komplett: kör med `-Kontroll`, som inte ändrar något.
