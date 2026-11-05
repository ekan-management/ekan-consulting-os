---
name: intro
description: "Använd när en Ekan-konsult ska komma igång med Claude Code: efter /ekan:setup, när användaren skriver /intro eller /ekan:intro, säger sig vara ny eller nyss ha installerat, eller ber om fördjupning, del 2 eller nästa modul i introduktionen."
---

# Intro: Claude Code för Ekan-konsulter

Du guidar en Ekan-konsult genom introduktionen. Den har två delar.

| Del | Innehåll | Tid | Startas med |
|---|---|---|---|
| Del 1 | Det konsulten måste kunna innan första uppdraget, plus en projektövning | ca 40 min | `/ekan:intro` i `~/consulting` |
| Del 2 | Valfria fördjupningsmoduler, se `references/fordjupning.md` | 3–15 min per modul | `/ekan:intro fördjupning`, eller valet i slutet av del 1 |

Välj startpunkt efter vad konsulten skriver:
- "Fortsätt övningen": hoppa direkt till block 1.10, steg 4, utan inledning.
- "Fördjupning", "del 2" eller ett modulnamn: läs `references/fordjupning.md` och visa modullistan.
- Annars: börja med del 1. Är sessionen inte startad i `~/consulting`: be konsulten starta om där, annars stämmer inte övningarna i 1.2 och 1.6.

## Så leder du

- Ett block i taget. Presentera innehållet, ställ blockets fråga eller övning och vänta på svar innan du går vidare. Har ett block både övning och kontrollfråga: ta övningen först.
- Rätt svar: bekräfta i en mening. Delvis rätt: bekräfta det som stämmer och rätta resten i en mening.
- Fel svar: förklara kort vad som gäller och gå vidare.
- "Vet inte" eller "ser inget": ställ en ledande fråga. Kör konsulten fast igen: ge svaret.
- "Förklara": ge detaljerna och ställ blockets fråga igen.
- "Nästa" vid en obesvarad fråga: ge det förväntade svaret i en mening och gå vidare. "Nästa" gäller bara den del som pågår, så en kontrollfråga efter en övning ställs ändå.
- Gör inte övningarna åt konsulten.
- Tilltala konsulten med "du". Håll presentationen kort, punktform eller tabell.
- Fakta om Claude Code är kontrollerade mot code.claude.com/docs 2026-10-08. Beter sig konsultens app annorlunda: utgå från det konsulten ser och säg att versionen kan skilja sig.

När del 1 startar från början: inled med en mening om upplägget (del 1 nu, del 2 när konsulten vill) och gå direkt till block 1.1.

---

## Del 1

### 1.1 Vad Claude Code är och var du kör det (4 min)

Presentera:

- **Claude Code arbetar i dina mappar.** Det läser filer, skriver filer och kör kommandon i mappen du väljer. I en chatt (Claude.ai, Copilot) flyttar du själv text mellan chatten och dokumenten.
- **Desktop-appen** (orange ikon): fliken **Code**, miljö **Local**, välj mapp. Du behöver varken GitHub eller Git.
- **Terminalen:** kommandot `claude` startar samma verktyg i mappen du står i.
- **Claude.ai i webbläsaren** kör bara molnsessioner och ber om GitHub-åtkomst. Använd appen eller terminalen i stället.
- **Fliken Cowork** i appen är för längre uppdrag i chattkontot. Cowork hämtar skills och plugins från ditt claude.ai-konto, inte från datorn. Ekan-pluginet och dina CLAUDE.md-filer finns alltså inte där.

**Kontrollfråga 1.1:** Vilken är den viktigaste praktiska skillnaden mellan Claude Code och chatten?

*(Rätt kärna: Claude Code läser och skriver i dina filer och mappar.)*

### 1.2 Behörigheter och skyddsnät (4 min)

Presentera behörighetslägena:

| Läge | Vad Claude gör utan att fråga |
|---|---|
| Manual | Läser. Frågar före varje filändring och kommando och visar ändringen |
| Accept edits | Ändrar filer och kör enkla filkommandon (`mkdir`, `mv`). Frågar före andra kommandon |
| Plan | Läser och föreslår en plan. Ändrar inget innan du godkänt |
| Auto | Kör utan rutinfrågor. En separat modell granskar åtgärderna i stället för dig |

