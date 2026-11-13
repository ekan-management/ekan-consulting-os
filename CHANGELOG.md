# Changelog

Varje version inleds med `### För konsulten`: en kort lista i klarspråk över
vad som är nytt och vad det betyder för konsulten. Sessionsstarten visar den
listan i varje ny session under ett dygn efter en uppdatering, så skriv utan
filnamn och tekniska termer. `tests/version.Tests.ps1` stoppar en release som
saknar avsnittet.

## 3.14.0 — 2026-11-12

### För konsulten

- Nya kollegor kommer igång genom att klistra in en färdig text i Claude Code. Du får texten av Stefan Edgren.
- Claude arbetar inte i synkade Teamsytor. Ladda ner filerna du behöver till projektmappen.
- Setup kontrollerar att Word-mallarna du lagt in går att öppna, och fungerar även om din inställningsfil är trasig.

### Ändrat

- **`onboarding/klistra-in.md`:** onboarding-prompten för desktop-appen. Den
  klistras in som den är och innehåller inga adresser till Ekans Teamsytor.
  `tests/onboarding.Tests.ps1` håller ihop promptens flaggor med `ekan-setup.ps1`.
- **Ramverkets `CLAUDE.md`, avsnitt 3.6:** ny regel om att Teamsytor inte synkas
  till en mapp där Claude arbetar, och att Claude stannar före läsning där.
- **Mallmappen sätts på ett ställe:** `EKAN_MALLAR` i `env` i
  `~/.claude/settings.json`, skriven av `ekan-setup.ps1 -Mallmapp`.
  `nytt-projekt.ps1`, `md_to_word.py` och projektdirektiv-skillen läser den och
  faller tillbaka på `~/consulting/templates`, som är standard.
- **`ekan-setup.ps1 -Kontroll`:** skrivskyddad slutkontroll med en rad per
  kontroll. Mallarna kontrolleras genom att filen öppnas, inte bara att den finns.
  En mall som inte lagts in än visas som SENARE och räknas inte som fel.
- **Setup tål en ogiltig `settings.json`:** filen lämnas orörd, resten installeras
  och konsulten får besked på svenska.
- **`CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`** skrivs i `env`, så att uppdateringar
  fungerar utan SSH-nyckel hos GitHub.
- **`nytt-projekt.ps1`** kopierar bara Office-filer ur mallmappen.
- **`session-start.ps1`** skapar `~/.claude` om mappen saknas, i stället för att
  skriva tre fel på stderr.
- **`config/permissions-template.json`:** de oanvända blocken `hooks` och
  `enabledPlugins` är borttagna. Setup läste dem aldrig.
- **README:** PowerShell 7 är inte längre en förutsättning. Hookarna har alltid
  körts i inbyggda Windows PowerShell 5.1.

## 3.13.0 — 2026-11-12

### För konsulten

- Webbsidor som Claude bygger i ett uppdrag hämtar inte längre typsnitt, skript eller bilder från internet. Tidigare kunde en sida ladda typsnitt från Google, och då fick Google mottagarens IP-adress varje gång sidan öppnades. En tysk domstol har bedömt det som ett brott mot GDPR.
- Sidorna använder i stället Ekans egna typsnitt, Calisto MT och Segoe UI, som redan finns på datorn.
- Regeln gäller även sidor som Claude publicerar på claude.ai.

### Ändrat

- **Ny regel i avsnitt 3.4 i Ekans CLAUDE.md:** HTML-filer i uppdrag hämtar
  ingenting från internet, inga typsnitt från Google Fonts, inga skript från
  CDN och inga externa bilder. Regeln går före Artifact-verktygets standard
  att ladda typsnitt från Google Fonts. Claude bäddar in bibliotek i filen
  och söker efter `https://` i `src`, `<link href>`, `url(` och `@import`
  före leverans.
- **`ramverk/visuell-profil.md`** anger typsnittsstackarna för HTML:
  `"Calisto MT", Georgia, serif` för rubriker och
  `"Segoe UI Semilight", "Segoe UI", sans-serif` för brödtext.

## 3.12.1 — 2026-11-05

### För konsulten

- Har du egna automatiska kommandon (hooks) i Claudes inställningar ligger de nu kvar när du kör setup. Tidigare togs de bort.
- Setup sparar din tidigare version av filer som den skriver över i consulting-mappen, och säger vilka det gäller.
- README beskriver vilka filer pluginet ändrar, för dig som redan har en egen konfiguration.

### Ändrat

- **Setup tar bara bort Ekans gamla hooks ur `settings.json`.** Tidigare
  försvann hela `hooks`-blocket, även konsultens egna hooks. Nu känner
  `Test-EkanLegacyHook` igen pluginets gamla skript i `~/.claude/hooks/` och
  påminnelsen efter komprimering. En grupp eller händelse som blir tom tas
  bort, och blocket försvinner först när inget är kvar.
- **Setup sparar `.bak` innan den skriver över** `~/consulting/CLAUDE.md`,
  filerna i `ramverk/` och hjälpskripten, på samma sätt som sessionsstarten.
  En fil med samma innehåll rörs inte, så en omkörning skriver ingen ny `.bak`.
  Setup listar sist de filer som fick en `.bak`.
- **README: "Har du redan en egen konfiguration?"** med vad setup och
  sessionsstarten skriver till.

## 3.12.0 — 2026-11-05

### För konsulten

- Ekans Office-mallar följer inte längre med pluginet. Hämta dem från Ekans SharePoint och lägg dem i mappen templates under consulting.
- Mallar du redan har ligger kvar. Setup säger till om någon av de mallar som projektdirektivet och Word-skriptet behöver saknas.
- Pluginet ligger nu i Ekans egen organisation på GitHub och kan installeras utan GitHub-konto.
- `/ekan:stop-slop` är borttagen. Skrivreglerna i Ekans CLAUDE.md gäller som förut.

### Ändrat

- **Pluginet flyttar till `ekan-management` och blir publikt.** Kunddata
  och Ekans eget material ska inte ligga i ett repo som vem som helst kan
  läsa. `/ekan:setup` registrerar `ekan-management/ekan-plugins` och byter
  en befintlig post som pekar på den gamla adressen. `LICENSE` anger att
  alla rättigheter förbehålls Ekan AB.
- **`/ekan:stop-slop` borttagen** med sin plats i permissions-mallen. De sex
  skrivreglerna i §2 täcker behovet.
- **`templates/` borttagen.** `/ekan:setup` kopierar inga mallar längre.
  Steget skapar `~/consulting/templates/` och listar de mallar som saknas av
  `Mall Projektdirektiv.docx`, `Mall Uppdragsdirektiv Små uppdrag.docx` och
  `Mall anteckningar.docx`. Befintliga mallar i mappen rörs inte.
- **`/ekan:projektdirektiv` läser mallarna från `~/consulting/templates/`**
  i stället för från pluginets mapp, och stannar om mallen saknas.
- **`docs/` borttagen.** Planerna var arbetsdokument från utvecklingen.
  Historiken står i den här filen.
- **Kundnamn och uppdragsdetaljer borttagna** ur exempel, tester, ordlistan
  i `check_diakriter.py` och tidigare poster i den här filen. Exemplen i
  `skrivstilar.md` bygger nu på Exempelstadens fiktiva HR-uppdrag från
  introt.
- **ROADMAP:** interna strategiavsnitt strukna.
- **AI-policyn i §3.6 och introt hänvisar inte längre till interna dokument.**
  Reglerna och stoppregeln är oförändrade. Dokumenttitlar, beslutsdatum,
  klassbeteckningar, roller och avtalsdetaljer är borttagna, och de
  ordagranna citaten är omskrivna.
- **`.gitignore`** stoppar Office-filer, `templates/` och `docs/`. Hänvisningen
  till en intern regelfil är borttagen där och i `fallgropar.md`.
- **`tests/e2e.ps1` läser sessionsstartens kontext ur `hookSpecificOutput`.**
  Två kontroller hade fallerat sedan 3.9.3, när fältet flyttade.

