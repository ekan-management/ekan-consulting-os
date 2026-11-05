# jobb.ps1 — Extraherar fas och ej avklarade uppgifter från alla projekt-CLAUDE.md
# Körs av /ekan:jobb via: powershell -NoProfile -ExecutionPolicy Bypass -File jobb.ps1

# Tvinga UTF-8 på stdout — annars skriver Windows PowerShell 5.1 i konsolens
# kodsida (CP850/CP437) och projektnamn med å/ä/ö kommer ut som mojibake.
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# Rubriker vars punktlistor räknas som öppna uppgifter även utan kryssruta.
# Projekt som skriver sina to-dos i prosa under "## Öppet" syns annars inte alls.
$openHeading = '^#{2,3}\s*(Öppet|Öppna frågor|Öppna punkter|Att göra|Nästa steg|To-?do)\b'

# Underrubriker som stänger en pågående öppet-sektion även om de ligger djupare
# än rubriken som öppnade den, t.ex. "### Avgjort 22 september" under "## Öppet".
# Utan detta sveps avklarade underavsnitt in som öppna uppgifter.
$closedHeading = '^#{1,6}\s*(Avgjort|Avklarat|Löst|Klart|Genomfört|Beslutat|Stängt|Arkiverat)\b'

function Limit-Line($text, $max = 180) {
    $t = $text.Trim()
    if ($t.Length -gt $max) { return $t.Substring(0, $max).TrimEnd() + '…' }
    return $t
}

$base = Join-Path $env:USERPROFILE "consulting\projects"
$files = Get-ChildItem $base -Filter "CLAUDE.md" -Recurse -Depth 1 -ErrorAction SilentlyContinue

foreach ($file in $files) {
    $proj = $file.Directory.Name
    $lines = Get-Content $file.FullName -Encoding UTF8

    $fas = $null
    $todos = @()          # rader med kryssruta
    $openItems = @()      # punkter under en öppet-rubrik
    $openSection = $null  # rubriken de kom ur
    $inOpen = $false
    $openLevel = 0        # rubriknivån som öppnade avsnittet

    foreach ($line in $lines) {
        if (-not $fas -and $line -match '\*\*Fas:\*\*|^Fas:') { $fas = $line.Trim() }

        if ($line -match '^(#{1,6})\s') {
            $level = $Matches[1].Length
            # Underrubriker hör till öppet-avsnittet, t.ex. "### Frågor som väntar på svar"
            # under "## Öppet". Först en rubrik på samma eller högre nivå avslutar det —
            # om den inte själv är en avslutsrubrik (se $closedHeading ovan).
            if ($inOpen -and $level -gt $openLevel) {
                if ($line -match $closedHeading) { $inOpen = $false }
                continue
            }
            $inOpen = $line -match $openHeading
            if ($inOpen) {
                $openLevel = $level
                if (-not $openSection) { $openSection = $line.Trim() }
            }
            continue
        }

        if ($line -match '^- \[ \]') { $todos += $line.TrimEnd(); continue }
        # Rader som redan har kryssruta hanteras ovan; [x] och [~] är avklarade/skippade
        if ($inOpen -and $line -match '^[-*]\s+\S' -and $line -notmatch '^[-*]\s*\[.\]') { $openItems += (Limit-Line $line.Substring(1)) }
    }

    if ($todos.Count -or $openItems.Count) {
        Write-Host ("=== " + $proj + " ===")
        if ($fas) { Write-Host $fas }
        foreach ($t in $todos) { Write-Host $t }
        if ($openItems.Count) {
            Write-Host ("(ur " + $openSection + ")")
            foreach ($o in $openItems) { Write-Host ("- [ ] " + $o) }
        }
        Write-Host ""
    }
}
