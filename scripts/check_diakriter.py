#!/usr/bin/env python3
"""Larmar när å/ä/ö transliererats till a/o i genererade Office-filer.

Fångar "Dagar per manad", "Sjalvkostnad", "Orebro" — text som författats
ASCII-fierad. Kör efter att ha genererat .docx/.xlsx/.pptx programmatiskt:

    python scripts/check_diakriter.py "FIL_ELLER_MAPP" [...]

Exit 1 om något hittas, 0 om rent.

Varför felet uppstår
--------------------
Filerna blir korrekt UTF-8-kodade — det är inget encoding-fel. Orden skrivs fel
redan när scriptet som genererar filen författas. Kodassistenter bär en
instruktion i stil med "default to ASCII when editing or creating files", avsedd
för källkod, och övergeneraliserar den till innehållet. Beteendet är rapporterat
för tyska, turkiska och ett dussin andra språk (claude-code#14131, #12417).
Det går alltså inte att konfigurera bort — därför denna efterhandskontroll.

Hur detektionen fungerar
------------------------
Ingen handskriven lista över felstavningar. I stället en svensk ordlista och två
signaler:

1. ENTYDIGA ord — ASCII-formen finns inte i ordlistan, men en form med å/ä/ö
   insatt gör det. "sjalvkostnad" -> "självkostnad". Larmar alltid.

2. HELA FILEN — vissa translitterationer är riktiga ord: "manad" är perfekt
   particip av "mana", "saker" av "sak". De kan inte bedömas ord för ord. Men en
   svensk text där många ord HAR en diakritvariant medan noll tecken faktiskt är
   å/ä/ö är transliererad — det var så felet först upptäcktes ("36 celler borde
   ha å/ä/ö, noll har det").

Sammansättningar som "avgiftsutrymme" saknas i ordlistan men har inga
diakritvarianter heller, och passerar därför tyst.
"""
import html
import re
import sys
import zipfile
from itertools import product
from pathlib import Path

# Ordlistor i hunspell-format. LibreOffice installerar den svenska på Windows;
# hunspell-paketen på macOS/Linux lägger den under /usr/share.
ORDLISTOR = [
    r"C:\Program Files\LibreOffice\share\extensions\dict-sv\sv_SE.dic",
    r"C:\Program Files (x86)\LibreOffice\share\extensions\dict-sv\sv_SE.dic",
    "/usr/share/hunspell/sv_SE.dic",
    "/usr/share/myspell/sv_SE.dic",
    "/Library/Spelling/sv_SE.dic",
]

# Reservlista när ingen ordlista hittas. Bara ord som ENDAST existerar med
# diakrit — tvetydiga former ("stad", "har", "for", "andra") är uteslutna.
RESERV = """
manader manadskostnad manadsavgift manadsvis rakneexempel berakning beraknad
sjalvkostnad sjalvklart socialnamnden namnden atgard atgarder arende arenden
forslaget foreslagen ovriga mojlighet mojligheter hojning okning arligen
vardnad omvardnad sjukvard hemtjanst hemtjansten bistand bistandsbeslut
ersattning ersattningen utforare uppfoljning overenskommelse tidsattning
Goteborg Vasteras Malmo Ostersund Umea Vaxjo Orebro Linkoping
Jonkoping Gavle Boras Sodertalje Norrkoping Osteraker Harnosand
""".split()
RESERV_LAG = {o.lower() for o in RESERV}

ERSATTNINGAR = {"a": "aåä", "A": "AÅÄ", "o": "oö", "O": "OÖ"}
MAX_VOKALER = 6  # 3^6 varianter i värsta fall; längre ord blir för dyra

# Hunspell-ordlistan innehåller stammar, inte böjda former: "sak" finns men inte
# "saker". Utan suffixhantering blir varje plural ett falskt larm. Listan är
# ordnad längst först så att "ningen" prövas före "en".
SUFFIX = [
    "ningarna", "ningarnas", "ningarna", "ningar", "ningen", "nings", "ning",
    "arna", "arnas", "erna", "ernas", "orna", "ornas", "ande", "ende", "else",
    "aren", "arens", "erna", "arna", "aste", "ades", "ade", "are", "ast",
    "ens", "ets", "ers", "ars", "ors", "en", "et", "er", "ar", "or", "na",
    "as", "es", "ts", "at", "an", "a", "e", "n", "t", "s",
]

# Antal misstänkta ord som krävs innan en fil utan å/ä/ö bedöms transliererad.
# Under tröskeln ryms korta filer, engelsk text och rena sifferblad.
TROSKEL = 5