## 3.11.0 — 2026-10-20

### För konsulten

- Små uppdrag får nu uppdragsdirektivet på Ekans småuppdragsmall, med en enda avstämning innan utkastet skrivs.
- Säger du själv att uppdraget är litet eller kort, frågar Claude inte om storleken igen.
- Tidplanen i ett litet uppdrag skrivs som faser med datum, utan veckotabell.

### Ändrat

- **Projektdirektiv: litet uppdrag använder `Mall Uppdragsdirektiv
  Små uppdrag.docx`.** Skillen kände bara till `Mall Projektdirektiv.docx`
  och rensade den ner för små uppdrag, men kvar fanns styrgrupp,
  projektledning, projektgrupp och organisationstabell. Småmallen har rätt
  avsnitt och signeras av beställare och konsult. Medel och stort använder
  den stora mallen som tidigare. Filnamnet för litet uppdrag är
  `uppdragsdirektiv [Projektnamn] UTKAST.docx`, efter mallens namn på
  dokumentet.
- **En avstämning i stället för fyra för litet uppdrag.** Klassificering,
  mallval, planerat innehåll per avsnitt och öppna sakfrågor samlas i en
  fråga. Därefter skriver Claude utkastet och levererar det med
  valideringsflaggor och självgranskning. Medel och stort behåller
  avstämningen efter varje steg. Gränsfallsfrågan ställs bara när konsulten
  inte själv har angett storlek ("kort", "litet" eller högst 200 timmar).
- **Referensfilerna:** `klassificering.md` har mallval och avsnitt för
  småmallen, `skrivstilar.md` visar vilken definition varje avsnitt i
  småmallen följer, `kvalitetschecklista.md` har en litet-variant och
  `teknisk-implementation.md` beskriver småmallens fallgropar:
  instruktionsrader som inte börjar med `<`, numId som måste läsas innan
  exempelpunkterna raderas, bundna innehållskontroller i sidhuvud och på
  försättsblad, gulmarkerade datumfält, signaturtabellen och ort/datum.
  Mönstren är provkörda mot mallen.

## 3.10.2 — 2026-10-09

### För konsulten

- Claudes sökagent följer nu också regeln om känsliga personuppgifter. Tidigare kunde den öppna en fil med personnummer när den letade i en projektmapp.

### Ändrat

- **3.7: stoppregeln följer med till Explore och Plan.** De inbyggda
  agenterna läser inga CLAUDE.md-filer. I ett test med en påhittad
  personallista (personnummer och sjukfrånvaro) vägrade vanliga subagenter
  i 4 av 4 körningar. Explore utan regeln körde `cut` på filen och tog ut
  namn, enhet och e-post i 2 av 3 körningar. Personnummer nådde inte
  kontexten, men filen öppnades, vilket 3.6 förbjuder. Huvudsessionen skriver
  nu in stoppregeln i uppdraget när Explore eller Plan söker i en
  projektmapp, eller använder en vanlig subagent. En hård spärr via hook
  prövas först om behovet visar sig.

## 3.10.1 — 2026-10-09

### För konsulten

- Listan över vad som är nytt visas i alla nya sessioner under ett dygn efter en uppdatering. Tidigare kunde den försvinna om appen öppnade en äldre session i bakgrunden.

### Rättat

- **Uppdateringsnotisen förbrukades av fel session.** Hooken markerade
  versionen som sedd i första sessionsstarten, oavsett vilken. Den 9 okt
  2026 återupptog appen en vilande session två minuter efter releasen av
  3.10.0; notisen hamnade där, och konsultens nästa nya session fick ingen.
  Nu sparas notisen i `~/.claude/.ekan-update-notice.json` med
  upptäcktstid och visas i varje ny session (`startup`, `clear`) under 24
  timmar, så länge den gäller den installerade versionen. Hooken läser
  `source` ur Claude Codes indata på stdin: en återupptagen session
  (`resume`) varken upptäcker en ny version eller visar notisen, och
  komprimering (`compact`) visar den inte mitt i arbetet. Saknas indata
  räknas starten som ny session.
- **Sju nya test** i `tests/uppdateringsnotis.Tests.ps1` för notisens
  livslängd, återupptagna sessioner, komprimering, `/clear` och en trasig
  notisfil.

## 3.10.0 — 2026-10-09

### För konsulten

- Efter en uppdatering berättar Claude vad som är nytt i pluginet, i en kort lista som den här. Nya skills kommer med automatiskt.
- Ekans instruktioner till Claude är genomgångna för Opus 5.5 och en fjärdedel kortare. Färgprofilen och reglerna för projektets CLAUDE.md ligger i egna filer som Claude läser när uppgiften kräver det.
- Skrivreglerna är nu sex korta regler på svenska i stället för den engelska stop-slop-checklistan. `/ekan:stop-slop` finns kvar när du vill ha en grundlig granskning.
- Claude frågar vilken version av ett dokument du menar bara när det finns flera.
- Claude har fått riktlinjer för att välja en snabbare och billigare modell till hjälpagenter som söker och sammanställer, och spara den starkaste till analys och slutsatser.
- Efter att ett långt samtal komprimerats fortsätter Claude med uppgiften i stället för att visa projektöversikten.

### Ändrat

- **Ramverket genomgånget för Opus 5.5.** Underlag: Anthropics
  prompting-guide för 5.5 (modellerna följer instruktioner exakt, och
  namngivna mönster styr bättre än "undvik AI-stil") och Claude Codes
  dokumentation om CLAUDE.md (under 200 rader per fil). Det modellen läser
  gick från 266 till 214 rader och från 18 600 till 13 600 tecken. HTML-kommentarerna med
  regeltyper räknas inte, eftersom Claude Code tar bort dem före inläsning.
- **3.4 och 3.5 flyttade till `consulting/ramverk/`.** `visuell-profil.md`
  och `projekt-claude-md.md` synkas till `~/consulting/ramverk/` av
  `session-start.ps1` och installeras av `/ekan:setup`. Till skillnad från
  `scripts/` speglas mappen: en fil som tagits bort ur pluginet tas bort
  hos konsulten, så att ingen föråldrad regel ligger kvar. Pekarna anger
  `~/consulting/ramverk/` så att de fungerar när sessionen startar i en
  projektmapp. Avsnitten i
  `CLAUDE.md` står kvar med en sammanfattning och en pekare, så att
  hänvisningar till 3.4 och 3.5 från skills och hookar fortsätter gälla.
  Flaggan för en för lång projekt-CLAUDE.md sänkt från 500 till 200 rader.
- **§2 skrivregler.** Kravet att köra stop-slop-skillen på all text, och
  att klistra in den i subagenters uppdrag, ersatt av sex namngivna mönster
  på svenska. Skillen är engelsk och har regler som inte går att översätta,
  som meningar som börjar med Wh-ord. Skillen har fått
  `disable-model-invocation: true`, annars hade dess beskrivning fortsatt
  att trigga den vid all skrivning. Den körs nu bara som `/ekan:stop-slop`.
- **3.2 villkor.** "Bekräfta versionen" gäller när flera versioner finns och
  konsulten inte pekat ut en. "Källseparation" frågar bara när det är oklart.
  5.5 följer instruktioner exakt, så en regel utan villkor ger en fråga
  varje gång. Inte prövat i test.
- **Tvålagerarbetssättet** definierat i §3. Den gamla 3.5 hänvisade till
  det, men det fanns bara i en konsults MY-CLAUDE.md. Regeln om kryssrutor
  för to-do (som `/ekan:jobb` kräver) flyttad samma väg till
  `ramverk/projekt-claude-md.md`.
- **Ny 3.7 Subagenter och modellval.** Haiku för sökning och extraktion,
  Sonnet för utkast och granskning, huvudmodellen för analys. Agent-verktygets
  `model` styr per anrop. Uppgiften att subagenter inte läser CLAUDE.md var
  fel och är struken: bara Explore och Plan saknar filerna, som
  intro-skillen redan säger.
