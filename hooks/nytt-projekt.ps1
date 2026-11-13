# nytt-projekt.ps1
# Skapar ny projektmapp med Ekans standardstruktur.
# Användning: nytt-projekt.ps1 -Namn "kundnamn-uppdragsnamn"

param(
    [Parameter(Mandatory=$true)]
    [AllowEmptyString()]
    [string]$Namn
)

# Tvinga UTF-8 på stdout — annars skriver Windows PowerShell 5.1 i konsolens
# kodsida (CP850/CP437) och mappnamn med å/ä/ö kommer ut som mojibake.
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# Validera namnet före vi bygger någon sökväg.
# Tomt/blanksteg ger annars ett kryptiskt parameter-bindningsfel; separatorer eller
# ".." skulle låta New-Item skapa mappar utanför den avsedda projektkatalogen.
if ([string]::IsNullOrWhiteSpace($Namn)) {
    Write-Error "Ange ett projektnamn: nytt-projekt -Namn `"kund-uppdrag`""
    exit 1
}
if ($Namn -match '[\\/]' -or $Namn -match '\.\.' -or $Namn.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
    Write-Error "Ogiltigt projektnamn '$Namn': använd ett enkelt mappnamn utan sökvägstecken (\ / ..) eller otillåtna tecken."
    exit 1
}

$base = Join-Path $env:USERPROFILE "consulting\projects"
$projektPath = Join-Path $base $Namn

# Kontrollera att baskatalogen finns
if (-not (Test-Path $base)) {
    Write-Error "Baskatalog saknas: $base"
    exit 1
}

# Kontrollera att projektet inte redan finns
if (Test-Path $projektPath) {
    Write-Error "Projekt '$Namn' finns redan: $projektPath"
    exit 1
}

# Skapa mappar
$mappar = @(
    "10 Dokument under arbete",
    "20 Möten",
    "40 Bakgrundsmaterial",
    "50 Styrande dokument",
    "60 Leveranser",
    "70 Projektsammanfattning",
    "80 Mallar kompassen"
)

# Skapa hela trädet i ett försök. -ErrorAction Stop gör fil-operationerna
# terminerande så catch-blocket fångar dem; vid fel städas en halvskapad mapp
# bort så att en omkörning blir ren (annars blockerar "finns redan"-vakten ovan).
try {
    New-Item -ItemType Directory -Path $projektPath -ErrorAction Stop | Out-Null
    foreach ($mapp in $mappar) {
        New-Item -ItemType Directory -Path (Join-Path $projektPath $mapp) -ErrorAction Stop | Out-Null
    }

    # Kopiera Ekan-mallar till 80
    # Mallmappen sätts på ett ställe, EKAN_MALLAR i ~/.claude/settings.json
    # (skrivs av /ekan:setup -Mallmapp). Saknas den gäller ~/consulting/templates.
    $templatePath = if ($env:EKAN_MALLAR) { $env:EKAN_MALLAR } else { Join-Path $env:USERPROFILE "consulting\templates" }
    $mapp80 = Join-Path $projektPath "80 Mallar kompassen"
    if (Test-Path $templatePath) {
        # Bara Office-filer: ett synkat SharePoint-bibliotek kan innehålla annat.
        Get-ChildItem $templatePath -File |
            Where-Object { $_.Extension -in '.docx', '.dotx', '.xlsx', '.xltx', '.pptx', '.potx' } |
            Copy-Item -Destination $mapp80 -ErrorAction Stop
    } else {
        Write-Warning "Mallkatalog saknas: $templatePath — inga mallar kopierade."
    }

    # Hämta dagens datum
    $datum = Get-Date -Format "yyyy-MM-dd"

    # Skapa CLAUDE.md
    $claudeContent = @"
# $Namn


## Uppdrag

| | |
|---|---|
| **Kund** | |
| **Beställare** | |
| **Period** | |
| **Budget** | |
| **Status** | Uppstart |
| **Syfte** | |

## Team

**Konsultteam (Ekan):**

| Namn | Roll | Ansvar |
|------|------|--------|
| | | |

**Kund:**
- (Att fylla i efter uppstartsmöte)

## Status

**Fas:** Uppstart
**Senast uppdaterad:** $datum

## To-do

### Fas 0: Uppstart

- [ ] Projektdirektiv (/projektdirektiv)
- [ ] Uppstartsmöte med kund

## Källdokument

- ``40 Bakgrundsmaterial/`` — material från kund och referensunderlag
- ``50 Styrande dokument/`` — PD, tidsplan, avtal

## Omfång

Den här filen läses i sin helhet vid varje sessionsstart. Håll den vid aktuell ram.
Avklarade punkter, avslutade faser och ersatta beslut flyttas till ``CLAUDE-historik.md``.
Källsammanfattningar och domänkunskap läggs under ``underlag/`` och pekas ut härifrån.
Se avsnitt 3.5 i Ekan-standarden.
"@

    $claudePath = Join-Path $projektPath "CLAUDE.md"
    [System.IO.File]::WriteAllText($claudePath, $claudeContent, [System.Text.UTF8Encoding]::new($false))
}
catch {
    if (Test-Path $projektPath) { Remove-Item $projektPath -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Error "Kunde inte skapa projektet '$Namn': $($_.Exception.Message)"
    exit 1
}

Write-Host "Projekt skapat: $projektPath"
Write-Host ""
Write-Host "Mappar:"
foreach ($mapp in $mappar) {
    Write-Host "  $mapp"
}
# Nästa steg-vägledningen ägs av skills/nytt-projekt/SKILL.md — skriptets enda konsument.
