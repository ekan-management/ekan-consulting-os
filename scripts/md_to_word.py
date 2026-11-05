"""Konverterar markdown till Word med Ekans referensmall.

Användning:
    python md_to_word.py input.md output.docx [--mall MALLNAMN]

Standardmall: Mall anteckningar.docx
Tillgängliga mallar: alla .docx i templates/
"""

import shutil
import subprocess
import sys
from pathlib import Path

TEMPLATES_DIR = Path(__file__).parent.parent / "templates"
DEFAULT_TEMPLATE = "Mall anteckningar.docx"


def convert(input_md: str, output_docx: str, template: str = DEFAULT_TEMPLATE):
    if not Path(input_md).exists():
        print(f"Fel: Indatafil '{input_md}' finns inte.", file=sys.stderr)
        sys.exit(1)

    if shutil.which("pandoc") is None:
        print("Fel: pandoc är inte installerat. Kör: winget install pandoc", file=sys.stderr)
        sys.exit(1)

    if not TEMPLATES_DIR.exists():
        print(f"Fel: templates-mapp saknas på {TEMPLATES_DIR}", file=sys.stderr)
        sys.exit(1)

    template_path = TEMPLATES_DIR / template
    if not template_path.exists():
        print(f"Fel: Mall '{template}' finns inte i {TEMPLATES_DIR}", file=sys.stderr)
        print("Tillgängliga mallar:", file=sys.stderr)
        for f in sorted(TEMPLATES_DIR.glob("*.docx")):
            print(f"  - {f.name}", file=sys.stderr)
        sys.exit(1)

    cmd = [
        "pandoc",
        input_md,
        "-o", output_docx,
        "--reference-doc", str(template_path),
    ]

    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        print(f"Fel vid konvertering: {result.stderr}", file=sys.stderr)
        sys.exit(1)

    print(f"Skapat: {output_docx}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    template = DEFAULT_TEMPLATE

    if "--mall" in sys.argv:
        idx = sys.argv.index("--mall")
        if idx + 1 < len(sys.argv):
            template = sys.argv[idx + 1]

    convert(input_file, output_file, template)