- **§5 kortad.** Namnrymd, personliga skills och samverkande plugins
  flyttade till README. §8 Roadmap struken; `ROADMAP.md` nämns i §5.
- **Versaler som ALLTID, INTE och ENBART** nedtonade. Anthropic dokumenterar
  överreaktion på sådan betoning för tidigare Opus-versioner.
- **`compact-reminder.ps1`** bad Claude visa projektöversikten som första
  meddelande efter komprimering, vilket avbröt pågående arbete. Påminnelsen
  ber nu Claude läsa om källfilen innan siffror, namn eller citat ur
  sammanfattningen återges.
- **MY-CLAUDE.md-mallen** lovade att ramverket hanterar "thinking, high
  effort". Det avsnittet finns inte längre. Listan följer nu ramverket, och
  mallen säger att modell, effort och advisor är inställningar.

### Rättat

- **`tests/version.Tests.ps1`** läste CHANGELOG utan `-Encoding UTF8` och
  fallerade under Windows PowerShell 5.1, som hookarna körs med.
- **`tests/smoke.ps1`** letade efter `additionalContext` på toppnivå och
  fallerade sedan 3.9.3. Läser nu `hookSpecificOutput.additionalContext`.

### Lagt till

- **Uppdateringsnotisen säger vad som är nytt.** `session-start.ps1` hämtar
  punkterna under `### För konsulten` för varje version mellan konsultens
  förra och nya version, nyaste först och högst tio. Claude ombeds visa
  listan ordagrant i första svaret. Tidigare stod det bara att pluginet
  uppdaterats, och changelogens rubriker var för tekniska för konsulterna.
- **Nya skills och kommandon nämns automatiskt.** Hooken sparar
  pluginets skills och kommandon i `~/.claude/.ekan-last-skills` och
  jämför vid nästa uppdatering. Saknas filen jämförs med förra versionens
  mapp i plugincachen. Skills som en klarspråkspunkt redan nämner hoppas
  över.
- **Klarspråksrader för 3.8.0–3.9.3**, så att konsulter som hoppar flera
  versioner får hela listan.
- **`tests/uppdateringsnotis.Tests.ps1`** och ett test i
  `tests/version.Tests.ps1` som stoppar en release utan `### För konsulten`.

## 3.9.3 — 2026-10-09

### För konsulten

- Claude får nu besked när pluginet har uppdaterats och kan berätta det för dig. Tidigare försvann beskedet på vägen.

### Rättat

- **Sessionsstartens kontext nådde aldrig Claude.** `session-start.ps1` och
  `compact-reminder.ps1` skrev `additionalContext` på toppnivå i sin JSON.
  Claude Code läser fältet bara inuti `hookSpecificOutput` och kastade det
  utan felmeddelande. Sessionsloggen visade hooken som lyckad med tomt
  innehåll. Ekan-banern, projektlistan, uppdateringsnotisen och påminnelsen
  efter komprimering kom därför aldrig fram till modellen, varken i
  terminalen eller i desktop-appen. Båda hookarna skriver nu
  `hookSpecificOutput` med `hookEventName: "SessionStart"`. `systemMessage`
  ligger kvar på toppnivå, där Claude Code läser det. Nya tester i
  `tests/session-start.Tests.ps1` fäller toppnivåformatet.

## 3.9.2 — 2026-10-08

### För konsulten

- `/ekan:jobb` kunde sluta fungera på grund av å, ä och ö. Det är rättat.

### Rättat

- **`hooks/jobb.ps1` saknade UTF-8 BOM.** Windows PowerShell 5.1 läser då
  filen som Windows-1252, och å, ä och ö i skriptet kan bryta parsningen när
  `/ekan:jobb` körs. Filen har fått BOM utan andra ändringar, och
  `tests/encoding.Tests.ps1` passerar igen på master.

## 3.9.1 — 2026-10-08

### För konsulten

- Regeln om PowerPoint är mjukare. Claude får bygga nya presentationer ovanpå Ekans mall, men får fortfarande inte bygga från tomt eller skriva om befintliga presentationer.

### Ändrat

- **§4.3 Verktygsval för PowerPoint är nyanserat.** Det generella förbudet
  mot python-pptx gäller nu två fall: att bygga från noll och att skriva om
  befintliga presentationer. Nya presentationer byggs med
  `ekan-powerpoint`-skillen eller PowerPoint-pluginet, ovanpå en kopia av
  `Ekan mall - 2026-06-09.potx` och mallens egna layouter. Underlag: en
  presentation på 23 bilder byggd så den 8 oktober höll när den öppnades i
  PowerPoint. Det löser den motsägelse mellan regeln och skillen som
  omfångsdesignen från 18 september lämnade öppen.

## 3.9.0 — 2026-10-08

### För konsulten

- Ny regel om känslig information: Claude stannar innan den öppnar filer som verkar innehålla personnummer eller hemlig information.
- `/ekan:intro` är omskriven och har fått en valfri fördjupningsdel med elva moduler.

### Lagt till

- **§3.6 Datahantering enligt Ekans AI-policy i `consulting/CLAUDE.md`.**
  Säkerhetsnivåerna och reglerna ur Ekans interna AI-anvisning, och en
  ansvarsfördelning. Konsulten ansvarar för att information med hög
  säkerhetsnivå och känsliga personuppgifter inte läggs i projektmappen.
  Claude stannar som reserv före läsning av filer som tyder på sådant
  innehåll, även när konsulten ber om det. Utan regeln öppnade Opus en
  kontaktlista med personnummer på direkt begäran i två av två försök. Med
  regeln vägrade Opus i fyra av fyra, varav ett under påtryckning, och läste
  en ofarlig kontaktlista som vanligt.
- **`/ekan:intro` del 2, `references/fordjupning.md`.** Elva valfria moduler,
  med subagenter med olika perspektiv först. Övrigt: agentbegrepp, Plan-läget,
  skills, verifieringsknep, styrkor och svagheter, Office-filer, OneDrive,
  sessionsrutiner, kostnad och gömda instruktioner i dokument.

### Ändrat

- **`/ekan:intro` del 1 är omskriven** kring det en konsult måste kunna före
  första uppdraget: behörighetslägen och skyddsnät, datahantering, ansvar och
  avvikelser, vad som styr Claude och var sessionen startas, kontext och
  cache, fel med säker ton, scope. Fakta om Claude Code är kontrollerade mot
  dokumentationen 2026-10-08, bland annat att terminalen startar i Auto och
  att cachen lever en timme för huvudsessionen.
- **Övningsutlysningen har tre fällor:** motsägelse i antalet intervjuer,
  ett lockbete utanför uppdraget och en bilaga med personnummer och
  sjukskrivningar.

### Borttaget

- **Blocket om planerade Ekan-agenter** (`@agentnamn`). De finns inte, och
  blocket blandades ihop med subagenter.
- **`/cost`** i kommandotabellen, ersatt av `/usage`.

### Rättat

- Intron hänvisade till fel block för MY-CLAUDE.md och länkade till repots
  gamla namn `ekan-claude-setup`.

## 3.8.1 — 2026-09-24

### För konsulten

- `/ekan:jobb` tappade uppgifter som låg under en underrubrik i projektets to-do-lista. Nu kommer de med.

### Rättat

- **`/ekan:jobb` tappade öppna punkter under underrubriker.** Varje ny rubrik
  avslutade öppet-avsnittet oavsett nivå, så `### Frågor som väntar på svar`
  under `## Öppet` gjorde att inga punkter kom med. Projekt utan kryssrutor
  försvann helt ur översikten. Nu avslutas avsnittet först vid en
  rubrik på samma eller högre nivå, eller vid en egen avslutsrubrik (`Avgjort`,
  `Löst`, `Klart` m.fl.) — annars svepte redan lösta underavsnitt in som öppna
  uppgifter. Nya tester i `tests/jobb.Tests.ps1`.

## 3.8.0 — 2026-09-23

### För konsulten

- Varje regel i Ekans instruktioner till Claude är märkt med varför den finns. Då kan regler som nya Claude-versioner inte behöver strykas.

### Lagt till