MOJIBAKE = re.compile(r"Ã[¥¤¶]|Â[\x80-\xbf]|\ufffd")
URL_EPOST = re.compile(
    r"\S+@\S+|\w+://\S+|\bwww\.\S+|\S+\.(?:se|com|nu|org|net|pdf|docx|xlsx|pptx)\b", re.I
)
ORD = re.compile(r"\b[A-Za-z][A-Za-z]{2,}\b")

XML_I_ZIP = {".xlsx": ("xl/",), ".docx": ("word/",), ".pptx": ("ppt/",)}


def las_ordlista():
    """Returnerar (ordset, källa). Tomt set om ingen ordlista finns."""
    for sokvag in ORDLISTOR:
        p = Path(sokvag)
        if not p.exists():
            continue
        ord_ = set()
        with p.open(encoding="utf-8", errors="replace") as f:
            next(f, None)  # första raden är antalet poster
            for rad in f:
                stam = rad.split("/", 1)[0].strip()
                if stam:
                    ord_.add(stam.lower())
        return ord_, str(p)
    return set(), None


def finns(ord_, ordlista):
    """Ordet, eller dess stam efter avskalat suffix, står i ordlistan.

    Approximerar hunspells affixexpansion, som ordlistan själv inte innehåller
    ("sak" finns, "saker" inte). Används GENERÖST — för att avgöra att ett ord
    är korrekt svenska och därmed ska lämnas i fred.
    """
    lag = ord_.lower()
    if lag in ordlista:
        return True
    for suffix in SUFFIX:
        if lag.endswith(suffix) and len(lag) - len(suffix) >= 3:
            stam = lag[: -len(suffix)]
            if stam in ordlista:
                return True
            # "flickor" -> "flick" -> "flicka": stammen kan behöva sin slutvokal.
            if stam + "a" in ordlista or stam + "e" in ordlista:
                return True
    return False


def finns_strikt(ord_, ordlista):
    """Exakt uppslag. Används för diakritVARIANTER.

    Måste vara strikt. Med suffixstrippning hittar nästan vilket ord som helst en
    "variant som finns" — "hade" -> "häde" -> stammen "häd" + a = "häda" — och
    detektorn dränks i falska larm. Uppmätt på verkliga projektfiler: 712 fynd
    med generös matchning, varav i princip alla felaktiga.
    """
    return ord_.lower() in ordlista


def diakritvarianter(ord_):
    """Alla former av ordet där a/o bytts mot å/ä/ö. Utan originalet."""
    platser = [i for i, c in enumerate(ord_) if c in ERSATTNINGAR]
    if not platser or len(platser) > MAX_VOKALER:
        return
    for kombination in product(*(ERSATTNINGAR[ord_[i]] for i in platser)):
        if all(ny == ord_[i] for i, ny in zip(platser, kombination)):
            continue  # originalet
        tecken = list(ord_)
        for i, ny in zip(platser, kombination):
            tecken[i] = ny
        yield "".join(tecken)


def texter(path):
    """Ger (plats, text) för varje textnod i Office-filen."""
    prefix = XML_I_ZIP[path.suffix.lower()]
    with zipfile.ZipFile(path) as z:
        for namn in z.namelist():
            if not namn.endswith(".xml") or not namn.startswith(prefix):
                continue
            if "/theme" in namn or namn.endswith("styles.xml"):
                continue
            xml = z.read(namn).decode("utf-8", errors="replace")
            # openpyxl och flera andra generatorer skriver å/ä/ö som XML-entiteter
            # (&#229;) i stället för råa tecken. Utan avkodning räknas de som noll
            # diakriter, och en korrekt fil kan då flaggas som transliererad.
            for m in re.finditer(r"<(?:a:t|w:t|t)(?:\s[^>]*)?>(.*?)</(?:a:t|w:t|t)>", xml, re.S):
                text = html.unescape(m.group(1))
                if text.strip():
                    yield namn, text
            # Fliknamn ligger i attribut, inte textnoder.
            if namn == "xl/workbook.xml":
                for m in re.finditer(r'<(?:sheet|definedName)[^>]*name="([^"]+)"', xml):
                    yield "FLIKNAMN", html.unescape(m.group(1))


