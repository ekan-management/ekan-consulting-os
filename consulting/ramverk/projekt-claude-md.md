# Projekt-CLAUDE.md: vad som hör i filen

Del av Ekan-standarden, synkas från pluginet. Redigera inte. `CLAUDE.md` avsnitt 3.5 pekar hit.

Projektets `CLAUDE.md` läses i sin helhet vid varje sessionsstart. Allt i den anländer som instruktion, utan tidsstämpel: rad 40 och rad 1 200 har samma auktoritet. I en chatt vinner det senaste, i en fil vinner ingenting. Därför är en föråldrad rad dyrare än en saknad. En saknad uppgift gör att Claude frågar; en föråldrad gör att Claude agerar med självförtroende och fel.

Fyra regler håller filen läsbar. De rör olika saker, och den första räcker inte utan de tre andra.

## 1. Historik flyttas ut

Håll filen vid aktuell ram: uppdrag, status, aktiva to-do, gällande beslut, källdokument. Flytta till `CLAUDE-historik.md` i projektmappen när något av det inträffar:

- en to-do-punkt blir avklarad
- en fas avslutas
- ett beslut eller en byggbeskrivning ersätts av ett senare
- ett spår läggs ner

Historikfilen inleds med att den inte ska läsas som instruktion, eftersom flera av dess beslut är ersatta. `CLAUDE.md` inleds med en rad som pekar på den.

Passerar `CLAUDE.md` 200 rader är det ett tecken på att flytten är försenad. Anthropic rekommenderar under 200 rader per CLAUDE.md, och projektets fil läses ovanpå Ekans. Det är en flagga, inte ett tak: bindande beslut som Claude måste läsa hör kvar i filen även när den blir lång, för felet "läste inte beslutet" är dyrare än "läste en aktuell rad i onödan".

## 2. Referensmaterial ligger utanför

Sammanfattningar av källdokument, domänkunskap, kontaktlistor, benchmarkdata, externa rapporter och analysunderlag från avslutade faser läggs som egna filer under `underlag/` i projektmappen. `## Källdokument` får en tabell med filnamn och en rad om vad varje fil innehåller.

CLAUDE.md säger att materialet finns och var. Inte vad det innehåller. Det är tvålagerarbetssättet (`CLAUDE.md` avsnitt 3) tillämpat på filen: fylligt analyslager som konsulten äger, sparsmakad ram som läses varje gång.

## 3. Byggloggen versioneras

När en ny version av en leverabel är byggd och verifierad: fäll in ändringarna i ett avsnitt som beskriver leverabeln som den är nu, och flytta den gamla versionens avsnitt till historiken. Låt inte specifikationen ligga som en kedja av deltan, där v4 beskriver ändringarna mot v3 och v3 mot v2. En sådan kedja går bara att läsa framåt i sin helhet, varje sessionsstart.

Görs det vid varje version kostar det fem minuter. Görs det inte alls blir det ett omskrivningsjobb som kräver att någon avgör vad som fortfarande gäller.

## 4. Beräknade utdata skrivs inte i filen

Andelar, nyckeltal, summor och resultat som en modell eller ett verktyg räknar fram ur underlag hör inte hit. De ändras när underlaget ändras, och varje gammal siffra blir en instruktion som pekar fel. Dokumentera indata, parametrar och var resultatet läses. Inte resultatet.

Undantag: en siffra som är ett **beslut** eller en **kundbekräftad uppgift** hör i filen. En beslutad och kommunicerad växlingsnivå ska stå där. En andel av budgeten som ett Excelverktyg räknar ur platshållardata ska inte.

## To-do-listor

To-do-punkter skrivs som kryssruterader (`- [ ]`). `/ekan:jobb` läser bara sådana rader, så vanliga punkter under en Öppet-rubrik syns inte i översikten.