- **Regeltyper i `consulting/CLAUDE.md`.** Varje regel har fått en
  HTML-kommentar som anger varför den finns. Typ 1 motverkar Claude Codes
  kodningsinriktning och gäller så länge verktyget är byggt för kod. Typ 2
  kompenserar modellens svagheter och åldras. Typ 3 är Ekan-fakta och
  metodik. En förklaring överst beskriver hur genomgången görs vid varje
  Opus-släpp: ta bort en typ 2-regel, kör två eller tre standarduppgifter i
  Opus och stryk regeln om utfallet blir detsamma. Opus är huvudmodellen, så
  att Fable klarar något utan regeln räcker inte.

### Ändrat

- **Inledningen beskriver synken som den fungerar.** Hooken jämför hash vid
  varje sessionsstart, så en lokal ändring skrivs över även utan
  pluginuppdatering. Tidigare stod det att synken sker efter en uppdatering.

### Borttaget

- **§4.1 Office**, som bara räknade upp Word, PowerPoint och Excel. §4.2–4.5
  heter nu 4.1–4.4.

## 3.7.1 — 2026-09-23

### Rättat

- **`autoUpdate` från 3.7.0 räckte inte när Claude Codes egen uppdatering är
  avstängd.** Med `"autoUpdates": false` i `~/.claude.json`, vanligt vid
  installation via npm, uppdateras inte plugins heller. Setup sätter därför
  också `FORCE_AUTOUPDATE_PLUGINS=1` under `env` i `~/.claude/settings.json`.
  Variabeln släpper igenom pluginuppdateringar utan att slå på uppdateringen
  av själva Claude Code. Befintliga `env`-variabler bevaras.

  Prövat på riktig installation 2026-09-23: med bara `autoUpdate` hämtades
  ingenting på 12 minuter. Med variabeln kom 3.7.0 in i cachen efter 7 minuter.

- **Setup läser `settings.json` och permissions-mallen som UTF-8.** Utan
  `-Encoding UTF8` antar Windows PowerShell 5.1 ANSI, och å, ä och ö i
  konsultens `settings.json` skrevs tillbaka förvanskade (`behåll` blev
  `behÃ¥ll`). Under `pwsh` märktes felet inte. Testet faller när fixen tas bort.

## 3.7.0 — 2026-09-23

### Lagt till

- **`/ekan:setup` slår på automatisk uppdatering av marknadsplatsen.** Setup
  skriver `extraKnownMarketplaces.ekan-plugins` med `autoUpdate: true` i
  `~/.claude/settings.json`. Finns posten redan sätts bara flaggan, och andra
  marknadsplatser lämnas orörda. Marknadsplatser från tredje part uppdateras
  inte automatiskt som standard, så en konsult som installerat via
  `/plugin marketplace add` låg kvar på sin första version, och update-pingen
  hade aldrig något att visa.

  Dokumentationen beskriver fältet bara för managed settings. Mekanismen i en
  vanlig `settings.json` är därför prövad på en riktig installation
  2026-09-23. Med `autoUpdate: false` i `known_marketplaces.json` och `true` i
  `settings.json` skrev en ny Claude Code-start om flaggan till `true`. Utan
  omstart låg `false` kvar, och med `false` i båda filerna förblev den `false`.
  Det är alltså `settings.json` som styr, och den läses vid start.

  ⚠️ Uppdateringen hämtas 0–10 minuter efter sessionsstart, och SessionStart-
  hooken kör med den version som laddades vid start. Pingen
  `Ekan-plugin uppdaterad` syns därför först i sessionen efter den där
  uppdateringen hämtades. `/reload-plugins` aktiverar den nya versionen
  direkt men visar ingen ping.

## 3.6.0 — 2026-09-18

### Lagt till

- **Avsnitt 3.5 i `consulting/CLAUDE.md`: vad som hör i en projekt-CLAUDE.md.**
  Fyra regler, var och en med sitt skäl. Historik flyttas till
  `CLAUDE-historik.md` när en punkt blir avklarad, en fas avslutas eller ett
  beslut ersätts. Referensmaterial ligger under `underlag/` och pekas ut från
  `## Källdokument`. Byggloggen versioneras, så att specifikationen inte blir
  en kedja av deltan. Beräknade utdata skrivs inte i filen alls.

  Bakgrunden är en granskning hos en konsult: två projektfiler hade vuxit till
  174 kB och 127 kB, alltså ungefär 43 000 och 32 000 tokens som lästes in vid
  varje sessionsstart i månader. Tokenkostnaden är det minsta av det. Filerna
  bar motsägelser som ingenting markerade — samma flik beskrevs med fem
  rutnät på en rad och femton på en annan, och samma nyckeltal fanns i fem
  versioner varav fyra hade en varning om att de inte skulle användas. Allt i
  filen anländer som instruktion utan tidsstämpel, så en föråldrad rad är
  dyrare än en saknad: den får Claude att agera med självförtroende och fel.

  500 rader är en flagga, inte ett tak. Bindande beslut som Claude måste läsa
  hör kvar i filen även när den blir lång.

- **Nio Pester-tester för ramverkssynken** i `tests/session-start.Tests.ps1`:
  att scripten kopieras, att `.bak` tas vid överskrivning, att konsultens egna
  script i samma mapp aldrig rörs, att ingen scriptmapp skapas när
  `~/consulting` saknas, och att JSON-outputen står även när flera filer
  synkas.

### Ändrat

- **`session-start.ps1` synkar en manifestlista, inte bara CLAUDE.md.**
  Standardens §2.1 är en hård regel som slutar med
  `python scripts/check_diakriter.py`, men scripten installerades bara av
  `/ekan:setup`, som körs en gång. När scriptet bytte namn från
  `check_swedish_chars.py` stod regeln kvar hos konsulten och pekade på en fil
  som inte fanns; `read_office.py` saknades helt hos den som installerat före
  3.1. Dokumentationen låg i takt med pluginet medan verktygen den hänvisar
  till låg tre versioner bak.

  Synken bär nu `consulting/CLAUDE.md`, `ROADMAP.md` och varje `.py` i
  pluginets `scripts/`, med samma hashjämförelse och `.bak` som tidigare.
  Inget raderas: konsultens egna filer i `~/consulting/scripts/` rörs aldrig,
  och ingen mapp skapas om `~/consulting` saknas. `/ekan:setup` fungerar
  oförändrat för en ny install.

  `ROADMAP.md` följer med av samma skäl: den refereras sex gånger i standarden
  med relativ sökväg från `~/consulting/` och installerades aldrig dit.

- **Projektmallen i `nytt-projekt.ps1` slutar föda tomma sektioner.**
  `## Mistakes to Avoid` med sin tomma tabell och `## Workflow-påminnelser`
  med sitt enda innehåll "Se `~/consulting/CLAUDE.md` för fullständiga
  riktlinjer" är borta. Standarden är auto-laddad i varje session under
  `~/consulting/`, så pekaren bad Claude läsa något den redan läst. Av tio
  granskade projektfiler hade fyra en tom mistakes-tabell. Två hade riktiga
  lärdomar, och de hör i en sektion som fylls när något går fel, inte i en
  tabell som föds tom. I stället får mallen ett kort `## Omfång` som pekar på
  regeln i 3.5, så att nya projekt känner mönstret från dag ett.

- **Rättade påståenden i `consulting/CLAUDE.md`** som inte stämde mot
  verkligheten hos konsulten: scope-tabellens `memory/*.md` pekade på en
  katalog som inte finns och anger nu den faktiska sökvägen per workspace;
  konfliktregeln hänvisade till säkerhetshooks som inte finns; §4.4 påstod att
  ingen API-integration mot Claude Code finns; och slutrapport, konsultcv och
  mötesanteckningar beskrevs som planerade fast de finns byggda som
  `personal-*`.

### Öppet inför nästa release

