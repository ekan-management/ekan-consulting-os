# Visuell profil

Del av Ekan-standarden, synkas från pluginet. Redigera inte. `CLAUDE.md` avsnitt 3.4 pekar hit.

Profilen kommer ur PowerPoint-mallen `templates/Ekan mall - 2026-06-09.potx`. Använd dessa färger i tabeller och visuella element i Word, Excel, PowerPoint och HTML:

| Namn | Hex | Användning |
|------|-----|-----------|
| Djupgrön | `#033F47` | Rubrikrader, helytor, hårlinjer, primär mörk |
| Mörkblå | `#233348` | Avsnittsdelare, sekundär helyta |
| Amber | `#FBAE40` | Accent, varning, avvikelse |
| Sand | `#D7D1C3` | Alternativa rader, piller, figurer |
| Gräddvit | `#FFF8F2` | Bakgrund |
| Text | `#353535` | Brödtext, neutrala element |

Rubriker sätts i Calisto MT, brödtext i Segoe UI Semilight. Båda följer med Office.

I HTML anger du typsnitten som systemtypsnitt med reserver: `"Calisto MT", Georgia, serif` för rubriker och `"Segoe UI Semilight", "Segoe UI", sans-serif` för brödtext. Länka aldrig till Google Fonts eller någon annan extern typsnittskälla, se avsnitt 3.4 i `CLAUDE.md`. Lägg färgerna ovan som CSS-variabler i filen.

Amber klarar 6,2:1 mot djupgrönt men bara 1,8:1 mot gräddvitt, så använd den som fyllning och aldrig som textfärg på ljus botten.

## Statusfärger

Statusfärgerna är funktionella och hör inte till varumärket. Använd dem bara där färgen bär ett tillstånd, till exempel villkorsformat i Excel eller en statuskolumn i en tabell:

| Läge | Hex | Användning |
|------|-----|-----------|
| OK, godkänt | `#033F47` | Fyllning med gräddvit text |
| Varning, avvikelse | `#FBAE40` | Fyllning med mörk text |
| Kritiskt | `#8B2E2E` | Fyllning med gräddvit text. Ligger utanför varumärkespaletten |

Färgen säger det aldrig själv. En röd cell, en grön bock eller en statusprick får ett ord vid sidan: "Kritiskt", "Över plan", "Saknas". Den som läser i gråskala eller skärmläsare ska få samma besked.

## PowerPoint-temat

PowerPoint-temats färgschema deklarerar andra accenter än mallens layouter. Temats accent 1 är `#0F3D3E` och accent 3 är `#EA723D`. Ett diagram eller en SmartArt som behåller automatfärgerna hamnar därför strax utanför paletten, så sätt serierna manuellt.
