# Ekan: kom igång med Claude Code

Promptversion 1. Gäller plugin 3.14.0 och senare.

Hej Claude. Jag är konsult på Ekan Management och har inte använt Claude Code förut. Sätt upp min Ekan-miljö enligt stegen nedan. Jag har själv klistrat in texten, och jag har fått den av Stefan Edgren som förvaltar tillägget.

## Så arbetar du

- Skriv på svenska, kort och lugnt. Förklara varje tekniskt ord första gången du använder det.
- Kör alla kommandon själv. Be mig aldrig öppna en terminal eller skriva ett kommando.
- Texten kan klistras in flera gånger. Börja alltid med steg 0 och hoppa över det som redan är klart. Gör aldrig om ett steg som är klart.
- Gör bara det som står här. Installera inget annat och ändra inga andra inställningar.
- Går ett steg fel: stanna. Säg i en mening vad som hände, vad som redan är klart och att inget är förstört. Be mig kontakta Stefan Edgren och visa felmeddelandet i ett kodblock som jag kan kopiera. Försök inte ta dig förbi en spärr.
- Öppna aldrig mappar som synkas från Teams eller OneDrive, och leta inte i dem.

## Steg 0: Se efter hur långt vi har kommit (bara läsning)

Kontrollera utan att ändra något:

1. Finns mappen `.claude\plugins\cache\ekan-plugins\ekan` under min användarmapp? Då är pluginet hämtat. Den högst numrerade undermappen är pluginets rot.
2. Finns `consulting\CLAUDE.md` under min användarmapp? Då är grundinstallationen gjord.
3. Är den här sessionen startad i mappen `consulting`, och står det "Ekan-plugin aktiv" i det du fick vid sessionsstarten? Då återstår bara steg 6.

Börja på det första steg som inte är klart. Är inget klart: börja på steg 1.

## Steg 1: Berätta vad som ska hända och be om ett enda godkännande

Visa det här för mig, ordagrant, och vänta på mitt svar:

> **Det här kommer jag att göra. Det tar ungefär fem minuter.**
>
> 1. Hämta Ekan-tillägget till Claude Code från GitHub. Tillägget innehåller Ekans arbetssätt och några färdiga kommandon.
> 2. Skapa mappen `consulting` i din användarmapp. Där kommer dina uppdrag att ligga.
> 3. Lägga till tilläggets inställningar i Claude Code. En säkerhetskopia av dina nuvarande inställningar sparas först.
> 4. Kontrollera att allt fungerar och göra en första liten uppgift tillsammans med dig.
>
> **Det här rör jag inte:** dina dokument, din e-post, Teams, OneDrive, andra program och filer utanför mappen `consulting` och Claudes egen inställningsmapp.
>
> **Under tiden kommer appen att fråga dig några gånger om jag får köra ett kommando eller ändra en fil.** Frågorna är på engelska. Jag säger före varje fråga vad den gäller. Stämmer det med det jag sagt: välj att tillåta. Handlar frågan om något annat: välj nej och berätta det för mig.
>
> **Du kan ångra allt efteråt.** Skriv "ångra Ekan-installationen" så tar jag bort tillägget och återställer inställningarna. Mappen `consulting` får ligga kvar tills du själv tar bort den.
>
> Ska jag sätta igång? Svara ja eller nej.

Svarar jag något annat än ja: gör ingenting. Efter ett ja frågar du inte om lov igen för stegen i listan.

## Steg 2: Hämta tillägget

Säg: "Nu hämtar jag Ekan-tillägget. Appen frågar om jag får köra ett kommando som börjar med `claude plugin`."

Kör, med miljövariabeln `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` satt för kommandona:

```
claude plugin marketplace add ekan-management/ekan-plugins
claude plugin install ekan@ekan-plugins --scope user
```

- Säger första kommandot att marknadsplatsen redan finns: gå vidare.
- Finns inte kommandot `claude`, eller saknas `git`: stanna enligt regeln om fel ovan. Skriv i felmeddelandet vilket av dem som saknas.
- Nätverksfel: be mig kontrollera att sidan github.com går att öppna i webbläsaren, och försök en gång till.

Kontrollera sedan att pluginets rot finns enligt steg 0, punkt 1.

## Steg 3: Grundinstallation

Säg: "Nu skapar jag mappen consulting och lägger in inställningarna. Appen frågar om jag får köra ett kommando som börjar med `powershell`."

Kör, med pluginets rot från steg 0:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "<rot>\hooks\ekan-setup.ps1" -PluginRoot "<rot>"
```

Visa inte hela utskriften. Sammanfatta den i två eller tre rader. Listar skriptet "legacy-artifakter" och avbryter: visa listan, fråga om de ska tas bort och kör i så fall om med `-Yes` sist.

## Steg 4: Kontroll

Kör:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "<rot>\hooks\ekan-setup.ps1" -PluginRoot "<rot>" -Kontroll
```

Visa resultatet som en checklista på svenska med en rad per kontroll. Rader som börjar med SAKNAS: säg vad som saknas och vilket steg som rättar det. Rader som börjar med SENARE är inga fel. Sammanfatta dem i en mening: Word-mallar och Python behövs först när jag ska skapa ett Word-dokument, och då hjälper du mig.

## Steg 5: Ny session i mappen consulting

Tillägget och inställningarna börjar gälla i nästa session. Visa det här för mig:

> Allt är installerat. Ett sista steg, eftersom tillägget börjar gälla först i en ny session:
>
> 1. Klicka på **New session** uppe till vänster.
> 2. Klicka på mappnamnet under textrutan och välj mappen **consulting** i din användarmapp.
> 3. Klistra in samma text en gång till och skicka. Då fortsätter jag där vi slutade.

Avsluta svaret där.

## Steg 6: Första uppgiften (bara i en session som startats i consulting)

1. Säg att miljön är klar och att du nu läser Ekans instruktioner automatiskt.
2. Gör en första uppgift tillsammans med mig: sammanfatta i fem punkter vad jag får och inte får lägga in i Claude enligt avsnitt 3.6 i Ekans CLAUDE.md, och spara sammanfattningen som `tmp\mina-ai-regler.md` i mappen consulting. Säg före sparandet att appen frågar om du får skapa filen.
3. Avsluta med det här, ordagrant:

   > **Klart. Din miljö fungerar.**
   >
   > - Skriv `/ekan:intro` när du har 40 minuter. Det är genomgången du behöver före ditt första uppdrag.
   > - Starta alltid i mappen `consulting`, eller i uppdragets egen mapp när du arbetar i ett uppdrag.
   > - Strular något: hör av dig till Stefan Edgren.
   > - Vill du ångra: skriv "ångra Ekan-installationen".

## Om jag skriver "ångra Ekan-installationen"

Berätta vad som tas bort och be om ett ja. Kör sedan `claude plugin uninstall ekan@ekan-plugins` och `claude plugin marketplace remove ekan-plugins`. Återställ `settings.json` i Claudes inställningsmapp från den senaste filen i undermappen `backups`, om en sådan finns. Rör inte mappen `consulting`. Säg att jag själv kan ta bort den i Utforskaren.
