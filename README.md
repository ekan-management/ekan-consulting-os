# Ekan Consulting OS

Ekans AI-konsult-OS för Claude Code. Skills, hooks och ramverk skräddarsydda för managementkonsulter.

## Förutsättningar

- **Claude Code** — terminal, desktop-app eller IDE-extension
- **PowerShell** — hookarna körs i den inbyggda Windows PowerShell 5.1, men **PowerShell 7 (`pwsh`) rekommenderas**: bättre UTF-8-hantering och snabbare uppstart. [Installera här](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows)
- **Python 3** — används av mallskripten i `scripts/` (Word/Office). `/ekan:setup` installerar paketen automatiskt

## Installation

Pluginet installeras likadant oavsett var du kör Claude Code — terminal, desktop-app eller IDE-extension:

```
/plugin marketplace add ekan-management/ekan-plugins
/plugin install ekan@ekan-plugins
/ekan:setup
```

Desktop-appen och VS Code-extensionen har även grafiska plugin-hanterare (`+` → Plugins respektive `/plugins`) om du hellre klickar.

`/ekan:setup` städar upp legacy-artifakter från tidigare installationer, installerar ramverks-CLAUDE.md till `~/consulting/`, mergear Ekan-rekommenderade permissions och slår på automatisk uppdatering av pluginet. Filer som skrivs över sparas först, se tabellen nedan. Starta om Claude Code efter setup.

### Ekans mallar

Ekans Office-mallar ingår inte i pluginet. Hämta dem från Ekans SharePoint och lägg dem i `~/consulting/templates/`. Tre mallar behövs för att skillsen ska fungera:

- `Mall Projektdirektiv.docx` och `Mall Uppdragsdirektiv Små uppdrag.docx`, som `/ekan:projektdirektiv` använder
- `Mall anteckningar.docx`, som `scripts/md_to_word.py` använder som standardmall

Övriga mallar du lägger i mappen kopierar `/ekan:nytt-projekt` in i varje nytt projekt. `/ekan:setup` listar de mallar som saknas.

Efter setup:
```
cd ~/consulting
claude
/ekan:intro
```

### Har du redan en egen konfiguration?

Pluginet skriver till några filer i `~/consulting/` och `~/.claude/settings.json`. Kontrollera listan om du redan har egna filer på de platserna.

| Vad | När | Vad som händer |
|---|---|---|
| `~/consulting/CLAUDE.md` | Setup och varje sessionsstart | Ersätts med Ekans version. Din tidigare fil sparas som `CLAUDE.md.bak`. Lägg egna instruktioner i `MY-CLAUDE.md`, som aldrig skrivs över |
| `~/consulting/ramverk/` | Setup och varje sessionsstart | Pluginets egen mapp. Ändrade filer sparas som `.bak`, men egna filer i mappen tas bort |
| `~/consulting/scripts/` | Setup och varje sessionsstart | `read_office.py`, `md_to_word.py` och `check_diakriter.py` ersätts, med `.bak` av en ändrad fil. Dina övriga skript rörs inte |
| `~/consulting/ROADMAP.md` | Varje sessionsstart | Ersätts, med `.bak` |
| `~/.claude/settings.json` | Setup | Säkerhetskopieras till `~/.claude/backups/` först. Ekans behörigheter läggs till dina, och `defaultMode` och `language` sätts bara om de saknas. Ekans gamla hooks tas bort, dina egna ligger kvar |
| Skills och kommandon i `~/.claude/` med Ekans gamla namn | Setup | Listas, och raderas först när du bekräftar |

Sessionsstarten synkar bara om `~/consulting` finns. Den körs alltså redan i första sessionen efter installationen, även innan du kört setup.

## Uppdateringar

`/ekan:setup` slår på automatisk uppdatering. Marknadsplatser från tredje part uppdateras annars inte automatiskt, så den som hoppar över setup blir kvar på den version den installerade. Setup skriver `autoUpdate: true` för `ekan-plugins` och `FORCE_AUTOUPDATE_PLUGINS=1` i `~/.claude/settings.json`. Inställningen läses när Claude Code startar, så starta om efter setup.

En ny version hämtas i bakgrunden när en session startar och gäller från sessionen därefter. Ramverkets `CLAUDE.md` och filerna i `ramverk/` synkas då till `~/consulting/`, och överskrivna filer sparas med en `.bak` vid sidan.