- **PowerPoint-regeln i §4.4 motsäger skillen `ekan-powerpoint`.** Standarden
  förbjuder python-pptx mot Ekan-mallarna; skillen bygger Ekan-presentationer
  med python-pptx och dokumenterar verifierade lösningar på renderingsproblem
  i mallen. Den här releasen stryker bara det påstående som säkert är falskt
  och lämnar förbudet orört. Vilket av de två som gäller är repo-ansvarigs
  beslut.

## 3.5.0 — 2026-09-17

### Lagt till

- **Statusfärger som egen tabell i 3.4** — djupgrön `#033F47` för OK, amber
  `#FBAE40` för varning och vinröd `#8B2E2E` för kritiskt, märkta som
  funktionella och inte varumärke. Vinröd behålls därmed från den gamla
  paletten, så villkorsformat i befintliga Excel-modeller fungerar som de är.
  Tabellen gäller bara där färgen bär ett tillstånd.

  Avsnittet säger också att färgen aldrig står ensam: en röd cell eller en
  statusprick får ett ord vid sidan, så att gråskala och skärmläsare ger samma
  besked.

### Ändrat

- **Visuell profil bytt till mallen `Ekan mall - 2026-06-09.potx`** — avsnitt
  3.4 i `consulting/CLAUDE.md` bär nu mallens sex kulörer i stället för den
  gamla sjufärgspaletten. Djupgrön `#033F47` ersätter `#2B5F5F`, sand
  `#D7D1C3` och gräddvit `#FFF8F2` delar upp det som var beige `#E8DCC8`, och
  brödtexten flyttar från `#4A4A4A` till `#353535`. Amber `#FBAE40` och
  mörkblå `#233348` är nya.

  Fyra färger utgår utan efterträdare: mint `#C5DDD8`, ljusblå `#A8CEDB`, rosa
  `#E8C5C5` och vinröd `#8B2E2E`. Mallen har ingen röd färg, så amber bär
  markering och avvikelse, och kritiskt läge sätts med djupgrön fyllning och
  gräddvit text. Villkorsformat i befintliga Excel-modeller med röd-grön-logik
  behöver därför ses över när de återanvänds.

  Avsnittet namnändras från *Visuell profil — färgkoder* till *Visuell profil*
  och får två tillägg: typsnitten (Calisto MT för rubriker, Segoe UI Semilight
  för brödtext) och en varning om att PowerPoint-temats färgschema deklarerar
  andra accenter än layouterna använder. Temats accent 1 är `#0F3D3E` och
  accent 3 `#EA723D`, så ett diagram som behåller automatfärgerna hamnar
  utanför paletten.

  Varje värde är läst ur mallens `theme1.xml`, `slideMaster1.xml` och
  `slideLayouts/`, inte uppskattat.

## 3.4.0 — 2026-09-17

### Ändrat

- **`Bash(rm *)` och `Bash(rmdir *)` ersatta av smalare regler** i
  `config/permissions-template.json`. Den breda regeln stoppade all radering,
  även en enstaka backupfil konsulten själv bett om att få bort, och gav en
  prompt i varje sådant läge. Den blockerade också kommandokedjor där `rm`
  bara var sista ledet.

  Deny träffar nu de rekursiva formerna: `rm -r`, `rm -R`, `rm -rf`, `rm -fr`,
  `rm -Rf`, `rm -r -f`, `rm -f -r` och `rmdir /s`. Enstaka filer raderas utan
  prompt.

  ⚠️ Detta är friktionsskydd, inte en spärr. `Remove-Item -Recurse -Force`
  går förbi listan eftersom `Bash(powershell *)` ligger i allow, och en
  rekursiv radering kan skrivas om till en form som inte matchar. Skyddet mot
  destruktiva kommandon vilar på att modellen frågar före radering, inte på
  regellistan.

- **Borttagna regler städas inte hos konsulten.** `Merge-Permissions` i
  `hooks/ekan-setup.ps1` gör union av allow och deny, så `Bash(rm *)` ligger
  kvar i `~/.claude/settings.json` hos alla som kört setup före 3.4.0. Den
  måste tas bort manuellt — mallen ensam räcker inte. Gäller varje regel som
  någonsin distribuerats.

## 3.3.0 — 2026-09-08

### Lagt till

- **`systemMessage` i `session-start.ps1`** — uppdateringsnotisen och
  synknotisen renderas nu på konsultens skärm vid sessionsstart. Tidigare låg
  båda bara i `additionalContext`, som går till modellen och inte till
  terminalen. Notisen bar dessutom instruktionen *"Nämn detta kort för
  användaren"*, så den nådde fram först när konsulten skickat sin första prompt.
  En session som bara öppnades missade den helt, och eftersom
  `~/.claude/.ekan-last-version` redan skrivits om jämförde nästa sessionsstart
  lika och teg. Notisen gick alltså förlorad utan spår.

  Hooken lägger nu båda fälten i samma JSON-objekt: `additionalContext` till
  modellen, `systemMessage` till skärmen. Kravet att allt på stdout ska vara ETT
  objekt gäller fortfarande, och det är därför fälten samsas i stället för att
  notisen skrivs med `Write-Host`.

  Ekan-banern och projektlistan stannar i `additionalContext`. De är kontext för
  modellen och hör inte på skärmen varje session.

- **Fyra tester i `tests/session-start.Tests.ps1`** — synknotis och
  uppdateringsnotis i `systemMessage`, banern och projektlistan utanför det, och
  fältet helt utelämnat när varken synk eller uppdatering skett. De två första
  faller utan ändringen, verifierat. De två sista passerar även utan den och
  fångar alltså bara en framtida regression, inte frånvaron av funktionen.

## 3.2.0 — 2026-09-08

### Borttaget

- **Regel 6.2 `<thinking>`-taggar** — instruktionen bad modellen tänka i
  `<thinking>`-taggar före riskanalyser, granskningar och öppna frågor.
  Anthropics promptguide för Opus 5 säger att regler som namnger tanketaggar
  ökar risken att taggarna läcker ut i det synliga svaret, och att instruktioner
  om att inte tänka har samma effekt. Opus 5 tänker dessutom som standard, så
  regeln köpte ingen kvalitet — den skapade bara en felkälla.
- **Regel 6.3 När föreslå high effort** — beskrev ett manuellt flöde där Claude
  erbjöd sig att skriva om `effortLevel` i `~/.claude/settings.json` till
  `"high"` och sedan tillbaka till `"medium"` efter uppgiften. Flödet förutsatte
  en modellgeneration där `high` var undantaget. På Opus 5 är `high` utgångsläget
  och effort styr hur mycket modellen *tänker*, inte hur mycket den *säger*, så
  förslaget kunde inte leverera vad rubriken antydde. Samma guide avråder av
  samma skäl från explicita verifieringsinstruktioner: de adderar tokens utan
  kvalitetsvinst.

Källa: [Prompting Claude Opus
5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5),
avsnitten *Running with thinking disabled*, *Response length and verbosity* och
*Task scope and over-verification*.

### Ändrat

- **6.4 Projektavslut heter nu 6.2.**

## 3.1.0 — 2026-08-13

### Lagt till