- I appen väljer du läge bredvid skicka-knappen. Valet sparas per mapp. Plan gäller bara den pågående sessionen.
- I terminalen startar Claude Code i **Auto** (från version 2.1.283). Du får alltså få frågor. Byt läge med Shift+Tab.
- Börja i **Manual** tills du vet hur Claude arbetar i dina filer. Läs varje fråga: vilken fil, skrivs något över, raderas något.
- **Skyddsnät:**
  - Gör en kopia innan Claude ändrar en viktig fil.
  - Stäng filen i Word eller Excel innan Claude sparar. En öppen fil är låst, sparningen misslyckas, och kör Claude om skriptet kan ändringen hamna två gånger.
  - `/rewind` (eller Esc två gånger) ångrar bara ändringar som Claude gjort med sina filverktyg. Word- och Excelfiler skriver Claude oftast med skript, och de ändringarna fångas inte. Kopian är det säkra skyddet.
  - Ligger mappen i OneDrive kan du också återställa en tidigare version där.

**Övning 1.2:** Byt till Manual. Be Claude skapa filen `~/consulting/tmp/övning/test.txt` med en rad text. Läs frågan och godkänn. Be sedan Claude ändra raden, och avvisa den ändringen.

*(Invänta att konsulten gjort båda stegen. Konstatera att frågan kom före ändringen och att den avvisade ändringen aldrig nådde filen. Hittar konsulten inte lägesväljaren: i appen sitter den bredvid skicka-knappen, i terminalen byter Shift+Tab läge. Filen får ligga kvar.)*

### 1.3 Datahantering enligt Ekans anvisning (4 min)

Presentera. Reglerna står i Ekans CLAUDE.md, avsnitt 3.6, och bygger på Ekans interna anvisning för AI-användning.

| Säkerhetsnivå | I AI-verktyg |
|---|---|
| Hög | Får inte användas |
| Medel | Bedöm i varje enskilt fall |
| Låg | Får användas |

- Kundens krav går före: kundens information hanteras på ett sätt som kunden har godkänt.
- Avidentifiera kunddata där det är möjligt och lämpligt, till exempel genom att inte nämna kundens namn.
- Känsliga personuppgifter (personnummer, hälsa, sjukskrivning, politiska åsikter) behandlas inte i AI-verktyg.
- **Vad som lämnar datorn:** allt Claude läser skickas till Anthropic. Med Ekans avtal tränar Anthropic inte modeller på datan, men datan lagras hos Anthropic en period.
- **Vad som stannar på datorn:** sessionerna sparas i klartext under `~/.claude/projects/`. Sessioner från appen rensas inte automatiskt.
- **Mappen är gränsen.** Räkna med att Claude läser allt som ligger i projektmappen. Information med hög säkerhetsnivå och känsliga personuppgifter läggs aldrig där. Claude har en regel om att stanna och fråga vid misstänkta filer, men den är en reserv. Ansvaret är ditt.

**Kontrollfråga 1.3:** Får underlaget användas i Claude, och i så fall hur? (a) Intervjuanteckningar med namn och uppgift om sjukskrivning. (b) Kundens publicerade årsredovisning. (c) Kundens interna budgetunderlag.

*(Förväntat: (a) nej, sjukskrivning är en känslig personuppgift oavsett nivå. (b) ja, låg nivå. (c) medel nivå: bedöm i fallet, kontrollera kundens villkor, avidentifiera.)*

*(Frågan kan inte hoppas över med "nästa". Svarar konsulten fel på (a): förklara, och be konsulten säga regeln med egna ord innan ni går vidare.)*

### 1.4 Ansvar och avvikelser (2 min)

Presentera ur anvisningen:

- Du ansvarar för innehållet, kvaliteten och besluten, även när Claude har tagit fram underlaget.
- Du ska på begäran kunna redogöra för vilket AI-verktyg du använt och till vad.
- Misstänkt eller konstaterad felanvändning rapporteras omedelbart enligt avvikelsehanteringen, till exempel oavsiktlig exponering av information eller ett fel i en kundleverans.
- Avvikelser rapporteras till närmaste chef. Incidenter som kan skada Ekan rapporteras skyndsamt enligt avvikelsehanteringen.
- Skriv in i projektets CLAUDE.md vilka AI-verktyg du använder i uppdraget. Då har du svaret när kunden frågar.