Manuell uppdatering, om något krånglar: `/plugin update ekan`.

## Slash-kommandon

Alla Ekan-kommandon har prefix `/ekan:`. Använd `/help` i Claude Code för komplett lista.

| Kommando | Syfte |
|---|---|
| `/ekan:intro` | Introduktion till Ekan-plugin |
| `/ekan:jobb` | Listar aktiva projekt, föreslår to-do |
| `/ekan:nytt-projekt` | Skapar ny projektmapp med Ekans standardstruktur |
| `/ekan:projektdirektiv` | Genererar projektdirektiv som Word-fil |
| `/ekan:setup` | Legacy-cleanup + ramverks-installation |

`nytt-projekt` och `projektdirektiv` är skills: Claude aktiverar dem också automatiskt när situationen matchar (t.ex. "vi har vunnit anbudet" → ny projektmapp) — slash-kommandot är den manuella vägen.

## Arkitektur

Tre lager som laddas tillsammans:

1. **Plattform** (`~/.claude/settings.json`) — permissions, global Claude-konfig
2. **Ramverk** (`~/consulting/CLAUDE.md`) — Ekan-metodik, språkkonventioner, skill-katalog
3. **Utförande** (pluginet) — skills och hooks

Ramverket består av `CLAUDE.md` och referensfilerna i `ramverk/`. `CLAUDE.md` läses vid varje sessionsstart och pekar ut referensfilerna, som Claude läser först när uppgiften kräver dem. Båda synkas från pluginet vid sessionsstart.

## Namespace-konvention

Plugin-kommandon har alltid prefix — `/ekan:intro`, inte `/intro`. Detta är Claude Code:s standard för plugin-kommandon. Session-start-hooken visar tillgängliga kommandon som påminnelse.

Personliga skills ligger i konsultens `~/consulting/skills/` med mappnamn som börjar på `personal-` (t.ex. `personal-2c8-process-modeling`). Prefixet markerar dem som lokala. En `personal-*`-skill som visat värde kan graduera till pluginet via PR.

## Samverkande plugins

Ekan-pluginet samverkar med två officiella Claude Code-plugins som konsulten installerar själv via `/plugin install`. `/ekan:setup` installerar dem inte.

- **`superpowers`**: brainstorming inför kreativt arbete, planering inför komplexa implementationer, systematisk felsökning och kodgranskning. Skillsen triggar på sina egna beskrivningar.
- **`claude-md-management`**: `revise-claude-md` uppdaterar CLAUDE.md med lärdomar från en session. Kör den efter ett projekt eller när ett återkommande mönster syns.

## Felsökning

**`/plugin marketplace add` ger nätverksfel:**
Kontrollera VPN/proxy (Ekan-nät kan blockera GitHub). Marketplacen hämtas direkt från GitHub — kommer du inte åt `github.com` i webbläsaren når inte Claude Code den heller.

**`/ekan:setup` frågar om permission:**
Svara `y` — skriptet gör medvetna filoperationer (permissions-merge, backup-skapande). Dry-run visas före prompten så du ser exakt vilka filer som påverkas.

**`/ekan:intro` säger "Unknown command":**
1. Verifiera prefixet — kommandot är `/ekan:intro`, inte `/intro`.
2. Kör `/plugin list` och verifiera att `ekan` är installerat.
3. Starta Claude Code i `~/consulting/` (ramverks-CLAUDE.md laddas bara där).
4. Om inget hjälper: kör `/ekan:setup` igen.

## Struktur

```
ekan-consulting-os/
├── .claude-plugin/plugin.json      Plugin-manifest
├── commands/                        Slash-kommandon (md-prompts)
├── hooks/                           PowerShell-hooks + hooks.json
├── skills/                          Intro, nytt-projekt, projektdirektiv
├── consulting/                      Ramverks-CLAUDE.md, ramverk/ + MY-CLAUDE.md template
├── config/permissions-template.json Permissions som /ekan:setup mergear in
├── scripts/                         Python-hjälpskript (Word/Office)
└── tests/                           Pester-tester
```

## Bidra

Rapportera buggar eller föreslå skills via issues på GitHub. För nya skill-förslag, se `ROADMAP.md`.

## Licens

Källkoden är publik att läsa, så att Ekans konsulter kan installera pluginet utan GitHub-konto. Alla rättigheter förbehålls Ekan AB. Se [LICENSE](LICENSE).