def granska(path, ordlista):
    entydiga, tvetydiga, mojibake = [], set(), []
    antal_diakrittecken = 0
    antal_ord = 0

    for plats, text in texter(path):
        antal_diakrittecken += sum(text.count(c) for c in "åäöÅÄÖ")
        if MOJIBAKE.search(text):
            mojibake.append((plats, text.strip()[:90]))

        rensad = URL_EPOST.sub(lambda m: " " * len(m.group(0)), text)
        for m in ORD.finditer(rensad):
            ord_ = m.group(0)
            antal_ord += 1
            if not any(c in ERSATTNINGAR for c in ord_):
                continue

            if ordlista:
                if not any(finns_strikt(v, ordlista) for v in diakritvarianter(ord_)):
                    continue
                if finns(ord_, ordlista):
                    tvetydiga.add(ord_)  # t.ex. "manad", "saker" — kräver filkontext
                else:
                    entydiga.append((plats, ord_, text.strip()[:90]))
            elif ord_.lower() in RESERV_LAG:
                entydiga.append((plats, ord_, text.strip()[:90]))

    return {
        "entydiga": entydiga,
        "tvetydiga": tvetydiga,
        "mojibake": mojibake,
        "diakrittecken": antal_diakrittecken,
        "ord": antal_ord,
    }


def main(argv):
    # Utan detta skriver Windows-konsolen i CP850 och rapporten om saknade å/ä/ö
    # blir själv oläslig.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    if not argv:
        print(__doc__.split("\n\n")[0])
        print("\nAnvändning: python scripts/check_diakriter.py <fil eller mapp> ...")
        return 2

    ordlista, kalla = las_ordlista()
    if ordlista:
        print(f"Ordlista: {kalla} ({len(ordlista):,} ord)".replace(",", " "))
    else:
        print("Ingen svensk ordlista hittad — använder reservlista (sämre täckning).")
        print("Installera LibreOffice eller hunspell sv_SE för full kontroll.")

    filer = []
    for arg in argv:
        p = Path(arg)
        if p.is_dir():
            filer += [
                f for f in p.rglob("*")
                if f.suffix.lower() in XML_I_ZIP and not f.name.startswith("~$")
            ]
        elif p.suffix.lower() in XML_I_ZIP:
            filer.append(p)
        else:
            print(f"Hoppar över (stöds ej): {p}")

    if not filer:
        print("Inga .docx/.xlsx/.pptx att granska.")
        return 0

    fynd = 0
    for f in sorted(filer):
        try:
            r = granska(f, ordlista)
        except (zipfile.BadZipFile, KeyError, OSError) as e:
            print(f"Kunde inte läsa {f.name}: {e}")
            continue

        # Filnivån är den bärande signalen. Enstaka ord duger inte: svenskan är
        # full av minimala par ("for"/"för", "har"/"här", "vagen"/"vägen"), så
        # ordnivålarm ensamt ger mest brus. Men en svensk text där MÅNGA ord
        # kunde burit diakrit och INGET tecken gör det är transliererad — det var
        # så felet först upptäcktes: "36 celler borde ha å/ä/ö, noll har det".
        misstankta = len(r["entydiga"]) + len(r["tvetydiga"])
        transliererad = r["diakrittecken"] == 0 and misstankta >= TROSKEL

        if not transliererad and not r["mojibake"]:
            status = f"{r['diakrittecken']} tecken med å/ä/ö"
            if r["diakrittecken"] == 0 and misstankta:
                status += f", {misstankta} misstänkta ord (under tröskeln {TROSKEL})"
            print(f"OK  {f.name} — {status}")
            continue

        fynd += (1 if transliererad else 0) + len(r["mojibake"])
        print(f"\nFEL {f}")

        if transliererad:
            print(f"    Noll tecken med å/ä/ö i filen, men {misstankta} ord som borde ha det.")
            for plats, ord_, rad in r["entydiga"][:12]:
                forslag = next(
                    (v for v in diakritvarianter(ord_) if finns_strikt(v, ordlista)), None
                ) if ordlista else None
                pil = f" -> {forslag}" if forslag else ""
                print(f"    [{plats}] {ord_}{pil}   i: {rad}")
            if len(r["entydiga"]) > 12:
                print(f"    ... och {len(r['entydiga']) - 12} till")
            if not r["entydiga"] and r["tvetydiga"]:
                print(f"    Exempel: {', '.join(sorted(r['tvetydiga'])[:10])}")

        for plats, rad in r["mojibake"][:10]:
            print(f"    [{plats}] MOJIBAKE: {rad}")

    if fynd:
        print(f"\n{fynd} fynd. Skriv om texten med å/ä/ö och generera filen igen.")
        return 1

    print(f"\nRent — {len(filer)} fil(er) granskade.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
