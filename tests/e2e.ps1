# e2e.ps1 — kör hela konsultflödet mot en isolerad hemkatalog.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\e2e.ps1
#   pwsh       -NoProfile -ExecutionPolicy Bypass -File tests\e2e.ps1
#
# Skillnad mot smoke.ps1: smoketestet kontrollerar att delarna finns och svarar.
# Det här går igenom vad en konsult faktiskt gör — installera, starta projekt,
# se sin to-do — och kontrollerar utfallet i varje steg. Rapporten är skriven
# för att kunna läsas av någon som inte granskar koden.
#
# Rör aldrig den riktiga profilen: allt sker under en temp-rot som städas efter.

param([string]$PluginDir = (Resolve-Path "$PSScriptRoot\..").Path)

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$ErrorActionPreference = 'Continue'

$vard = (Get-Process -Id $PID).Path
$sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("ekan-e2e-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
$resultat = @()

function Kontroll {
    param([string]$Steg, [string]$Forvantat, [bool]$Utfall, [string]$Detalj = "")
    $script:resultat += [PSCustomObject]@{
        Steg = $Steg; Forvantat = $Forvantat; Ok = $Utfall; Detalj = $Detalj
    }
    $ikon = if ($Utfall) { "OK  " } else { "FEL " }
    $farg = if ($Utfall) { "Green" } else { "Red" }
    Write-Host ("  {0} {1}" -f $ikon, $Forvantat) -ForegroundColor $farg
    if ($Detalj) { Write-Host "       $Detalj" -ForegroundColor DarkGray }
}

function Kor-Setup {
    # -TestMode hoppar avsiktligt över bekräftelsen så testsviten kan köra utan
    # input. För att pröva själva spärren måste den alltså vara AV — då används
    # -Interaktiv, som i stället matar tom stdin och därmed härmar hur skriptet
    # anropas av Bash-verktyget (ingen konsol att svara i).
    param([switch]$MedYes, [switch]$Interaktiv)
    $argument = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
        (Join-Path $PluginDir "hooks\ekan-setup.ps1"),
        "-UserHome", $sandbox, "-PluginRoot", $PluginDir, "-SkipPython"
    )
    if (-not $Interaktiv) { $argument += "-TestMode" }
    if ($MedYes) { $argument += "-Yes" }

    if ($Interaktiv) { return ("" | & $vard @argument 2>&1 | Out-String) }
    & $vard @argument 2>&1 | Out-String
}

Write-Host ""
Write-Host "Testar hela konsultflödet i en sandlåda" -ForegroundColor Cyan
Write-Host "Värd: PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray
Write-Host "Sandlåda: $sandbox" -ForegroundColor DarkGray
Write-Host ""