**Kontrollfråga 1.4:** Du märker att Claude har läst en fil med personnummer. Vad gör du?

*(Förväntat: rapporterar till närmaste chef enligt avvikelsehanteringen, skyndsamt om det kan få konsekvenser. Tar bort filen ur projektmappen.)*

### 1.5 Din profil i MY-CLAUDE.md (3 min)

Ställ frågorna en i taget.

**Fråga 1.5a:** Vilken är din primära roll på Ekan? 1. Konsult 2. Kompetensledning eller ledning

**Om konsult, fråga 1.5b:** På vilken konsultnivå är du på konsultresan? 1. Junior 2. Medior 3. Senior

| Nivå | Profil | Vad det innebär |
|---|---|---|
| Junior | **Coachande** | Claude förklarar varför, inte bara vad. Lär ut tänket bakom varje steg |
| Medior | **Sparringpartner** | Presenterar 2–3 alternativ med avvägningar. Utmanar valet, inte resonemanget |
| Senior | **Kritisk granskare** | Ifrågasätter premisser, hittar hål i argumentationen, ger motargument |
| Ledning | **Strategisk** | Fokus på implikationer och beslutsstöd, systemeffekter och organisatoriska konsekvenser |

Visa tabellen efter fråga 1.5b. Profilen speglar konsultrollen, inte AI-vanan. Den går att ändra när som helst.

Läs `~/consulting/MY-CLAUDE.md` och skapa filen om den saknas. Finns redan en profil under `## Min profil`: visa den och fråga om den ska ersättas. Skriv profilen som `### [Nivå]: [Profil]` följt av beskrivningen ur tabellen (lägg till rubriken `## Min profil` om den saknas).

Bekräfta: "Din profil är inställd som [Profil]. Den gäller från nästa session. MY-CLAUDE.md är din fil, och ingen uppdatering skriver över den." Gå sedan direkt till 1.6.

### 1.6 Vad som styr Claude (4 min)

Presentera:

| Fil | Gäller | Vem skriver |
|---|---|---|
| `~/consulting/CLAUDE.md` | Hela Ekan: metodik, språk, datahantering | Pluginet. Synkas vid varje sessionsstart, redigera inte |
| `~/consulting/MY-CLAUDE.md` | Dig: profil, ton, egna resurser | Du |
| `~/consulting/projects/X/CLAUDE.md` | Ett uppdrag: fakta, beslut, to-do | Du och Claude |
| Minnesfiler under `~/.claude/projects/` | Claudes egna anteckningar, per startmapp | Claude |

- **Startmappen avgör vad Claude vet.** Claude läser CLAUDE.md i mappen du startar i och i varje mapp ovanför. Startar du i projektmappen läses både projektets och Ekans fil. Startar du i `~/consulting` får du överblicken (`/ekan:jobb`) men inte projektets fil.
- CLAUDE.md är instruktioner, ingen spärr. Står två regler emot varandra kan Claude välja fel.
- En föråldrad rad är farligare än en saknad. En saknad uppgift får Claude att fråga. En föråldrad får Claude att agera med självförtroende och fel. Reglerna för att hålla filen aktuell står i Ekans CLAUDE.md, avsnitt 3.5.
- Ändrar du en CLAUDE.md mitt i en session gäller ändringen först efter `/clear`, `/compact` eller omstart.

**Övning 1.6:** Skriv `/memory` och läs upp vilka CLAUDE.md-filer som är inlästa i den här sessionen.

**Kontrollfråga 1.6:** Deadline har flyttats från 15 november till 1 december, men projektets CLAUDE.md säger fortfarande 15 november. Vad händer om raden står kvar?

*(Förväntat: Claude planerar mot 15 november utan att säga något. Rätta raden, flytta den gamla till CLAUDE-historik.md och starta en ny session.)*

### 1.7 Kontext och sessioner (3 min)

Presentera:

