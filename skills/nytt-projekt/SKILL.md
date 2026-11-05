---
name: nytt-projekt
description: "Använd när ett nytt uppdrag ska sättas upp: konsulten berättar att ett anbud är vunnet eller ett uppdrag hemtaget ('vi vann anbudet', 'vi fick uppdraget'), att ett nytt projekt eller en ny kund startar, eller ber om en ny projektmapp med Ekans standardstruktur. Använd INTE för projektdirektiv eller dokument i befintliga projektmappar."
argument-hint: "<kund-uppdrag>"
---

# Nytt projekt

Skapar projektmapp med Ekans standardstruktur (mappar 10–80 + projekt-CLAUDE.md) via skript. Skriptet validerar namnet, vägrar skriva över befintliga projekt och städar upp vid fel.

## Workflow

### 1. Bestäm projektnamn

Format: `kund-uppdrag`, gemener med bindestreck (t.ex. `exempelstaden-intern-kommunikation`).

- Angavs ett namn som argument ($ARGUMENTS)? Använd det.
- Annars: härled ett förslag från samtalet (kund + uppdragets kärna).
- **Bekräfta alltid namnet med konsulten innan mappen skapas** — skriptet skapar kataloger på disk.

### 2. Kör skriptet

Via Bash-tool:

`powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/hooks/nytt-projekt.ps1" -Namn "<projektnamn>"`

### 3. Bekräfta och peka framåt

Bekräfta vad som skapades och påminn om nästa steg:

1. Fyll i `CLAUDE.md` i projektmappen (kund, beställare, syfte, team)
2. Lägg källmaterial i `50 Styrande dokument/` (avtal, förfrågningsunderlag, offert — vid vunnet anbud: anbudet, det är källmaterialet för projektdirektivet) och `40 Bakgrundsmaterial/`
3. Kör `/ekan:projektdirektiv` när uppdraget är tydligare definierat
