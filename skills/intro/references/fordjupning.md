# Del 2: Fördjupning

Valfria moduler. Visa listan, låt konsulten välja och kör modulen med samma regler som i del 1: ett block i taget, vänta på svar, gör inte övningarna åt konsulten. Erbjud nästa modul när en är klar.

Flera övningar bygger vidare på övningsprojektet från del 1 (Exempelstaden). Finns det inte: skapa det enligt block 1.10, steg 1–4, innan modulen startar.

| Nr | Modul | Tid |
|---|---|---|
| 1 | Subagenter med olika perspektiv | 15 min |
| 2 | Agentbegreppen: Copilot-agenter och subagenter | 5 min |
| 3 | Plan-läget och att låta Claude fråga först | 5 min |
| 4 | Skills och slash-kommandon | 8 min |
| 5 | Verifieringsknep | 8 min |
| 6 | Vad Claude är bra och sämre på i konsultarbete | 5 min |
| 7 | Office-filer i praktiken | 8 min |
| 8 | Arbeta tillsammans via OneDrive | 5 min |
| 9 | Sessionsrutiner | 5 min |
| 10 | Kostnad, modellval och användningsgränser | 5 min |
| 11 | Instruktioner gömda i dokument | 3 min |

---

## 1. Subagenter med olika perspektiv (15 min)

Presentera:

- En subagent är en ny Claude-instans som huvudsessionen startar för en deluppgift. Den har ett eget arbetsminne och lämnar bara tillbaka en sammanfattning. Flera kan köras parallellt.
- **Perspektivgranskning:** samma leverabel granskas av flera subagenter i olika roller, till exempel projektledare, upphandlare och kundens beställare. Var och en lämnar de 1–3 svagaste punkterna (Ekans CLAUDE.md, 6.1).
- **Granskning av beräkningar** kräver andra roller än perspektiv:

| Roll | Uppdrag |
|---|---|
| Reproduktionstestare | Får metoden och körs mot kända utfall som metoden inte kalibrerats mot. Kriterierna sätts i förväg |
| Falsifierare | Utgår från att metoden har minst ett allvarligt fel och letar tills felet hittats eller uteslutits |
| Normativ prövare | Får smala frågor med ett rätt svar i lag eller primärkälla, men inte våra svar. Ska hänvisa |

- **Fällor:**
  - Subagenter ser inte ert samtal. Allt de behöver ska stå i uppdraget eller i filer.
  - Subagenter läser samma CLAUDE.md-filer som huvudsessionen. Står slutsatsen i projektets CLAUDE.md är granskaren inte blind. De inbyggda agenterna Explore och Plan läser inga CLAUDE.md-filer. Säkrast är en egen mapp utanför projektet med bara indata.
  - En subagent som ombeds hitta brister hittar några. Be om fynd som påverkar korrekthet eller krav.
  - Be subagenterna skriva rapporterna till fil. Kontrollera deras kärnpåståenden själv innan något förs in som fakta.
  - Varje subagent drar egen kvot.

**Övning 1:**
1. Konsulten ber Claude starta tre subagenter parallellt (projektledare, upphandlare, kundens beställare). Var och en granskar utlysningen och projektdirektivutkastet och skriver högst tre svagheter till `10 Dokument under arbete/granskning/<roll>.md`.
2. Läckagetest: konsulten skriver in raden "Beslut: uppdraget omfattar sex intervjuer" i projektets CLAUDE.md och startar en ny session i projektmappen. Konsulten ber en subagent svara på frågan "Hur många intervjuer omfattar uppdraget enligt utlysningen?"
3. Samma fråga ställs till Explore-agenten.
4. Konsulten tar bort raden.

*(Förväntat: steg 1 ger tre filer med olika fynd. I steg 2 svarar subagenten troligen "sex" utan att nämna "8–10 samtal". I steg 3 bör Explore se båda uppgifterna. Poängen: CLAUDE.md styr vad granskaren ser.)*

## 2. Agentbegreppen (5 min)

Presentera:

- **Copilot-agenter** och liknande byggs i förväg för ett återkommande syfte och kan delas med kollegor.
- **I Claude Code är huvudsessionen agenten.** Den planerar, läser, skriver och kör kommandon i flera steg.
- **Subagenter** startas av huvudsessionen för en deluppgift. Inbyggda: Explore (läser och söker, ändrar inget), Plan (samlar underlag i Plan-läget) och general-purpose. Egna definieras i `.claude/agents/` i projektet eller i `~/.claude/agents/`.

