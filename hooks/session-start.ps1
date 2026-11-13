# session-start.ps1
# Injicerar projektnamn + slash-kommando-baner för plugin-kontext.

# Tvinga UTF-8 på stdout — annars blir emoji/åäö mojibake under Windows PowerShell 5.1
# (som hooks.json startar via `powershell`). Filen sparas med UTF-8 BOM så att 5.1
# även tolkar källans icke-ASCII-literaler korrekt vid inläsning.
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# --- Update-detektion: notis om VERSION ändrats sedan förra sessionen ---
# Notisen går aldrig via Write-Host — allt på stdout måste vara ETT JSON-objekt,
# annars kan Claude Code inte parsa hooken (buggen visade sig exakt den session
# då pluginet just uppdaterats). Den levereras därför i två fält i samma objekt:
# hookSpecificOutput.additionalContext till modellen, systemMessage till
# konsultens skärm. Desktop-appen har inte visat systemMessage i något test
# (9 okt 2026), så det är Claude som för fram notisen i sitt första svar.
#
# Notisen säger vad som är nytt i klarspråk: punkterna under "### För
# konsulten" i CHANGELOG.md för varje version konsulten hoppat över, plus nya
# skills och kommandon som ingen punkt nämner. version.Tests.ps1 stoppar en
# release utan sådana punkter.
#
# Notisen visas i varje ny session under 24 timmar efter att uppdateringen
# upptäcktes, inte bara i den första. Fram till 3.10.0 markerades versionen
# som sedd i första sessionsstarten, och den 9 okt 2026 var det en vilande
# session som appen återupptog i bakgrunden: notisen förbrukades utan att
# någon såg den. Återupptagna sessioner (source "resume") och komprimering
# varken upptäcker en ny version eller visar notisen.
$pluginRoot = $env:CLAUDE_PLUGIN_ROOT
if (-not $pluginRoot) { $pluginRoot = Split-Path $PSScriptRoot -Parent }
$versionFile = Join-Path $pluginRoot "VERSION"
$stateFile = Join-Path $env:USERPROFILE ".claude\.ekan-last-version"
$skillStateFile = Join-Path $env:USERPROFILE ".claude\.ekan-last-skills"
$changelogFile = Join-Path $pluginRoot "CHANGELOG.md"
$updateNote = $null
# Rader som ska nå konsultens skärm, inte bara modellens kontext.
$userNotes = @()

function Get-KlarsprakRader {
    # Punkterna under "### För konsulten" för versioner efter $Fran till och med
    # $Till, nyaste först. En punkt som fortsätter på indragna rader slås ihop.
    param([string]$Path, [string]$Fran, [string]$Till)
    $rader = @()
    if (-not (Test-Path $Path)) { return $rader }
    try { $franV = [version]$Fran; $tillV = [version]$Till } catch { return $rader }
    $iVersion = $false
    $iAvsnitt = $false
    # -Encoding UTF8: Windows PowerShell 5.1 läser annars filen som ANSI.
    foreach ($rad in (Get-Content $Path -Encoding UTF8)) {
        if ($rad -match '^## (\d+\.\d+\.\d+)') {
            $v = [version]$Matches[1]
            $iVersion = ($v -gt $franV) -and ($v -le $tillV)
            $iAvsnitt = $false
        }
        elseif ($rad -match '^#') {
            $iAvsnitt = $iVersion -and ($rad -match '^### För konsulten\s*$')
        }
        elseif ($iAvsnitt -and $rad -match '^- (.+)$') {
            $rader += $Matches[1].Trim()
        }
        elseif ($iAvsnitt -and $rad -match '^\s+(\S.*)$' -and $rader.Count -gt 0) {
            $rader[$rader.Count - 1] += " " + $Matches[1].Trim()
        }
    }
    return $rader
}

function Get-SkillNamn {
    # Skills (skills/<namn>/SKILL.md) och kommandon (commands/<namn>.md) i en
    # pluginversion. Båda anropas som /ekan:<namn>.
    param([string]$Rot)
    $namn = @()
    $namn += @(Get-ChildItem -Path (Join-Path $Rot "skills") -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } |
        ForEach-Object { $_.Name })
    $namn += @(Get-ChildItem -Path (Join-Path $Rot "commands") -Filter "*.md" -File -ErrorAction SilentlyContinue |
        ForEach-Object { $_.BaseName })
    return @($namn | Sort-Object -Unique)
}