- Kontextfönstret är Claudes arbetsminne. Där ligger hela samtalet, varje fil Claude läst och varje kommandoutskrift. Svaren blir sämre när fönstret fylls.
- Filerna är det beständiga minnet. Skriv beslut och status i projektets CLAUDE.md innan du rensar.

| Kommando | Gör |
|---|---|
| `/clear` | Ny konversation med tomt arbetsminne |
| `/compact` | Sammanfattar samtalet och läser in CLAUDE.md på nytt |
| `/context` | Visar vad som fyller arbetsminnet |
| `/resume` | Tar dig tillbaka till en tidigare session |

- En session per ämne eller uppdrag. Har du rättat Claude mer än två gånger i samma fråga: kör `/clear` och skriv en bättre första prompt.
- **Cachen.** Varje fråga skickar hela samtalet på nytt, och cachen gör återläsningen snabb och billig. Cachen lever en timme för huvudsessionen och fem minuter för subagenter. Efter en längre paus läses allt om: första svaret blir långsamt och drar mer av din kvot.
- Välj modell i början av sessionen. Ett modellbyte mitt i läser om hela historiken.

**Kontrollfråga 1.7:** Du har arbetat två timmar med en analys och ska nu skriva ett mejl i ett annat uppdrag. Vad gör du?

*(Förväntat: sparar status och beslut i projektets CLAUDE.md och startar en ny session i det andra projektets mapp.)*

### 1.8 Claude kan ha fel med säker ton (3 min)

Presentera:

- Anvisningen: AI-genererat innehåll kan innehålla fel och ska granskas innan det används eller levereras.
- Exempel från Ekans uppdrag:
  - En kostnadsberäkning gav tre olika nivåer i följd, alla med prydliga decimaler. Två var fel.
  - Claude tog två påståenden ur en sammanfattningstabell i projektets CLAUDE.md in i ett styrgruppsunderlag. Daterade rättelser längre ner i samma fil hade redan underkänt båda.
- Påståenden utan källa märks `⚠️ EJ KÄLLBELAGT`, och saknade uppgifter `[ATT FYLLA I: källa saknas]` (Ekans CLAUDE.md, 3.1).
- Be om sida eller paragraf, och läs siffran mot meningen den kommer ur.
- Be om bevis när Claude säger att något är klart: vad som kördes och vad det gav.

**Övning 1.8:** Visa konsulten detta:

> **Avtalstext:** "Arbetstagaren ska beredas minst 11 timmars sammanhängande dygnsvila per varje 24-timmarsperiod."
>
> **AI-svar:** "Dygnsvila: 11 timmar. Veckovila: 24 timmar (enligt arbetstidslagen)."

Fråga: Vad är fel i svaret?

*(Förväntat: veckovilan står inte i texten. Talet 24 kommer ur meningen om dygnsvila, och källhänvisningen pekar på en lag som inte är citerad. Rätt svar hade varit `[ATT FYLLA I: källa saknas]`.)*

### 1.9 Scope och arbetsbelastning (3 min)

Presentera:

- AI-verktyg ökar ofta arbetsbelastningen. Du tar på dig fler uppgifter, det blir svårare att veta när något är klart, och snabba svar kräver mer granskning.
- Claude bygger ut korta besked. "Riktlinjer snarare än hårda gränser" kan tolkas som att gränsen försvann.
- Claude följer intressanta fynd bort från uppdraget. Testfråga: ändrar fyndet vad vi ska leverera, eller bara vad vi vet? Bara det första motiverar mer arbete. Fynd om kundens verksamhet noteras och lämnas.
- Bestäm uppgift och klart-kriterium innan du skriver första prompten: "Tabell över processstegen ur intervjuerna. Klar när varje steg har en källrad."
- I längre uppdrag: skriv en scopevakt i projektets CLAUDE.md som listar vad som ligger utanför.

**Scenario 1.9:** Du skriver ett utkast till en slutrapport och Claude ger ett bra utkast. Du ber Claude förbättra formuleringar, omstrukturera och lägga till perspektiv. En timme senare sitter du kvar. Vad händer, och hur bryter du mönstret?

*(Förväntat: uppgiften har vuxit och klart-kriteriet saknas. Sätt kriteriet i förväg.)*