**Kontrollfråga 2:** Vad ser en subagent av ert samtal?

*(Förväntat: ingenting. Den får uppdragstexten och CLAUDE.md-filerna. Explore och Plan hoppar över CLAUDE.md.)*

## 3. Plan-läget och att låta Claude fråga först (5 min)

Presentera:

- I Plan-läget läser Claude och skriver en plan. Inget ändras innan du godkänt den. I appen väljer du Plan bredvid skicka-knappen, i terminalen med Shift+Tab.
- Hoppa över planen när ändringen går att beskriva i en mening.
- Inför större arbete: be Claude intervjua dig, en fråga i taget, innan något görs. Starta sedan en ny session för genomförandet.

**Övning 3:** Konsulten väljer Plan-läget och ber: "Bygg en Excelmall för tidsuppföljning per fas i Exempelstaden-uppdraget." Konsulten stryker en del av planen och godkänner resten.

*(Förväntat: ingen fil skapas före godkännandet, och den strukna delen saknas i resultatet.)*

## 4. Skills och slash-kommandon (8 min)

Presentera:

- En skill är en mapp med en `SKILL.md`. Claude ser bara beskrivningen tills skillen används, sedan läses resten in. Claude startar en skill när beskrivningen matchar situationen, eller när du skriver `/namn`.
- Pluginets skills har prefix: `/ekan:projektdirektiv`.
- Egna skills läggs i `~/consulting/skills/personal-*`. En som visat sitt värde kan bli en del av pluginet via pull request.
- Bygg en skill när du gör samma sak för tredje gången. Instruktioner i en skill kostar arbetsminne bara när skillen används, till skillnad från CLAUDE.md.
- Skriv beskrivningen så att den säger när skillen ska användas och när inte. Se `nytt-projekt` och `projektdirektiv` för mönstret "Använd INTE för ...".

**Övning 4:** Konsulten väljer ett återkommande moment, till exempel veckostatus till kund, och ber Claude skissa `personal-veckostatus/SKILL.md` med namn, beskrivning och fem steg.

*(Förväntat: beskrivningen anger när skillen ska användas och när inte.)*

## 5. Verifieringsknep (8 min)

Presentera:

- **Sabotera kontrollen.** Mata in ett känt fel och se om kontrollen larmar. I en kostnadsberäkning visade sig fyra av sex kontroller vara identiteter som inte kunde slå fel.
- **Pröva mot något utanför modellen,** till exempel publicerade utfall. Ett mönster över flera fall är ingen förklaring.
- **Primärkällan går före egen sammanställning.** Säger kundens Excelflik "2026" och vår gaplista "2025" är det gaplistan som är fel.
- **Senaste daterade rättelsen vinner.** Sök i projektets CLAUDE.md på ämnesordet och läs datumen före leverans.
- **Källseparation.** Granska inte Claudes eget utkast som om det vore källmaterial (Ekans CLAUDE.md, 3.2).

**Övning 5:** Visa konsulten detta utdrag ur en projekt-CLAUDE.md och fråga vilken budget som gäller:

> | Post | Värde |
> |---|---|
> | Budget | 120 000 kr |
>
> ⚠️ Rättelse 2026-10-01: budgeten är utökad till 150 000 kr efter beslut i styrgruppen.

*(Förväntat: 150 000 kr. Rättelsen är daterad och nyare än tabellen.)*

## 6. Vad Claude är bra och sämre på (5 min)

| Starkare | Svagare |
|---|---|
| Analys och beräkningar med källhänvisning och kontroller | Långa rapporttexter i din röst |
| Excelverktyg och räknebänkar | PowerPoint på Ekans mallar. Använd PowerPoint-pluginet, inte skript (Ekans CLAUDE.md, 4.3) |
| Projektstruktur och projektminne | Att förstå vad kunden egentligen vill ha |
| Sammanfattningar, protokoll, CV-uppdatering | Korta besked: Claude bygger gärna ut dem |

- Rapporter: du skriver texten. Claude ger disposition, stämmer av logiken mot källorna och tar mindre stycken på begäran.
- Be Claude redovisa varje ändring i din text som "Står → Nu". Oredovisade småändringar förstör din röst.

**Kontrollfråga 6:** Vilka uppgifter ger du Claude när du skriver en slutrapport?