function Format-Notis {
    # Notisen till modellen och skärmen, ur en sparad notis.
    param([string]$Fran, [string]$Till, [string[]]$Nyheter)
    if ($Nyheter.Count -gt 0) {
        $max = 10
        $lista = @()
        for ($i = 0; $i -lt [Math]::Min($Nyheter.Count, $max); $i++) { $lista += "$($i + 1). $($Nyheter[$i])" }
        if ($Nyheter.Count -gt $max) { $lista += "Och $($Nyheter.Count - $max) ändringar till. Fråga Claude om du vill se dem." }
        $listText = $lista -join "`n"
        return @{
            Modell = "Ekan-plugin uppdaterad: $Fran -> $Till. Börja ditt första svar med listan nedan, ordagrant, under rubriken `"Ekan-pluginet är uppdaterat. Det här är nytt:`". Lägg inte till tekniska förklaringar. Frågar användaren varför något ändrats står bakgrunden i $changelogFile.`n$listText"
            Skarm  = "Ekan-plugin uppdaterad: $Fran -> $Till. Det här är nytt:`n$listText"
        }
    }
    return @{
        Modell = "Ekan-plugin uppdaterad: $Fran -> $Till. Nämn detta kort för användaren."
        Skarm  = "Ekan-plugin uppdaterad: $Fran -> $Till."
    }
}

# Claude Code skickar hookens indata som JSON på stdin, med source = startup,
# resume, clear eller compact. Saknas indata räknas starten som en ny session.
$kalla = "startup"
try {
    $indata = (@($input) -join "`n").Trim()
    if ($indata) {
        $hookIndata = $indata | ConvertFrom-Json
        if ($hookIndata.source) { $kalla = [string]$hookIndata.source }
    }
}
catch { }
$nySession = $kalla -in @("startup", "clear")

$noticeFile = Join-Path $env:USERPROFILE ".claude\.ekan-update-notice.json"
$notisTimmar = 24

$aktuellaSkills = @(Get-SkillNamn $pluginRoot)

# Tillståndsfilerna ligger i ~/.claude. Saknas mappen skrev Set-Content tre fel
# på stderr vid varje sessionsstart.
$claudeDir = Join-Path $env:USERPROFILE ".claude"
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }

$currentVersion = $null
if (Test-Path $versionFile) {
    $currentVersion = (Get-Content $versionFile -ErrorAction SilentlyContinue | Select-Object -First 1).Trim()
}

if ($currentVersion -and $nySession) {
    $lastSeen = if (Test-Path $stateFile) { (Get-Content $stateFile -ErrorAction SilentlyContinue | Select-Object -First 1).Trim() } else { $null }

    if ($currentVersion -ne $lastSeen) {
        if ($lastSeen) {
            $nyheter = @(Get-KlarsprakRader -Path $changelogFile -Fran $lastSeen -Till $currentVersion)

            # Förra versionens skills: den sparade listan, annars förra versionens
            # mapp i plugincachen. Finns ingen av dem nämns inga skills, hellre
            # än att alla ser nya ut.
            $forraSkills = $null
            if (Test-Path $skillStateFile) {
                $forraSkills = @(Get-Content $skillStateFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            }
            else {
                $forraRot = Join-Path (Split-Path $pluginRoot -Parent) $lastSeen
                if (Test-Path $forraRot) { $forraSkills = @(Get-SkillNamn $forraRot) }
            }
            if ($null -ne $forraSkills) {
                $namnda = $nyheter -join "`n"
                foreach ($skill in $aktuellaSkills) {
                    $omnamnd = $namnda -match ([regex]::Escape("/ekan:$skill") + '(?![\w-])')
                    if ($forraSkills -notcontains $skill -and -not $omnamnd) { $nyheter += "Ny skill: /ekan:$skill" }
                }
            }

            # Notisen sparas med upptäcktstid och visas sedan under $notisTimmar.
            $notis = @{
                fran      = $lastSeen
                till      = $currentVersion
                upptackt  = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
                nyheter   = @($nyheter)
            }
            Set-Content -Path $noticeFile -Value ($notis | ConvertTo-Json -Compress) -Encoding utf8
        }
        Set-Content -Path $stateFile -Value $currentVersion -Encoding utf8
        if ($aktuellaSkills.Count -gt 0) { Set-Content -Path $skillStateFile -Value $aktuellaSkills -Encoding utf8 }
    }
}

# Visa notisen i nya sessioner så länge den gäller den installerade versionen
# och är yngre än $notisTimmar.
if ($currentVersion -and $nySession -and (Test-Path $noticeFile)) {
    try {
        $sparad = Get-Content $noticeFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $alderTimmar = ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - [long]$sparad.upptackt) / 3600
        if ($sparad.till -eq $currentVersion -and $alderTimmar -ge 0 -and $alderTimmar -lt $notisTimmar) {
            $sparadeNyheter = @($sparad.nyheter | Where-Object { $_ } | ForEach-Object { [string]$_ })
            $text = Format-Notis -Fran $sparad.fran -Till $sparad.till -Nyheter $sparadeNyheter
            $updateNote = $text.Modell
            $userNotes += $text.Skarm
        }
    }
    catch {
        # En trasig notisfil får aldrig fälla sessionsstarten.
    }
}