try {
    New-Item -ItemType Directory -Path $sandbox -Force | Out-Null

    # --- 1. Ny konsult installerar för första gången ----------------------
    Write-Host "1. Ny konsult kör /ekan:setup på en ren dator" -ForegroundColor Yellow
    $ut = Kor-Setup

    $consultingDir = Join-Path $sandbox "consulting"
    Kontroll "install" "Arbetsmappen ~/consulting skapas" (Test-Path $consultingDir)
    Kontroll "install" "Ekans standardinstruktioner (CLAUDE.md) läggs på plats" `
        (Test-Path (Join-Path $consultingDir "CLAUDE.md"))
    Kontroll "install" "Personlig MY-CLAUDE.md skapas från mall" `
        (Test-Path (Join-Path $consultingDir "MY-CLAUDE.md"))

    $mallDir = Join-Path $consultingDir "templates"
    Kontroll "install" "Mallmappen ~/consulting/templates skapas" (Test-Path $mallDir)
    Kontroll "install" "Setup listar mallarna konsulten själv ska lägga dit" `
        ("$ut" -match 'Mall Projektdirektiv\.docx')

    # Konsulten lägger in en mall, så att kopieringen till projektet kan provas.
    Set-Content -Path (Join-Path $mallDir "Mall anteckningar.docx") -Value "testmall"

    $skript = @(Get-ChildItem (Join-Path $consultingDir "scripts") -Filter *.py -ErrorAction SilentlyContinue)
    Kontroll "install" "Hjälpskripten installeras (CLAUDE.md hänvisar till dem)" ($skript.Count -gt 0) `
        "$($skript.Count) skript: $($skript.Name -join ', ')"

    foreach ($d in @("projects", "tmp", "arkiv")) {
        Kontroll "install" "Undermappen $d finns" (Test-Path (Join-Path $consultingDir $d))
    }

    $settings = Join-Path $sandbox ".claude\settings.json"
    if (Test-Path $settings) {
        $s = Get-Content $settings -Raw | ConvertFrom-Json
        Kontroll "install" "Ekans permissions skrivs till settings.json" ([bool]$s.permissions.allow)
        Kontroll "install" "Inga dubbla hooks skrivs in (pluginet äger dem)" (-not [bool]$s.hooks)
    } else {
        Kontroll "install" "settings.json skapas" $false "filen saknas"
    }

    # --- 2. Konsulten startar ett projekt med svenska tecken -------------
    Write-Host ""
    Write-Host "2. Konsulten startar ett nytt uppdrag" -ForegroundColor Yellow
    $projektnamn = "Exempelstaden HR-ärenden och åtgärder — förstudie"
    $gammalProfil = $env:USERPROFILE
    $env:USERPROFILE = $sandbox
    try {
        $utProj = & $vard -NoProfile -ExecutionPolicy Bypass `
            -File (Join-Path $PluginDir "hooks\nytt-projekt.ps1") -Namn $projektnamn 2>&1 | Out-String

        $projektDir = Join-Path $consultingDir "projects\$projektnamn"
        Kontroll "projekt" "Projektmappen skapas med å/ä/ö bevarade" (Test-Path $projektDir) $projektnamn

        $undermappar = @(Get-ChildItem $projektDir -Directory -ErrorAction SilentlyContinue)
        Kontroll "projekt" "Standardstrukturen skapas" ($undermappar.Count -ge 6) "$($undermappar.Count) mappar"

        $motesmapp = $undermappar | Where-Object { $_.Name -match 'Möten' }
        Kontroll "projekt" "Mappnamn med å/ä/ö blir rätt (20 Möten)" ([bool]$motesmapp) `
            $(if ($motesmapp) { $motesmapp.Name } else { ($undermappar.Name -join ', ') })

        $projektMallar = @(Get-ChildItem (Join-Path $projektDir "80 Mallar kompassen") -File -ErrorAction SilentlyContinue)
        Kontroll "projekt" "Mallarna kopieras in i projektet" ($projektMallar.Count -gt 0) `
            "$($projektMallar.Count) mallar i '80 Mallar kompassen'"

        Kontroll "projekt" "Projektets CLAUDE.md skapas" (Test-Path (Join-Path $projektDir "CLAUDE.md"))

        # --- 3. Konsulten frågar efter sin to-do -------------------------
        Write-Host ""
        Write-Host "3. Konsulten kör /ekan:jobb" -ForegroundColor Yellow
        $utJobb = & $vard -NoProfile -ExecutionPolicy Bypass `
            -File (Join-Path $PluginDir "hooks\jobb.ps1") 2>&1 | Out-String

        Kontroll "jobb" "Projektet syns i to-do-listan" ($utJobb -match [regex]::Escape($projektnamn))
        Kontroll "jobb" "Svenska tecken visas rätt i utskriften" ($utJobb -match 'Uppstartsmöte|Möten|å|ä|ö') `
            ($utJobb.Trim() -split "`n" | Select-Object -First 1)
        $trasigaTecken = $utJobb.ToCharArray() | Where-Object { [int]$_ -ge 128 -and [int]$_ -lt 160 }
        Kontroll "jobb" "Inga förvanskade tecken i utskriften" (-not $trasigaTecken) `
            $(if ($trasigaTecken) { "hittade $($trasigaTecken.Count) tecken i mojibake-intervallet" } else { "" })

        # --- 4. Sessionsstart --------------------------------------------
        Write-Host ""
        Write-Host "4. Konsulten startar Claude Code" -ForegroundColor Yellow
        $env:CLAUDE_PLUGIN_ROOT = $PluginDir
        $utSession = & $vard -NoProfile -ExecutionPolicy Bypass `
            -File (Join-Path $PluginDir "hooks\session-start.ps1") 2>&1 | Out-String

        $giltigJson = $false
        $parsed = $null
        try { $parsed = $utSession | ConvertFrom-Json; $giltigJson = $true } catch { }
        Kontroll "session" "Sessionsstart svarar med giltig data" $giltigJson
        if ($giltigJson) {
            # Sedan 3.9.3 ligger additionalContext i hookSpecificOutput.
            $ctx = $parsed.hookSpecificOutput.additionalContext
            Kontroll "session" "Kommandolistan visas vid start" ($ctx -match '/ekan:')
            Kontroll "session" "Aktiva projekt listas" ($ctx -match [regex]::Escape($projektnamn))
        }

        # --- 5. CLAUDE.md-synk vid ny version -----------------------------
        Write-Host ""
        Write-Host "5. Pluginet uppdateras — synkas standardinstruktionerna?" -ForegroundColor Yellow
        Set-Content -Path (Join-Path $consultingDir "CLAUDE.md") -Value "INAKTUELL VERSION" -Encoding UTF8
        & $vard -NoProfile -ExecutionPolicy Bypass `
            -File (Join-Path $PluginDir "hooks\session-start.ps1") 2>&1 | Out-Null

        $eftersynk = Get-Content (Join-Path $consultingDir "CLAUDE.md") -Raw
        Kontroll "synk" "CLAUDE.md uppdateras automatiskt när den ändrats" `
            ($eftersynk -notmatch 'INAKTUELL VERSION')
        Kontroll "synk" "Föregående version sparas som säkerhetskopia" `
            (Test-Path (Join-Path $consultingDir "CLAUDE.md.bak"))
    }
    finally {
        $env:USERPROFILE = $gammalProfil
        Remove-Item Env:\CLAUDE_PLUGIN_ROOT -ErrorAction SilentlyContinue
    }

    # --- 6. Migrering från den gamla installationen ----------------------
    Write-Host ""
    Write-Host "6. Konsult med gammal installation migrerar" -ForegroundColor Yellow
    $claudeDir = Join-Path $sandbox ".claude"
    New-Item -ItemType Directory -Path (Join-Path $claudeDir "hooks") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $claudeDir "commands") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $claudeDir "skills\nytt-projekt") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $claudeDir "skills\intro") -Force | Out-Null

    Set-Content (Join-Path $claudeDir "hooks\jobb.ps1") "# gammal" -Encoding UTF8
    Set-Content (Join-Path $claudeDir "hooks\nytt-projekt.ps1") "# gammal" -Encoding UTF8
    Set-Content (Join-Path $claudeDir "commands\jobb.md") "# gammal" -Encoding UTF8
    Set-Content (Join-Path $claudeDir "commands\setup.md") "# gammal" -Encoding UTF8
    Set-Content (Join-Path $claudeDir "skills\nytt-projekt\SKILL.md") "# gammal skill" -Encoding UTF8
    Set-Content (Join-Path $claudeDir "skills\intro\SKILL.md") "# gammal skill" -Encoding UTF8

    # Utan bekräftelse ska ingenting raderas. Detta är spärren som tidigare
    # brast: Read-Host gav en tom kollektion och villkoret utvärderades falsy,
    # så raderingen kördes ändå.
    $utUtanJa = Kor-Setup -Interaktiv
    Kontroll "migrering" "Utan bekräftelse raderas ingenting" `
        (Test-Path (Join-Path $claudeDir "skills\nytt-projekt\SKILL.md")) `
        "spärren som brast före 3.0.0"

    # Med bekräftelse ska allt gammalt bort.
    $utMedJa = Kor-Setup -MedYes
    $kvar = @()
    foreach ($p in @(
        "hooks\jobb.ps1", "hooks\nytt-projekt.ps1",
        "commands\jobb.md", "commands\setup.md",
        "skills\nytt-projekt", "skills\intro"
    )) {
        if (Test-Path (Join-Path $claudeDir $p)) { $kvar += $p }
    }
    Kontroll "migrering" "Efter bekräftelse städas allt gammalt bort" ($kvar.Count -eq 0) `
        $(if ($kvar.Count) { "kvar: $($kvar -join ', ')" } else { "inget kvar" })
    Kontroll "migrering" "Konsultens eget arbete i ~/consulting rörs inte" `
        (Test-Path (Join-Path $consultingDir "projects\$projektnamn\CLAUDE.md"))
}
finally {
    Remove-Item $sandbox -Recurse -Force -ErrorAction SilentlyContinue
}

# --- Sammanfattning ------------------------------------------------------
$fel = @($resultat | Where-Object { -not $_.Ok })
Write-Host ""
Write-Host ("=" * 60)
if ($fel.Count -eq 0) {
    Write-Host "ALLT FUNGERAR — $($resultat.Count) kontroller, inga fel" -ForegroundColor Green
} else {
    Write-Host "$($fel.Count) av $($resultat.Count) kontroller MISSLYCKADES:" -ForegroundColor Red
    foreach ($f in $fel) { Write-Host "  - [$($f.Steg)] $($f.Forvantat)  $($f.Detalj)" -ForegroundColor Red }
}
Write-Host ("=" * 60)
Write-Host ""

exit $(if ($fel.Count -eq 0) { 0 } else { 1 })