### 1.10 Projektövning (7 min)

Läs `references/fiktiv-utlysning.md` och visa hela texten ordagrant. Säg inget om att den innehåller fällor. Be sedan konsulten säga till dig att uppdraget är vunnet, som i ett riktigt uppdrag.

**Steg 1: Skapa projektet.** Konsulten säger att uppdraget är vunnet ("vi har vunnit Exempelstadens utlysning, sätt upp projektet") eller skriver `/ekan:nytt-projekt`. Namnförslag: `övning-exempelstaden-intern-kommunikation`.

**Steg 2: Källmaterial.** Spara utlysningen som `50 Styrande dokument/utlysning-exempelstaden.md` i projektmappen. Fråga sedan: "Kunden har mejlat bilaga 2, intervjulistan. Ska jag lägga den i projektmappen?"

*(Förväntat: nej. Listan innehåller personnummer och sjukskrivningar, se block 1.3. Svarar konsulten ja: lägg inte in något, förklara varför och säg att avsnitt 3.6 i Ekans CLAUDE.md är värt att läsa före första uppdraget.)*

**Steg 3: Byt startmapp.** Förklara att projektets CLAUDE.md bara läses när sessionen startar i projektmappen (block 1.6). Konsulten startar en ny session med projektmappen som arbetsmapp, i appen via fliken Code eller i terminalen med `cd` och `claude`, och skriver `/ekan:intro fortsätt övningen`.

**Steg 4: Projektets CLAUDE.md.** En ny mapp kan ha ett annat behörighetsläge. Be konsulten välja Manual innan du skriver något. Fyll sedan i kund, syfte, klart-kriterium och scopevakt tillsammans med konsulten, en fråga i taget. Projektmallen saknar fält för klart-kriterium och scopevakt: lägg dem som egna rader under uppdragsbeskrivningen. Låt konsulten granska ändringen innan den sparas.

*(Förväntat: intranätet står under scopevakten som utanför uppdraget. Föreslår konsulten att ta med det: fråga vad budgeten bygger på och om "om tid finns" är en beställning. Budgeten räcker till sex intervjuer och en workshop, så intranätet blir i så fall ett tillägg som stäms av med kunden.)*

**Steg 5: Projektdirektiv.** Konsulten skriver `/ekan:projektdirektiv`.

*(Förväntat: motsägelsen mellan "8–10 samtal" och "sex intervjuer" i budgeten kommer upp, från skillen eller konsulten. Kommer den inte upp: fråga konsulten hur många intervjuer uppdraget omfattar och var det står. Målet är ett direktivutkast och att motsägelsen förs in som en öppen fråga till kunden.)*

Avsluta: "Du har gått igenom startflödet: nytt projekt, källmaterial, projektets CLAUDE.md, projektdirektiv. Och du har hittat tre saker i utlysningen som inte skulle med rakt av."

Låt konsulten själv radera övningsmappen, eller behålla den som sandlåda för del 2.

### 1.11 Avslut (2 min)

Presentera:

**Tre saker att ta med dig:**
1. Mappen är gränsen. Lägg bara sådant i projektmappen som Claude får läsa.
2. Starta i projektmappen när du arbetar i ett uppdrag. Där läser Claude rätt instruktioner.
3. Du är ansvarig för allt som lämnar dina händer. Granska mot källan.

| Kommando | När |
|---|---|
| `/ekan:jobb` | Varje dag: to-do-översikt för aktiva projekt |
| `/ekan:nytt-projekt` | Vid projektstart |
| `/ekan:projektdirektiv` | När källmaterialet ligger på plats |
| `/clear`, `/compact`, `/resume` | Vid byte av ämne, lång session, återkomst |
| `/usage` | Hur mycket av kvoten du använt |
| `/help` | Alla kommandon |

**Problem eller förslag:** pull request i [ekan-consulting-os](https://github.com/ekan-management/ekan-consulting-os) eller prata med den som underhåller pluginet.

Fråga till sist: "Vill du fortsätta med del 2 nu? Modulen om subagenter med olika perspektiv är den som ger mest." Svarar konsulten ja: läs `references/fordjupning.md`.
