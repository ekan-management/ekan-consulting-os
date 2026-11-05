---
description: Visa en kompakt to-do-översikt för aktiva projekt och välj vad du ska jobba på
---

Kör detta kommando via Bash-tool och presentera resultatet som en kompakt to-do-översikt:

`powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/hooks/jobb.ps1"`

Formatera output så här:
```
Aktiva projekt — to-do
──────────────────────
[projektnamn]
Fas: [fas]
- [ ] Uppgift 1
- [ ] Uppgift 2
```

Regler:
- Visa bara uppgifter som är aktivt relevanta — filtrera bort uppgifter som tydligt tillhör framtida faser som inte startat ännu
- En rad per uppgift, inga förklaringar
- Avsluta med: "Vilket projekt kör vi på?"

När användaren svarar vilket projekt de vill köra på:
1. Matcha projektnamnet mot en mapp i `$env:USERPROFILE/consulting/projects/`
2. Läs alltid projektets CLAUDE.md med Read-verktyget: `$env:USERPROFILE/consulting/projects/[matchad-mapp]/CLAUDE.md`
3. Presentera en detaljerad to-do baserad på CLAUDE.md — gruppera per fas/sektion, inkludera deadlines och risker
4. Fråga vad användaren vill göra