# Listan behövs vid nästa uppdatering. Saknas den, till exempel första sessionen
# efter att funktionen kom in, skapas den nu.
if (-not (Test-Path $skillStateFile) -and $aktuellaSkills.Count -gt 0) {
    Set-Content -Path $skillStateFile -Value $aktuellaSkills -Encoding utf8
}

$context = @()

# --- Ekan-baner: synliggör slash-kommandon ---
$context += "🧭 Ekan-plugin aktiv. Kommandon: /ekan:intro, /ekan:jobb, /ekan:nytt-projekt, /ekan:projektdirektiv, /ekan:setup."

if ($updateNote) { $context += $updateNote }

# --- Ramverkssynk: håll ~/consulting i takt med pluginet ---
# Synkar en manifestlista, inte bara CLAUDE.md. Skälet: CLAUDE.md hänvisar till
# scripts/ och ROADMAP.md med relativa sökvägar från ~/consulting/. Bärs bara
# CLAUDE.md med, hamnar dokumentationen i takt med pluginet medan verktygen den
# pekar på ligger kvar i en äldre version. Då blir en hård regel oföljbar: så
# gick det när check_swedish_chars.py bytte namn till check_diakriter.py i
# §2.1, och read_office.py saknades helt hos konsulter som installerat före 3.1.
#
# Synkas bara om ~/consulting finns — annars har /ekan:setup aldrig körts och en
# ensam CLAUDE.md vore en halv install. Saknas en källa hoppas den posten över
# tyst. Inget raderas: konsultens egna script i samma mapp rörs aldrig.
function Sync-RamverksFil {
    param([string]$Source, [string]$Dest)
    # Returnerar $true bara när filen faktiskt skrevs.
    if (-not (Test-Path $Source)) { return $false }
    if (Test-Path $Dest) {
        $srcHash = (Get-FileHash $Source -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash $Dest -Algorithm SHA256).Hash
        if ($srcHash -eq $dstHash) { return $false }
        Copy-Item $Dest "$Dest.bak" -Force
    }
    $destDir = Split-Path $Dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Copy-Item $Source $Dest -Force
    return $true
}

$consultingDir = Join-Path $env:USERPROFILE "consulting"
$synkade = @()

