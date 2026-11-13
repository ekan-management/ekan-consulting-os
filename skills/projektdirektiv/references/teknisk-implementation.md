# Teknisk implementation — python-docx (Projektdirektiv)

## Mallinspektion

Kör alltid inspektionsskriptet innan du skriver genereringsskriptet. Det ger stilnamn, numId, sektionsordning och placeholder-instruktioner per sektion.

```python
import os
from docx import Document
from docx.oxml.ns import qn
from docx.enum.style import WD_STYLE_TYPE

# Medel/stort: 'Mall Projektdirektiv.docx'. Litet: 'Mall Uppdragsdirektiv Små uppdrag.docx'
MALLMAPP = os.environ.get('EKAN_MALLAR') or os.path.join(os.path.expanduser('~'), 'consulting', 'templates')
TEMPLATE = os.path.join(MALLMAPP, 'Mall Projektdirektiv.docx')
doc = Document(TEMPLATE)

# Stilar
print([s.name for s in doc.styles if s.type == WD_STYLE_TYPE.PARAGRAPH])

# Struktur
for i, p in enumerate(doc.paragraphs):
    if p.text.strip():
        print(f"{i:3} [{p.style.name}] {p.text[:60]}")

# numId för List Paragraph
for p in doc.paragraphs:
    if p.style.name == "List Paragraph":
        pPr = p._element.find(qn('w:pPr'))
        if pPr is not None:
            numPr = pPr.find(qn('w:numPr'))
            if numPr is not None:
                print("numId:", numPr.find(qn('w:numId')).get(qn('w:val')))
                break

# Extrahera placeholder-instruktioner per sektion
current_heading = None
section_instructions = {}
for p in doc.paragraphs:
    if p.style.name.startswith('Heading'):
        current_heading = p.text.strip()
        section_instructions[current_heading] = []
    elif p.text.strip().startswith('<') and current_heading:
        section_instructions[current_heading].append(p.text.strip())
for h, instructions in section_instructions.items():
    if instructions:
        print(f"{h}: {instructions}")
```

## Skript-placering och städning

- Skriv skriptet till `~/consulting/tmp/create_pd_[projektnamn].py` — ALDRIG i projektmappen
- Kör skriptet, verifiera output
- Radera skriptet omedelbart efter: `rm ~/consulting/tmp/create_pd_[projektnamn].py`
- Projektmappen ska aldrig innehålla tillfälliga skript

## Tekniska regler

### 1. Strukturera innehåll som dicts, inte plaintext-strängar

```python
CONTENT = {
    "Bakgrund och syfte": {
        "type": "text",
        "paragraphs": ["Löptext stycke 1.", "Löptext stycke 2."]
    },
    "Risker": {
        "type": "mixed",
        "pre": "Övergripande riskbild...",
        "items": ["Risk 1 — hantering", "Risk 2 — hantering"]
    }
}
```

- `type: "text"` → lista av paragrafsträngar (Normal-stil)
- `type: "mixed"` → `pre` (Normal) + `items` (List Paragraph)

### 2. Ta bort sektioner korrekt

Använd body-children direkt — enkel paragraf-iteration missar tabeller i borttagna sektioner.

```python
def find_body_elements_to_remove(doc, heading_text):
    """Returnerar alla element (paragrafer + tabeller) under en given rubrik."""
    from docx.oxml.ns import qn
    body = doc.element.body
    collecting = False
    to_remove = []
    for child in body:
        tag = child.tag.split('}')[-1]
        if tag == 'p':
            style = child.find('.//{http://schemas.openxmlformats.org/wordprocessingml/2006/main}pStyle')
            text = ''.join(t.text or '' for t in child.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}t'))
            if style is not None and 'Heading' in style.get('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}val', ''):
                if collecting:
                    break
                if heading_text.lower() in text.lower():
                    collecting = True
                    continue
        if collecting:
            to_remove.append(child)
    return to_remove
```

### 3. Cacha XML-element INNAN ändringar

`doc.paragraphs`-index skiftar dynamiskt vid borttagning — cachat index är stabilt.

```python
all_elements = [p._element for p in doc.paragraphs]  # INNAN fill_section/deletions
```

### 4. Bullet-paragrafer kräver numPr-kopiering

```python
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

def add_bullet(doc, text, num_id):
    p = doc.add_paragraph(text, style='List Paragraph')
    pPr = p._element.get_or_add_pPr()
    numPr = OxmlElement('w:numPr')
    ilvl = OxmlElement('w:ilvl'); ilvl.set(qn('w:val'), '0')
    numId_el = OxmlElement('w:numId'); numId_el.set(qn('w:val'), num_id)
    numPr.append(ilvl); numPr.append(numId_el); pPr.append(numPr)
    return p
```

### 5. Anchor-baserad insertion (inte append-kedja)

Bygg `ordered = [(text, style), ...]` i önskad ordning, infoga i omvänd ordning efter samma anchor:

```python
for text, style in reversed(ordered):
    new_para = doc.add_paragraph(text, style=style)
    anchor_para._element.addnext(new_para._element)
```