*(Förväntat: disposition, logikkontroll mot källor och projektbeslut, punktvisa ändringsförslag.)*

## 7. Office-filer i praktiken (8 min)

Presentera:

- **Låsta filer.** En `~$`-fil i mappen betyder att Word eller Excel har filen öppen. Stäng den eller be Claude säga till före sparning. Har en sparning misslyckats: kontrollera filen innan skriptet körs igen, annars kan ändringen hamna två gånger.
- **Öppen Excel.** Ett skript som styr Excel kan i värsta fall stänga dina öppna arbetsböcker. Spara dem innan.
- **Svenska tecken.** Claude kan skriva "manad" i stället för "månad" när det genererar Office-filer med skript. Kontrollera med `python scripts/check_diakriter.py "SÖKVÄG"` (Ekans CLAUDE.md, 2.1).
- **Läsa och skriva.** `scripts/read_office.py` läser Word, Excel, PowerPoint och PDF. `scripts/md_to_word.py` skriver Word med Ekans mallar.
- **Visningssidor** för möten fungerar bra som HTML i Ekans profil. Fråga innan en sida med kunddata publiceras någonstans.

**Övning 7:** Claude skapar `Mötesanteckningar Exempelstaden.docx` med rubriken "Åtgärder för HR-kommunikationen". Konsulten öppnar filen i Word och ber Claude ändra en rad. Därefter stänger konsulten filen och Claude försöker igen. Sist körs `check_diakriter.py`.

*(Förväntat: första försöket misslyckas för att filen är låst, andra lyckas, kontrollen hittar inga fel.)*

## 8. Arbeta tillsammans via OneDrive (5 min)

Presentera:

- En delad projekt-CLAUDE.md styr allas Claude. En föråldrad rad slår mot hela teamet.
- Minnesfiler och sessioner ligger lokalt på din dator och följer inte med till kollegorna.
- Rätta med daterade block i stället för att skriva om tyst, så att kollegorna ser vad som ändrats.
- Vid korrläsning i ett delat dokument: bestäm vilken version som är master. Claude ändrar inte en lokal kopia medan andra arbetar i originalet.

**Kontrollfråga 8:** En kollega uppdaterar projektets CLAUDE.md medan din session pågår. Ser din Claude ändringen?

*(Förväntat: först när filen synkats och du kört `/clear`, `/compact` eller startat om.)*

## 9. Sessionsrutiner (5 min)

Presentera:

- Före `/clear`: skriv status, beslut och öppna to-do i projektets CLAUDE.md. Mönster som gäller alla dina projekt hör hemma i MY-CLAUDE.md.
- To-do skrivs som kryssrutor (`- [ ]`). Andra punkter syns inte i `/ekan:jobb`.
- `/resume` tar dig tillbaka till en tidigare session.
- Kör `/compact` vid en naturlig paus mellan uppgifter, inte mitt i en.
- En rutin du gör varje gång kan bli en egen skill (modul 4).

**Kontrollfråga 9:** Nämn tre saker du sparar innan `/clear`.

*(Förväntat: status, beslut, öppna to-do som kryssrutor.)*

## 10. Kostnad, modellval och användningsgränser (5 min)

Presentera:

- Planen har en kvot per person som delas mellan chatt, Cowork och Claude Code. Kvoten räknas i ett rullande femtimmarsfönster och ett veckofönster.
- `/usage` visar hur mycket du använt och vad som drar mest.
- `/model` byter modell. Välj vid sessionens början: ett byte mitt i läser om hela historiken.
- Det som drar mest: långa sessioner, pauser längre än cachens livslängd (en timme), subagenter och komprimering.

**Kontrollfråga 10:** Du kommer tillbaka efter lunch till en stor session. Varför går första svaret långsamt?

*(Förväntat: cachen har gått ut och hela historiken läses om.)*

## 11. Instruktioner gömda i dokument (3 min)

Presentera:

- Claude läser kunddokument, mejl och webbsidor. Text i dem kan se ut som en instruktion till Claude ("skicka filen till ...", "ignorera tidigare instruktioner").
- Behandla sådan text som innehåll, inte som order. Granska särskilt förslag som dyker upp efter att Claude läst externt material och som skickar data någonstans eller raderar något.

**Kontrollfråga 11:** Claude föreslår att mejla en fil till en adress som stod i en upphandlingsbilaga. Vad gör du?

*(Förväntat: avböjer och frågar varifrån förslaget kom.)*