try {
    if (Test-Path $consultingDir) {
        $manifest = @(
            @{ Namn = "CLAUDE.md";  Source = (Join-Path $pluginRoot "consulting\CLAUDE.md"); Dest = (Join-Path $consultingDir "CLAUDE.md") }
            @{ Namn = "ROADMAP.md"; Source = (Join-Path $pluginRoot "ROADMAP.md");           Dest = (Join-Path $consultingDir "ROADMAP.md") }
        )
        # Scripten läggs till dynamiskt, så ett nytt hjälpskript i pluginet når
        # konsulten utan att manifestet behöver röras.
        $scriptsDir = Join-Path $pluginRoot "scripts"
        if (Test-Path $scriptsDir) {
            foreach ($py in @(Get-ChildItem -Path $scriptsDir -Filter "*.py" -File -ErrorAction SilentlyContinue)) {
                $manifest += @{
                    Namn   = "scripts/$($py.Name)"
                    Source = $py.FullName
                    Dest   = (Join-Path $consultingDir "scripts\$($py.Name)")
                }
            }
        }
        # Referensfilerna i ramverk/ pekas ut från CLAUDE.md (3.4, 3.5) och läses
        # bara när uppgiften kräver dem. De synkas som scripten, men mappen
        # speglas också, se nedan.
        $ramverkDir = Join-Path $pluginRoot "consulting\ramverk"
        if (Test-Path $ramverkDir) {
            foreach ($md in @(Get-ChildItem -Path $ramverkDir -Filter "*.md" -File -ErrorAction SilentlyContinue)) {
                $manifest += @{
                    Namn   = "ramverk/$($md.Name)"
                    Source = $md.FullName
                    Dest   = (Join-Path $consultingDir "ramverk\$($md.Name)")
                }
            }
        }
        foreach ($post in $manifest) {
            if (Sync-RamverksFil -Source $post.Source -Dest $post.Dest) { $synkade += $post.Namn }
        }

        # ramverk/ är pluginets egen mapp och speglas: en fil som tagits bort ur
        # pluginet tas bort hos konsulten, annars kan Claude hitta en föråldrad
        # regel och följa den. scripts/ speglas inte, eftersom konsultens egna
        # script ligger där. En .bak från tidigare synk ligger kvar.
        $ramverkDest = Join-Path $consultingDir "ramverk"
        if ((Test-Path $ramverkDir) -and (Test-Path $ramverkDest)) {
            $kallor = @(Get-ChildItem -Path $ramverkDir -Filter "*.md" -File | ForEach-Object { $_.Name })
            foreach ($gammal in @(Get-ChildItem -Path $ramverkDest -Filter "*.md" -File)) {
                if ($kallor -notcontains $gammal.Name) {
                    Remove-Item $gammal.FullName -Force
                    $synkade += "ramverk/$($gammal.Name) (borttagen)"
                }
            }
        }
    }
}
catch {
    # Synken får aldrig fälla sessionsstarten — /ekan:setup är manuell fallback.
}

if ($synkade.Count -gt 0) {
    $versionNote = if ($currentVersion) { " (v$currentVersion)" } else { "" }
    $vad = $synkade -join ", "
    $context += "Ekan-ramverkets filer synkades till plugin-versionen$versionNote`: $vad. Överskrivna filer har en .bak vid sidan."
    $userNotes += "Ekan-ramverkets filer synkades till plugin-versionen$versionNote`: $vad. Dina tidigare filer ligger kvar som .bak i samma mapp."
}

# --- Aktiva projekt ---
$projectsDir = Join-Path $env:USERPROFILE "consulting\projects"
$claudeFiles = Get-ChildItem -Path $projectsDir -Filter "CLAUDE.md" -Recurse -Depth 1 -ErrorAction SilentlyContinue

if ($claudeFiles.Count -gt 0) {
    $projectNames = ($claudeFiles | ForEach-Object { $_.Directory.Name }) -join ", "
    $context += "Aktiva projekt: $projectNames. Kör /ekan:jobb för to-do-översikt."
}

# --- Output ---
# Banern och projektlistan är kontext för modellen och hör inte på skärmen varje
# session. Bara $userNotes renderas för konsulten.
#
# Claude Code läser additionalContext bara inuti hookSpecificOutput. Ligger
# fältet på toppnivå parsas JSON:en utan fel men kontexten kastas tyst: hooken
# loggas som lyckad med tomt innehåll, och banern och uppdateringsnotisen når
# aldrig modellen. Så var det fram till 3.9.3.
if ($context.Count -gt 0) {
    $result = @{
        hookSpecificOutput = @{
            hookEventName     = "SessionStart"
            additionalContext = ($context -join "`n")
        }
    }
    if ($userNotes.Count -gt 0) {
        $result.systemMessage = ($userNotes -join "`n")
    }
    $result | ConvertTo-Json -Compress
}