Uppdatera INTE `last = p` — alltid efter samma anchor → korrekt slutordning.

### 6. Exempel:-rader ska raderas, inte ersättas

Annars dupliceras innehåll.

```python
to_remove = []
for p in doc.paragraphs:
    if p.text.strip().startswith('Exempel:') or p.text.strip().startswith('<'):
        to_remove.append(p._element)
for el in to_remove:
    el.getparent().remove(el)
```

### 7. Sidbrytning före Fastställande

```python
import unicodedata

def norm(text):
    return unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode().lower().strip()

for para in doc.paragraphs:
    if norm(para.text) == "faststallande" and "Heading" in para.style.name:
        para.paragraph_format.page_break_before = True
```

### 8. TOC-uppdatering via win32com — alltid sista steget

```python
import win32com.client, os

word = win32com.client.Dispatch("Word.Application")
word.Visible = False
doc_w = word.Documents.Open(os.path.abspath(OUTPUT))
for i in range(1, doc_w.TablesOfContents.Count + 1):
    doc_w.TablesOfContents(i).Update()
doc_w.Save()
doc_w.Close(False)
word.Quit()
```

## Kritiska regler

- Bevara ALL befintlig formatering (sidhuvud, sidfot, logotyp, stilar)
- Hitta placeholders `<Beskriv...>` och `Exempel:` — ersätt resp. radera
- Ta bort hela sektioner som inte behövs för aktuell storlek (inkl. tabeller)
- numId måste hämtas från mallens befintliga `List Paragraph` — hårdkoda aldrig ett värde

## Kända fallgropar

- `doc.paragraphs` är en dynamisk lista — modifiera aldrig under iteration, cacha element först
- Enkel paragraf-iteration missar tabeller vid sektionsborttagning — använd `find_body_elements_to_remove()`
- Kontakttabellen (Tabell 0) och signaturtabellen (Tabell 1) — blanda inte ihop dem
- **Rubrik vs Heading:** Ekans mall använder svenska XML-stil-ID:n (`Rubrik1`, `Rubrik2`) — INTE `Heading1`/`Heading2`. Kolla ALLTID både `"Heading" in style_val or "Rubrik" in style_val` vid heading-detection. python-docx `p.style.name` returnerar "Heading 1" men XML:ens `w:pStyle/@w:val` är "Rubrik1".
- **Signaturtabellen** har namn uppdelat i 3 runs: `"Namn "` + `"Namnsson"` + `"\nRoll"`. Adressera runs individuellt — `cell.text` eller `run.text` matchar aldrig hela "Namn Namnsson".

## Småmallen (litet uppdrag)

`Mall Uppdragsdirektiv Små uppdrag.docx` delar sidhuvud, försättsblad och stilar med den stora mallen, men har egna fallgropar. Reglerna ovan gäller, med följande tillägg och undantag.

### Struktur

| Rubrik (stil) | Innehåll i mallen |
|---|---|
| Uppdragsdirektivets syfte (Heading 2, onumrerad) | Standardtext. Behålls |
| Bakgrund och syfte (Heading 1) | `<Beskriv kortfattad bakgrund...>`, `<Beskriv uppdragets syfte.>` |
| Mål med uppdraget (Heading 1) | `<Beskriv vad uppdraget skall uppnå.>`, `<Tidpunkt när uppdraget ska vara genomfört.>` |
| Framgångsfaktorer, Risker (Heading 2) | Placeholder + exempelrad + exempelpunkter |
| Omfattning (Heading 1) → Genomförande, Leveranser, Avgränsningar (Heading 2) | Placeholder, i Leveranser och Avgränsningar även exempelrader |
| Uppdragsekonomi (Heading 1) → `Resursåtgång ` (Heading 2) | Rubriken har ett avslutande mellanslag. Jämför med `.strip()` |
| Fastställande (Heading 1) | Ort/datum, signaturtabell, sist ett tomt Heading 1-stycke som ska stå kvar |

Mallen har ingen innehållsförteckning. Hoppa över TOC-uppdateringen (regel 8).

### Instruktionsrader som inte börjar med `<`

Regel 6 fångar inte de här raderna. Radera dem tillsammans med punkterna (stil `List Paragraph`, XML-ID `Liststycke`) som följer fram till nästa rubrik:

- `Exempel på framgångsfaktorer som är viktiga i små uppdrag:` + fyra punkter + ett tomt `List Paragraph`-stycke utan numrering
- `Exempel på risker som vanliga inom små uppdrag:` + tre punkter
- `Vanliga leveranser i små uppdrag:` + tre punkter
- `Viktigt då detta säkerställer möjligheterna att hålla sig inom uppdragets ramar!` (inga punkter)

```python
EXEMPELRADER = ('Exempel på framgångsfaktorer', 'Exempel på risker',
                'Vanliga leveranser', 'Viktigt då detta säkerställer')
to_remove, in_example = [], False
for p in doc.paragraphs:
    t = p.text.strip()
    if p.style.name.startswith('Heading'):
        in_example = False
        continue
    if t.startswith(EXEMPELRADER):
        to_remove.append(p._element); in_example = True
    elif p.style.name == 'List Paragraph' and (in_example or not t):
        to_remove.append(p._element)
    else:
        in_example = False
```

