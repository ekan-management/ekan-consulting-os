"""Konverterar Office-filer (.docx, .pptx, .xlsx) och .pdf till markdown via markitdown.

Användning:
    python scripts/read_office.py "FILSÖKVÄG"

Output går till stdout som UTF-8 så svenska tecken bevaras vid pipe/redirect.
Använd Windows-sökvägar (C:/...), inte Unix-stil (/c/...).
"""

import io
import sys
from pathlib import Path


def main(argv: list[str]) -> int:
    if hasattr(sys.stdout, "buffer"):
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    if hasattr(sys.stderr, "buffer"):
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

    if len(argv) != 2:
        print("Användning: python scripts/read_office.py FILSÖKVÄG", file=sys.stderr)
        return 2

    path = Path(argv[1])
    if not path.exists():
        print(f"Fel: filen '{path}' finns inte.", file=sys.stderr)
        return 1

    try:
        from markitdown import MarkItDown
    except ImportError:
        print("Fel: markitdown saknas. Kör: pip install markitdown", file=sys.stderr)
        return 1

    md = MarkItDown()
    try:
        result = md.convert(str(path))
    except Exception as exc:
        print(f"Fel: markitdown kunde inte konvertera filen: {exc}", file=sys.stderr)
        return 1

    text = result.text_content or ""
    if not text.strip():
        print(f"Varning: ingen text extraherad från '{path}'.", file=sys.stderr)
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
