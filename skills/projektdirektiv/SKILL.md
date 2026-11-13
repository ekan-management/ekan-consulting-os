---
name: projektdirektiv
description: "Använd när ett uppdrag ska formaliseras i ett direktiv: källmaterial (offert, avtal, förfrågningsunderlag) finns i projektmappen och projektdirektiv saknas, eller när konsulten säger 'projektdirektiv', 'uppdragsdirektiv', 'skapa PD' eller 'formalisera uppdraget'. Använd INTE för: projektplaner, statusrapporter, offerter, tidsrapporter eller andra projektdokument."
---

# Projektdirektiv

Skapa projektdirektiv som Word-fil, skalat efter uppdragsstorlek (litet/medelstort/stort). Storleken avgör mall och arbetsflöde:

| Storlek | Mall | Arbetsflöde |
|---|---|---|
| Litet | `Mall Uppdragsdirektiv Små uppdrag.docx` | En avstämning, sedan utkast |
| Medelstort, stort | `Mall Projektdirektiv.docx` | Avstämning efter varje steg |

Båda mallarna ligger i mallmappen: miljövariabeln `EKAN_MALLAR` om den är satt, annars `~/consulting/templates/`. Pluginet innehåller inga mallar, de ligger i Teamsytan för varje uppdrag. Läs mallen, skriv aldrig till mallmappen. Saknas mallen: stanna och be konsulten ladda ner den från uppdragets Teamsyta och lägga den i mallmappen. Leta inte själv i synkade Teams- eller OneDrive-mappar. Bygg aldrig ett direktiv utan mallen.

## Workflow

```
1. Klassificera uppdragsstorlek → välj mall och arbetsflöde
2. Läs ALLA källdokument
3. Inspektera mallen
4. Generera innehåll
5. Källförankrad validering
6. Kvalitetskontroll
7. Skriv filen
```

Litet uppdrag går igenom samma steg men stannar bara en gång, efter steg 3. Se "Litet uppdrag: en avstämning" nedan.

### Steg 1: Klassificera uppdragsstorlek

Analysera källdokument (CLAUDE.md, source/, offert) för budget, timmar, tidsperiod, faser och intressenter. Om informationen inte räcker, fråga.

Läs `references/klassificering.md` för poängsystem, mallval och avsnitt per storlek.

**Har konsulten själv angett storlek** i argumenten eller samtalet ("kort", "litet", eller en timvolym på högst 200 timmar), räkna poängen och visa dem, men ställ ingen gränsfallsfråga. Konsultens besked gäller.

**Medel/stort:** presentera klassificeringen och invänta bekräftelse innan du fortsätter.
**Litet:** gå vidare. Klassificeringen ingår i avstämningen efter steg 3.

### Steg 2: Läs alla källdokument

**Läs INNAN du börjar skriva.**

Läsordning (Ekans projektmappstruktur, se `nytt-projekt.ps1`):
1. `CLAUDE.md` i projektmappen
2. Alla filer i `50 Styrande dokument/` (avtal, förfrågningsunderlag, offert)
3. Alla filer i `40 Bakgrundsmaterial/` (kundmaterial, referensunderlag)
4. Mötesanteckningar i `20 Möten/`
5. Konversationshistorik i denna session

Syntetisera, identifiera motsägelser, notera vad som saknas.

### Steg 3: Inspektera mallen

Kör inspektionsskriptet från `references/teknisk-implementation.md` mot mallen för aktuell storlek. Det kartlägger stilnamn, numId, avsnittsordning och placeholder-instruktioner.

**Medel/stort:** presentera placeholders per avsnitt och invänta bekräftelse.
**Litet:** presentera inte placeholderlistan. Använd den för att planera innehållet i avstämningen.

### Steg 4: Generera innehåll

Kombinera två källor för varje avsnitt:
1. **Placeholder-instruktionen** (från steg 3): bekräftar att avsnittet är relevant
2. **`references/skrivstilar.md`**: definition (vad ska in), format och exempel. För småmallen anger skrivstilar.md vilken definition varje avsnitt följer

Följ även de generella kvalitetsreglerna i `~/consulting/CLAUDE.md` (källförankring, rollfråga, effektmål-gränsdragning).

**PD-specifik regel, kundavtal:**
Direktivet undertecknas av kunden. Ta ALDRIG med interna Ekan-processer (Rexor, fakturering, lessons learned). Överlämning och kunskapsåterföring = enbart vad kunden får.

### Steg 5: Källförankrad validering

Verifiera varje faktuellt påstående mot källdokumenten. Flagga med `⚠️ EJ KÄLLBELAGT` vid avsaknad av stöd.

**Medel/stort:** presentera valideringsrapport och invänta bekräftelse.
**Litet:** flaggorna står i utkastet och listas vid leverans.

### Steg 6: Kvalitetskontroll

Läs och kör `references/kvalitetschecklista.md`. Litet uppdrag har en egen variant i checklistan.

**Självgranskning (UA-perspektiv), obligatorisk:**
Tänk igenom dokumentet i `<thinking>`-taggar som UA. Presentera 1–3 svagheter med förbättringsförslag. Medel/stort: innan filen skrivs. Litet: tillsammans med utkastet.

### Steg 7: Skriv filen (python-docx)

Följ `references/teknisk-implementation.md` för alla tekniska mönster. Småmallen har egna fallgropar i ett eget avsnitt där.

**Filnamn:**
- Litet: `uppdragsdirektiv [Projektnamn] UTKAST.docx`, efter mallens namn på dokumentet
- Medel/stort: `projektdirektiv [Projektnamn] UTKAST.docx`

Presentera med klassificering, källor, ATT FYLLA I-fält och antaganden.

## Litet uppdrag: en avstämning

För litet uppdrag samlas allt som kräver konsultens besked i en enda fråga efter steg 3:

1. **Klassificering:** poäng per dimension och totalsumma, eller konsultens eget besked om storlek
2. **Mallval:** `Mall Uppdragsdirektiv Små uppdrag.docx`
3. **Planerat innehåll per avsnitt:** en till två rader per avsnitt i småmallen, med källan inom parentes. Tidplanen planeras som faser med datum under Genomförande
4. **Öppna sakfrågor:** bakgrundsfrågan i skrivstilar.md, beställarens resurser, och det som källorna inte besvarar eller motsäger

Invänta svaret. Skriv sedan utkastet utan fler stopp: steg 4–7 i följd. Leverera filen med:
- `⚠️ EJ KÄLLBELAGT`-flaggor och `[ATT FYLLA I: ...]`-fält
- Antaganden
- Självgranskningen (1–3 svagheter med förbättringsförslag)

Filnamnet slutar på UTKAST, så konsulten granskar och justerar efter leverans.

## Felhantering

- **Mall hittas inte** → Fråga användaren
- **Saknad information** → Fråga, gissa ALDRIG. För litet uppdrag samlas frågorna i avstämningen
- **Oklarheter mellan källor** → Presentera motsägelsen
- **Klassificering osäker** → Låt användaren välja, om hen inte redan har angett storlek