### numId före radering

Exempelpunkterna är mallens enda `List Paragraph`-stycken. Läs numId (regel 4) **innan** de raderas, annars finns inget att hämta. Varje exempellista har ett eget numId, alla med punkttecken, så ett av dem räcker för alla nya punktlistor.

### Placeholders mitt i en mening

Under Resursåtgång står `Ekan Managements resursåtgång i enlighet med omfattning i avtal, <xxx timmar.> ` i en enda run. Stycket börjar inte med `<` och ska stå kvar. Ersätt bara `<xxx timmar.>` i run-texten, till exempel med `200 timmar.`. Placera innehållet om beställarens resurser efter stycket.

### Sidhuvud och försättsblad

Dokumentnamnet i sidhuvudet är en innehållskontroll (alias `Titel`) bunden till kärnegenskapen `title`. Försättsbladets Rubrik och Underrubrik är bundna till `title` och `subject` och ligger i en textruta som finns två gånger i XML:en (`mc:Choice` och `mc:Fallback`). Word läser om bundna kontroller från kärnegenskaperna när filen öppnas, men andra läsare (förhandsvisning, PDF-konvertering, python-docx) visar den cachade texten. Sätt därför båda:

```python
W = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'
doc.core_properties.title = PROJEKTNAMN
doc.core_properties.subject = KUNDNAMN
XP = {'/ns1:coreProperties[1]/ns0:title[1]': PROJEKTNAMN,
      '/ns1:coreProperties[1]/ns0:subject[1]': KUNDNAMN}
for root in [doc.element.body] + [s.header._element for s in doc.sections]:
    for sdt in root.iter(f'{W}sdt'):
        db = sdt.find(f'{W}sdtPr/{W}dataBinding')
        if db is not None and db.get(f'{W}xpath') in XP:
            ts = list(sdt.find(f'{W}sdtContent').iter(f'{W}t'))
            ts[0].text = XP[db.get(f'{W}xpath')]
            for t in ts[1:]:
                t.text = ''
```

Datumfälten är gulmarkerade och syns inte i `doc.paragraphs`:
- Sidhuvudets Version: `ÅÅ-MM-DD` (till exempel `26-10-20`). Markeringen sitter både på run-nivå och på styckemarkeringen (`w:pPr/w:rPr`)
- Försättsbladet: `ÅÅÅÅ-MM-DD`, två gånger (textrutans båda varianter), markerad på run-nivå

Iterera över XML:en, ersätt texten och ta bort `w:highlight` på båda nivåerna:

```python
def fyll_datum(root, gammal, ny):
    for r in root.iter(f'{W}r'):
        t = r.find(f'{W}t')
        if t is None or t.text != gammal:
            continue
        t.text = ny
        for hl in r.findall(f'{W}rPr/{W}highlight'):
            hl.getparent().remove(hl)
        p = r.getparent()
        while p is not None and p.tag != f'{W}p':
            p = p.getparent()
        if p is not None:
            for hl in p.findall(f'{W}pPr/{W}rPr/{W}highlight'):
                hl.getparent().remove(hl)

fyll_datum(doc.element.body, 'ÅÅÅÅ-MM-DD', '2026-10-20')
fyll_datum(doc.sections[0].header._element, 'ÅÅ-MM-DD', '26-10-20')
```

Författare och Ansvarig i sidhuvudet är två runs med texten `Nn`, i den ordningen.

### Signaturtabellen

Hämta tabellen via innehåll, inte `doc.tables[0]`. En infogad risktabell hamnar före signaturtabellen i dokumentordningen.

```python
sig = next(t for t in doc.tables
           if 'Namnsson' in ''.join(c.text for r in t.rows for c in r.cells))
```

Runs per cell: `['Namn', ' ', 'Namnsson', '\nBeställare']` och `['Namn', ' ', 'Namnsson', '\n', 'Konsult']`. Leta upp runen `Namnsson`, ersätt den med efternamnet och runen två steg före med förnamnet. Rollruns står kvar.

### Ort och datum

Raden `Göteborg/Stockholm 20XX-___________` är en run. Välj ort och fyll i året, men lämna dag och månad för signeringen: `Göteborg 2026-___________`.

### Risktabell

Infoga tabellen efter Risker-rubriken med kolumnerna Risk, Konsekvens, Hantering. Använd inte mallens `List Table 3 Accent 1`: rubrikraden får vit text på ljus turkos och svag kontrast. Ge rubrikraden fyllning djupgrön `#033F47` med fet gräddvit text `#FFF8F2`, och sätt brödtexten i 9 pt, enligt `ramverk/visuell-profil.md`.

```python
shd = OxmlElement('w:shd')
shd.set(qn('w:val'), 'clear'); shd.set(qn('w:color'), 'auto'); shd.set(qn('w:fill'), '033F47')
cell._tc.get_or_add_tcPr().append(shd)
```