- **`scripts/check_diakriter.py`** — larmar när å/ä/ö transliererats till a/o i
  genererade Office-filer (`Dagar per manad`, `Sjalvkostnad`, `Orebro`). Felet
  uppstår när text författas ASCII-fierad i script som genererar filen, inte i
  teckenkodningen — kodassistenter bär en instruktion avsedd för källkod
  (*"default to ASCII when editing or creating files"*) och övergeneraliserar den
  till innehållet. Rapporterat för tyska, turkiska och ett dussin andra språk
  (claude-code#14131, #12417); går inte att konfigurera bort, därav kontrollen.
- **Regel 2.1 i ramverkets CLAUDE.md** — å/ä/ö skrivs alltid ut, med hänvisning
  till kontrollen efter programmatisk filgenerering.

### Fixat

- **`scripts/` distribuerades aldrig** — ramverkets CLAUDE.md hänvisar till
  `scripts/read_office.py` och `scripts/md_to_word.py` med sökväg relativt
  `~/consulting/`, men ingen installationsväg har någonsin kopierat dem dit.
  Inte heller den borttagna `setup.ps1`. Skripten fanns bara hos konsulter som
  klonat repot manuellt; nya konsulter fick instruktioner som pekade i tomma
  luften. Ny `Install-Scripts` i `ekan-setup.ps1`, verifierad i `e2e.ps1`.

### Noterat om detektionen

Kontrollen använder ingen handskriven lista över felstavningar, utan
hunspell-ordlistan `sv_SE` (LibreOffice installerar den; hunspell-paketen på
macOS/Linux likaså). Ett ord flaggas när en form med å/ä/ö insatt står i
ordlistan.

Ordnivån ensam duger inte: svenskan är full av minimala par — `for`/`för`,
`har`/`här`, och `manad` är ett riktigt ord (perfekt particip av *mana*). Mätt
mot 380 verkliga projektfiler gav ordnivålarm 712 träffar, i princip alla
felaktiga. Den bärande signalen är i stället filnivån: en svensk text där många
ord kunde burit diakrit men **inget tecken** gör det är transliererad. Efter
omläggningen: 380 filer granskade, 1 fynd — äkta.

## 3.0.0 — 2026-08-13

### Fixat

- **`/ekan:setup` raderade utan bekräftelse** — `Read-Host` returnerar en tom
  kollektion när konsol-stdin saknas, och `@() -notmatch '...'` är en
  filteroperation som ger tom kollektion (falsy). Avbryt-grenen hoppades därför
  över och legacy-artifakterna raderades okonfirmerat. Eftersom
  `commands/setup.md` föreskriver körning via Bash-verktyget var det
  normalfallet, inte ett undantag. Villkoret citerar nu svaret (`"$answer"`), och
  en ny `-Yes`-flagga låter Claude bekräfta i chatten i stället — `setup.md`
  beskriver det flödet.
- **Legacy-städningen missade tre artifakter** — `$legacySkills` saknade
  `nytt-projekt` (skill sedan 2.3.0) och den ursprungliga mappen `stop slop`
  med mellanslag; `$legacyCommands` saknade `setup.md`; `$legacyHooks` saknade
  `compact-reminder.ps1` och `ekan-setup.ps1`. Den kvarlämnade
  `~/.claude/skills/nytt-projekt/` var värst: en personlig skill med bred
  autotrigger som konkurrerade med pluginets, och som pekade på en hook samma
  setup-körning just raderat. Listorna täcker nu allt som någonsin shippats.
- **`/ekan:jobb` och `nytt-projekt` gav mojibake** — båda hookarna saknade
  `[Console]::OutputEncoding`, så Windows PowerShell 5.1 skrev i konsolens
  kodsida (CP850) och projektnamn med å/ä/ö förvanskades.
- **Smoketestet körde alltid PowerShell 7** — `smoke.ps1` hårdkodade `pwsh` för
  setup-steget, så en körning under 5.1 testade ändå 7. Använder nu samma värd
  som testet startats i, och kontrollerar dessutom att mallarna installerats.

### Fixat (kodning)

- **Tre skript kraschade under Windows PowerShell 5.1** — `.ps1`-filer utan
  UTF-8 BOM tolkas av 5.1 som Windows-1252. Svenska tecken lästes då som fel
  byte-par, och när ett av dem råkade bli ett citattecken bröts parsningen:
  `hooks/nytt-projekt.ps1` gav 68 parse-fel, `hooks/ekan-setup.ps1` 6 och
  `tests/session-start.Tests.ps1` 1. Felen var osynliga eftersom skills startar
  skripten med `pwsh` (PowerShell 7), som antar UTF-8 — men `hooks.json` startar
  hookar med `powershell`, så `pwsh` hade blivit ett dolt installationskrav.
  Samtliga `.ps1` har nu BOM. Pester-sviten går igenom i båda värdarna (42/42);
  tidigare kunde den bara köras under `pwsh`.
- **Ny testsvit `tests/encoding.Tests.ps1`** — verifierar att varje `.ps1` har
  BOM och parsar utan fel i den aktuella värden, så regressionen inte kan
  återkomma tyst.

### Borttaget (brytande)

- **Hybrid-installationsvägen är avvecklad** — `setup.ps1`, `update.ps1` och
  `lib/install-lib.ps1` borttagna. Vägen infördes i 2.0.0 för Desktop- och
  IDE-användare som antogs sakna plugin-stöd, men antagandet stämmer inte:
  desktop-appen har en plugin-hanterare under `+` → Plugins, VS Code-extensionen
  under `/plugins`, och JetBrains når `/plugin` via IDE-terminalen. Fallbacken
  löste alltså inget problem, men kostade underhåll i varje release.
  **Migrering:** har du installerat via `git clone` + `.\setup.ps1`, installera
  om via `/plugin marketplace add DaVincisfather/ekan-plugins` +
  `/plugin install ekan@ekan-plugins` och kör `/ekan:setup`. Setup städar de
  gamla artifakterna i `~/.claude/` åt dig. `~/consulting/` rörs inte.
- **`tests/install-lib.Tests.ps1`** — testade enbart den borttagna modulen.

### Ändrat

- **`hybrid/settings-template.json` → `config/permissions-template.json`** —
  filen var aldrig hybrid-specifik: den är källan för permissions-mergen i
  `/ekan:setup` och används av plugin-vägen. Namn och placering speglar nu det.
- **Mallinstallationen flyttad till `/ekan:setup`** — `setup.ps1` steg 6/8 var
  den enda vägen som fyllde `~/consulting/templates/`, och den försvann med
  hybrid. Utan mallar varnar `nytt-projekt.ps1` och projektets "80 Mallar
  kompassen" blir tom. Ny `Install-Templates` i `ekan-setup.ps1` täcker det, och
  smoketestet verifierar antalet installerade mallar.
- **Ny testsvit `tests/version.Tests.ps1`** — låser att `VERSION`,
  `plugin.json`-versionen och CHANGELOG-posten hänger ihop. Divergerar de tystnar
  antingen update-pingen eller själva uppdateringen.
- **Cross-platform-punkten i ROADMAP omformulerad** — distributionen är
  plattformsoberoende sedan hybrid-skripten försvann. Kvarvarande Windows-
  beroende är hookarna (PowerShell); nästa steg är att välja mellan `pwsh` som
  förutsättning eller portning till `sh` — inte att skriva ett `setup.sh`.
- **`Remove-ObsoleteCommands` bortfaller med `lib/install-lib.ps1`** —
  legacy-städningen av oprefixade kommandon fanns redan självständigt i
  `ekan-setup.ps1` (`$legacyCommands`), som plugin-vägen använder.

## 2.5.0 — 2026-06-09

### Lagt till

- **CLAUDE.md-autosynk vid sessionsstart** — `hooks/session-start.ps1` jämför
  hash på pluginets `consulting/CLAUDE.md` mot `~/consulting/CLAUDE.md` och
  synkar vid skillnad (gamla filen sparas som `CLAUDE.md.bak`). Det manuella
  "kör `/ekan:setup` efter `/plugin update`"-steget behövs inte längre.
  Synken hoppar över om `~/consulting/` saknas (setup aldrig körd) och är
  no-op i hybrid-läge (där äger `update.ps1` synken). Ny Pester-svit:
  `tests/session-start.Tests.ps1` (9 fall, isolerad HOME/plugin-root).

### Ändrat

- **README dokumenterar auto-update** — tredjeparts-marketplaces har
  auto-update avstängt som standard; instruktion för att aktivera det för
  `ekan-plugins` tillagd under Uppdateringar. MY-CLAUDE.md rörs aldrig av
  synken.

### Fixat

- **Update-pingen korrumperade hookens JSON** — `Write-Host`-raden från 2.2.1
  hamnade på stdout före JSON-objektet, så SessionStart-outputen blev oparsbar
  exakt den session då pluginet just uppdaterats. Notisen levereras nu via
  `additionalContext` i stället.
- **Smoke-testets hook-check muterade riktiga `~/.claude`** — den körde
  hookarna med utvecklarens riktiga `USERPROFILE` och skrev över
  `.ekan-last-version` (gav även flaky FAIL vid versionsskillnad — sågs som
  "transient" i PR #11). Hook-checken kör nu mot isolerad temp-HOME.

## 2.4.0 — 2026-06-09

### Ändrat

- **`projektdirektiv`-skillen triggas nu på situationen** — beskrivningen
  omskriven från frasigenkänning ("användaren säger 'projektdirektiv'...")
  till situationstrigger: källmaterial finns i projektmappen och direktiv
  saknas. De manuella fraserna kvarstår som sekundära signaler.
- **Skill-permissions i hybrid-mallen** — `Skill(nytt-projekt)`, `Skill(intro)`
  och `Skill(stop-slop)` tillagda i allow-listan (stop-slop ska köras tyst —
  en permission-prompt bryter tystnaden). `Skill(namn)`-syntaxen verifierad
  mot officiell docs; ROADMAP-frågan stängd.

### Fixat

- **Intro-skillen påstod att en säkerhetsspärr fanns** — raden om att
  "en säkerhetsspärr blockerar farliga kommandon" borttagen
  (`block-dangerous.ps1` togs bort i 2.2.0).
- **Intro-skillen visar nu `/ekan:`-prefixade kommandon** — Block A/D/E/F/H
  använde oprefixade namn (`/jobb`) som inte fungerar i plugin-installation.
  Hybrid-notis tillagd i Block A.

## 2.3.0 — 2026-06-09

### Ändrat

- **`nytt-projekt` är nu en skill, inte ett slash-kommando** — flyttad från
  `commands/nytt-projekt.md` till `skills/nytt-projekt/SKILL.md`. Claude
  aktiverar den autonomt när konsulten berättar att ett anbud är vunnet eller
  ett nytt uppdrag startar ("vi vann anbudet", "nu har vi ett nytt projekt") —
  tidigare krävdes manuellt `/ekan:nytt-projekt`, som fortfarande fungerar.
  Skillen bekräftar projektnamnet med konsulten innan mappen skapas.
- **`setup.ps1`/`update.ps1` städar obsoleta kommandofiler** — ny
  `Remove-ObsoleteCommands` i `lib/install-lib.ps1` tar bort gamla
  `~/.claude/commands/nytt-projekt.md` vid hybrid-installation/-uppdatering,
  så att kommando- och skill-varianten inte samexisterar. Endast explicit
  listade filer rörs — konsultens egna kommandon lämnas orörda.

## 2.2.1 — 2026-06-09

### Lagt till

- **Update-ping i terminalen** — `hooks/session-start.ps1` jämför pluginens
  `VERSION` mot `~/.claude/.ekan-last-version` och skriver en rad i terminalen
  när versionen ändrats. Tyst när versionen är oförändrad. Gör autoupdates
  synliga utan att kräva manuell kontroll. (Ersätter PR #7, som grenades före 2.2.0.)

## 2.2.0 — 2026-06-08

### Borttaget

- **`block-dangerous.ps1` borttagen** — PreToolUse-hooken blockerade i praktiken
  ingenting: den skrev ett JSON-schema som Claude Code inte känner igen och
  avslutade med `exit 0` (= tillåt), så farliga kommandon släpptes alltid igenom.
  Den dubblerade dessutom Claude Codes inbyggda permission-skydd. Hooken och dess
  Pester-tester är borttagna; ramverket förlitar sig nu på Claude Codes egna
  säkerhetskontroller.

### Fixat

- **UTF-8 i `session-start.ps1`** — tvingar `[Console]::OutputEncoding` och filen
  sparas med BOM, så emoji/åäö inte blir mojibake i session-kontexten under
  Windows PowerShell 5.1 (som `hooks.json` startar via `powershell`).
- **Påminnelse efter komprimering** flyttad från rå `echo '...'` till en egen
  UTF-8-medveten `hooks/compact-reminder.ps1` — undviker literala citattecken på
  cmd.exe och teckenproblem mellan skal/kodsidor.
- **`nytt-projekt.ps1` validerar projektnamnet** (tomt namn ger tydlig hjälptext;
  sökvägstecken, `..` och otillåtna tecken avvisas) och städar bort en halvskapad
  projektmapp om något steg misslyckas, så att en omkörning blir ren.
- **`scripts/md_to_word.py`** avkodar pandocs utdata som UTF-8 (`errors="replace"`)
  i stället för systemets kodsida, så svenska felmeddelanden inte tappas eller
  garblas vid konverteringsfel.
- **`/ekan:setup` kraschade på en helt ren maskin** — `Merge-Permissions` skrev
  `~/.claude/settings.json` utan att först skapa `~/.claude`. Katalogen säkerställs
  nu. (Pester-testerna såg det inte eftersom de förseedar `.claude`; fångades av
  det nya smoketestet.)

### Lagt till

- **`tests/smoke.ps1`** — sandbox-smoketest som validerar att pluginet laddar och
  fungerar utan kollega eller Desktop: `claude plugin validate --strict`,
  UTF-8-kontroll av SessionStart-hookarna, och `/ekan:setup` mot en isolerad,
  bortstädad HOME. Kör: `pwsh -File tests/smoke.ps1`.
- **Frontmatter med `description`** på `jobb`-, `nytt-projekt`- och `setup`-kommandona,
  så `claude plugin validate --strict` går igenom rent och kommandona visas tydligt.

## 2.1.2 — 2026-04-27

### Fixat

- **PluginRoot-validering** — `hooks/ekan-setup.ps1` kastar nu tydligt fel
  om `$env:CLAUDE_PLUGIN_ROOT` saknas och `-PluginRoot` inte angetts.
  Tidigare kraschade `Install-RamverkClaudeMd` silent på `Join-Path "" ...`.

### Ändrat

- **MY-CLAUDE.md backupas inte längre** — dead code-rensning. Setup rör
  aldrig befintlig MY-CLAUDE.md (skapas bara från template när dst saknas),
  så backupen försvarade mot ett scenario som inte kan inträffa.
- **Settings.json-backup flyttad** från `~/.claude/settings.json.bak-<ts>`
  till `~/.claude/backups/settings.json.bak-<ts>`. Roterar och behåller
  de 5 senaste — ingen mer skräpfil-tillväxt över tid.

### Migration

`/ekan:setup` städar nu automatiskt bort gamla `MY-CLAUDE.md.bak-*` från
`~/consulting/` och `settings.json.bak-*` från `~/.claude/`-rotnivån.
Filer i den nya `~/.claude/backups/`-mappen rörs inte.

## 2.1.1 — 2026-04-27

### Ändrat

- **`kundspecifikt/`-mappen ersatt av `arkiv/`** i `~/consulting/`-strukturen.
  Mappen var oanvänd efter att referensen till "kundspecifika resurser" flyttats
  till `MY-CLAUDE.md` i 2.1.0. `arkiv/` är avsedd för avslutade uppdrag enligt
  konventionen `arkiv/<avslutsår>/<projektnamn>/` (se `consulting/CLAUDE.md` 6.4).
- **`consulting/CLAUDE.md` 6.4** — arkiveringssteget pekar nu på `arkiv/`-mappen
  med strukturhint för framtida `/ekan:slutrapport`-skill.

### Migration

Befintliga installationer: den lokala tomma `~/consulting/kundspecifikt/`-mappen
kan tas bort manuellt — den används inte längre av ramverket.

## 2.1.0 — 2026-04-27

### Tillkommer

- **Refaktorerad `consulting/CLAUDE.md`** till 8-sektion-struktur (rik standard).
  Nya sektioner: standarder för konsultarbete (källförankring, projektdokument,
  interaktionsstil, färgkoder), verktyg och resurser (markitdown, md_to_word,
  PowerPoint-val, Word-mallar), skills och plugin-ekosystem, beteenden Claude utför
  automatiskt (prompt chaining, thinking, high effort, projektavslut), miljö, roadmap.
- **`scripts/md_to_word.py`** — md→Word-konvertering via pandoc med Ekan-mallar
  som reference-doc. Default `Mall anteckningar.docx`. Stöder `--mall`-flagga.
  Robusta felmeddelanden vid saknad pandoc, templates-mapp eller indatafil.

### Ändrat

- **`consulting/MY-CLAUDE.md.template`** — tydligare avgränsning mot plugin-standard.
  Ny sektion "Vad hör hemma här (vs i CLAUDE.md)" och "Personliga verktyg utöver
  Ekan-standard".
- **Färgkonflikt löst** — `#8B2E2E` och `#941C1C` konsoliderade till en mörkröd.
- **ROADMAP** — avslutsflöde-not (`/slutrapport` + `/konsultcv` är ett par).

### Tas bort

- **Mistakes to Avoid-sektionen i CLAUDE.md** — konsultarbete är för brett för en
  generell lista; lärdomar hör hemma per skill (`references/fallgropar.md`) eller
  i projekt-CLAUDE.md.
- **Plan mode/Subagents/Utmana Claude-tips** — täcks av `superpowers:*`-pluginet.
- **Lessons Learned-flöde** — täcks av `claude-md-management:revise-claude-md`.
- **Rollfråga vid projektstart** — friktion överstiger värde.

## 2.0.0 — 2026-04-22

**Brytande ändringar:** Repot är nu en äkta Claude Code plugin med marketplace-distribution.

### Ny installation (plugin)

```
/plugin marketplace add DaVincisfather/ekan-plugins
/plugin install ekan@ekan-plugins
/ekan:setup
```

### Ändringar

- **Plugin-struktur** — `commands/`, `hooks/`, `skills/`, `lib/` är nu i repo-rot (inte under `claude/`).
- **Slash-prefix** — alla kommandon kräver `/ekan:`-prefix (`/ekan:intro`, inte `/intro`). Plugin-namespace-konvention.
- **`/ekan:setup`** — nytt slash-kommando som ersätter `setup.ps1` för plugin-användare. Städar legacy-artifakter, installerar ramverk, mergear permissions. Backup tas automatiskt.
- **Hybrid-fallback behålls** — `setup.ps1` + `update.ps1` fungerar för Desktop/IDE-användare med ny repo-struktur.
- **Marketplace-repo** — distribution via `DaVincisfather/ekan-plugins`.

### Migration från 1.x

Kör `/ekan:setup` efter `/plugin install` för att städa upp gamla setup.ps1-artifakter. Befintliga `MY-CLAUDE.md` och `~/consulting/projects/` bevaras. Backup tas av `MY-CLAUDE.md` och `~/.claude/settings.json`.

## 1.4 — 2026-04-16

### Fixat — kritiska buggar

- **Hårdkodad användarsökväg** i `/projektdirektiv`-skillen — ersatt med dynamisk `$env:USERPROFILE`/`~/consulting/templates/...`. Skillen fungerade tidigare bara på en dator.
- **Död referens till en delad regelfil** — borttagen från `/projektdirektiv` SKILL.md. Kvalitetsreglerna ligger i `consulting/CLAUDE.md`.
- **Död kommando-referens `/klassificering`** i `nytt-projekt.md` — borttagen (kommandot togs bort i 1.1).
- **Död skill-referens `/konsultcv`** i `consulting/CLAUDE.md` — flyttad till `ROADMAP.md` tills skillen är klar.
- **Mapp-namn-mismatch** — `/projektdirektiv` läste från `source/` och `meetings/`, men `nytt-projekt.ps1` skapar `40 Bakgrundsmaterial/`, `50 Styrande dokument/` och `20 Möten/`. Skillen uppdaterad.
- **Skill-name mismatch** — mappen `stop slop/` har bytts till `stop-slop/` så att mappnamn och `name:`-metadata matchar. Alla referenser uppdaterade.
- **`/projektplan`-referens** i `/intro` — skillen fanns inte. Ersatt med hänvisning till ROADMAP.

### Nytt

- **Deps-check** i `setup.ps1` — kontrollerar Git, Python 3.x, pip, Claude Code CLI och PowerShell execution policy innan installation startar.
- **`claude/lib/install-lib.ps1`** — gemensam modul som `setup.ps1` och `update.ps1` delar. Eliminerar duplicerad kopierings- och substitutionslogik.
- **Pester-tester** för `block-dangerous.ps1` — `tests/block-dangerous.Tests.ps1` täcker positiva fall, negativa fall och dokumenterade false positives. Se `tests/README.md`.
- **`ROADMAP.md`** omarbetad — hybrid-distribution (plugin + setup), cross-platform, prioriterad skill-kandidatlista.

### Ändrat

- **UTF-8 console encoding** i `setup.ps1` och `update.ps1` — å/ä/ö visas nu korrekt utan ASCII-transliteration.
- **README** — förtydligat att repot är ett setup-repo (inte en äkta Claude Code-plugin), lagt till troubleshooting för ExecutionPolicy och uppdaterat repo-namn i exempel.

## 1.3 — 2026-03-27

### Fixat

- **Version-ping fungerade inte** — `update.ps1` ersatte aldrig `__USER_HOME__` i hooks-sektionen vid inställningsmerge. Hooks-kommandona innehöll bokstavligen `__USER_HOME__` som sökväg, vilket tystfelsades och blockerade session-start-hooken (ingen versionskontroll, inga projekt-notiser).
- **`.gitattributes` tillagd** — Normaliserar radslut till CRLF på Windows, förhindrar falska git-konflikter vid `git pull`.

## 1.2 — 2026-03-27

### Fixat

- **Slash-kommandon `/jobb` och `/nytt-projekt`** saknades för nya konsulter efter installation. Kommandon var definierade lokalt med hårdkodade sökvägar och ingick inte i repot. Åtgärd: ny `claude/commands/`-mapp med generiska kommandofiler (sökvägar substitueras vid installation). `setup.ps1` och `update.ps1` kopierar och substituerar commands till `~/.claude/commands/`.

## 1.1 — 2026-03-26

### Nytt

- **Skill: `/intro`** — Guidad introduktion för nya konsulter (8 block, ca 20–30 min). Täcker orientering, rollprofil, risk, praktisk användning och en projektövning med fiktiv utlysning.
- **Skill: `stop slop`** — Eliminerar AI-skrivmönster från all skriftlig produktion. Laddas automatiskt vid textgenerering.
- **settings.json** — Standardkonfiguration med auto-mode, behörigheter, hooks och superpowers-plugin. Installeras via setup.ps1.

### Ändrat

- **CLAUDE.md trimmat** (205 → 127 rader) — Bort med thinking-taggar, effort level, generiska workflow-tips, lessons learned och icke-existerande skills. Renare och lättare kontext.
- **MY-CLAUDE.md.template** — Ny sektion för kundspecifika resurser, bättre exempel.
- **README** — Fullständig repostruktur tillbaka, tydligare steg-för-steg med explicit PowerShell → claude → /intro-flöde.
- **setup.ps1** — Ersätter `__USER_HOME__` i settings.json med rätt sökväg vid installation.

### Borttaget

- **`/klassificering`** (datasäkerhet) — Borttagen från CLAUDE.md, README, nytt-projekt.ps1 och compact-hook. Storleksklassificering i `/projektdirektiv` bevarad.

## 1.0 — 2026-03-11

Första release av Ekan Claude Code.

### Ingår

- **CLAUDE.md** — Ekans standardinstruktioner med tvålagerssystem (CLAUDE.md + MY-CLAUDE.md)
- **MY-CLAUDE.md.template** — Personlig konfiguration med fyra rollprofiler (junior/medior/senior/ledning)
- **setup.ps1** — Förstagångsinstallation (hooks, skills, settings, mallar, mappstruktur)
- **update.ps1** — Uppdatering av Ekan-standard utan att röra konsultens arbete
- **Hooks:** block-dangerous, jobb, nytt-projekt, session-start (med versionskontroll)
- **Skill:** projektdirektiv (med referensfiler och kvalitetschecklista)
- **Kompassen-mallar** — 28 standardmallar
- **Versionskontroll** — Automatisk notifiering vid sessionsstart om ny version finns
