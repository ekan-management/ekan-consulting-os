# hooks/ekan-setup.ps1
# Implementerar /ekan:setup — städar legacy-artifakter och installerar ramverk.

param(
    [switch]$TestMode,
    [string]$UserHome = $env:USERPROFILE,
    [string]$PluginRoot = $env:CLAUDE_PLUGIN_ROOT,
    [switch]$SkipPython,
    # Bekräftar legacy-städningen utan interaktiv prompt. Skriptet körs normalt
    # via Bash-verktyget, som inte har konsol-stdin — där kan Read-Host inte
    # besvaras. Claude listar artifakterna för konsulten och sätter denna flagga
    # först efter ett ja. Se commands/setup.md.
    [switch]$Yes
)

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$ErrorActionPreference = 'Stop'

$ClaudeDir = Join-Path $UserHome ".claude"
$ConsultingDir = Join-Path $UserHome "consulting"

function Write-Info { param([string]$Msg) Write-Host "  $Msg" -ForegroundColor Gray }
function Write-Ok   { param([string]$Msg) Write-Host "  $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "  $Msg" -ForegroundColor Yellow }

# Filer i ~/consulting som setup skrev över och sparade som .bak. Redovisas sist.
$script:Bakade = @()

function Copy-MedBackup {
    # Skriver en pluginfil till ~/consulting. Finns en fil med annat innehåll
    # sparas den först som .bak, på samma sätt som sessionsstarten gör. En fil
    # med samma innehåll rörs inte, så en omkörning skriver ingen ny .bak.
    param([string]$Source, [string]$Dest)
    if (Test-Path $Dest) {
        $srcHash = (Get-FileHash $Source -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash $Dest -Algorithm SHA256).Hash
        if ($srcHash -eq $dstHash) { return }
        Copy-Item $Dest "$Dest.bak" -Force
        $script:Bakade += $Dest
    }
    Copy-Item $Source $Dest -Force
}

function Backup-UserFiles {
    # Backupar settings.json till ~/.claude/backups/ (settings.json ändras varje
    # körning av permissions-merge — backup ger rollback-säkerhet).
    # MY-CLAUDE.md backupas inte: setup rör inte filen om den redan finns
    # (Install-RamverkClaudeMd skapar bara från template när dst saknas).
    # Roterar: behåller N=5 senaste backups.
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $settings = Join-Path $ClaudeDir "settings.json"

    if (-not (Test-Path $settings)) {
        return $null
    }

    $backupDir = Join-Path $ClaudeDir "backups"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }

    $backupPath = Join-Path $backupDir "settings.json.bak-$ts"
    Copy-Item $settings $backupPath -Force
    Write-Ok "Backup: ~/.claude/backups/settings.json.bak-$ts"

    $maxBackups = 5
    $allBackups = @(Get-ChildItem -Path $backupDir -Filter "settings.json.bak-*" |
        Sort-Object Name -Descending)
    if ($allBackups.Count -gt $maxBackups) {
        $toRemove = $allBackups | Select-Object -Skip $maxBackups
        foreach ($f in $toRemove) {
            Remove-Item $f.FullName -Force
        }
    }

    return $ts
}

function Remove-LegacyBackups {
    # Städar bort backup-filer från pre-2.1.2-regimen:
    #   ~/consulting/MY-CLAUDE.md.bak-* (alla — backupas ej längre)
    #   ~/.claude/settings.json.bak-* (i rotnivån — flyttat till backups/-mappen)
    # Påverkar inte filer i den nya ~/.claude/backups/-mappen.
    $patterns = @(
        @{ Dir = $ConsultingDir; Pattern = "MY-CLAUDE.md.bak-*" },
        @{ Dir = $ClaudeDir;     Pattern = "settings.json.bak-*" }
    )
    $removed = 0
    foreach ($p in $patterns) {
        if (-not (Test-Path $p.Dir)) { continue }
        $files = Get-ChildItem -Path $p.Dir -Filter $p.Pattern -File -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            Remove-Item $f.FullName -Force
            $removed++
        }
    }
    if ($removed -gt 0) {
        Write-Info "Städat $removed gamla backup-fil(er) från ~/consulting/ och ~/.claude/"
    }
}

function Find-LegacyArtifacts {
    $artifacts = @{
        HookFiles = @()
        SkillDirs = @()
        CommandFiles = @()
        VersionFile = $null
    }

    # Listorna nedan måste täcka allt som NÅGONSIN shippats till ~/.claude/ via
    # den gamla setup.ps1/update.ps1-vägen — inte bara det pluginet levererar
    # idag. En kvarlämnad artifakt är inte passiv: en personlig skill i
    # ~/.claude/skills/ konkurrerar med pluginets version om autotriggern, och
    # pekar dessutom på hookar som den här körningen just raderat.
    # Kontrollera mot historiken när något läggs till eller döps om:
    #   git log --all --pretty=format: --name-only --diff-filter=A -- 'commands/*.md'
    $legacyHooks = @(
        "block-dangerous.ps1", "compact-reminder.ps1", "ekan-setup.ps1",
        "jobb.ps1", "nytt-projekt.ps1", "session-start.ps1"
    )
    foreach ($h in $legacyHooks) {
        $p = Join-Path $ClaudeDir "hooks/$h"
        if (Test-Path $p) { $artifacts.HookFiles += $p }
    }

    # "stop slop" med mellanslag är den ursprungliga mappen (claude/skills/stop slop/),
    # döpt till stop-slop senare. Båda kan finnas på gamla installationer.
    $legacySkills = @("intro", "nytt-projekt", "projektdirektiv", "stop slop", "stop-slop")
    foreach ($s in $legacySkills) {
        $p = Join-Path $ClaudeDir "skills/$s"
        if (Test-Path $p) { $artifacts.SkillDirs += $p }
    }

    $legacyCommands = @("jobb.md", "nytt-projekt.md", "setup.md")
    foreach ($c in $legacyCommands) {
        $p = Join-Path $ClaudeDir "commands/$c"
        if (Test-Path $p) { $artifacts.CommandFiles += $p }
    }

    $versionFile = Join-Path $ClaudeDir ".ekan-setup-version"
    if (Test-Path $versionFile) { $artifacts.VersionFile = $versionFile }

    return $artifacts
}

function Remove-LegacyArtifacts {
    param($Artifacts)
    foreach ($f in $Artifacts.HookFiles) {
        Remove-Item $f -Force
        Write-Info "Raderat: $f"
    }
    foreach ($d in $Artifacts.SkillDirs) {
        Remove-Item $d -Recurse -Force
        Write-Info "Raderat: $d"
    }
    foreach ($c in $Artifacts.CommandFiles) {
        Remove-Item $c -Force
        Write-Info "Raderat: $c"
    }
    if ($Artifacts.VersionFile) {
        Remove-Item $Artifacts.VersionFile -Force
        Write-Info "Raderat: $($Artifacts.VersionFile)"
    }
}

function Install-ConsultingStructure {
    foreach ($dir in @("projects", "tmp", "arkiv")) {
        $p = Join-Path $ConsultingDir $dir
        if (-not (Test-Path $p)) {
            New-Item -ItemType Directory -Path $p -Force | Out-Null
            Write-Info "Skapat: $p"
        }
    }
}

function Install-RamverkClaudeMd {
    $src = Join-Path $PluginRoot "consulting/CLAUDE.md"
    $dst = Join-Path $ConsultingDir "CLAUDE.md"
    if (-not (Test-Path $src)) {
        Write-Warn "Saknar $src — hoppar över CLAUDE.md-install"
        return
    }
    Copy-MedBackup -Source $src -Dest $dst
    Write-Ok "Installerat: ~/consulting/CLAUDE.md (Ekan-ramverk)"

    # CLAUDE.md pekar ut referensfilerna i ramverk/ (3.4, 3.5). Utan dem här
    # kommer de först med nästa sessionsstart.
    $ramverkSrc = Join-Path $PluginRoot "consulting/ramverk"
    if (Test-Path $ramverkSrc) {
        $ramverkDst = Join-Path $ConsultingDir "ramverk"
        if (-not (Test-Path $ramverkDst)) { New-Item -ItemType Directory -Path $ramverkDst -Force | Out-Null }
        foreach ($fil in Get-ChildItem $ramverkSrc -File -Filter *.md) {
            Copy-MedBackup -Source $fil.FullName -Dest (Join-Path $ramverkDst $fil.Name)
        }
        Write-Ok "Installerat: ~/consulting/ramverk (referensfiler)"
    }

    $myTemplate = Join-Path $PluginRoot "consulting/MY-CLAUDE.md.template"
    $myDst = Join-Path $ConsultingDir "MY-CLAUDE.md"
    if ((Test-Path $myTemplate) -and (-not (Test-Path $myDst))) {
        Copy-Item $myTemplate $myDst
        Write-Ok "Skapat: ~/consulting/MY-CLAUDE.md (från template)"
    }
}

function Test-Templates {
    # Ekans Office-mallar ingår inte i pluginet sedan 3.12.0: repot är publikt och
    # mallarna är Ekans material. Konsulten lägger dem själv i ~/consulting/templates/.
    # nytt-projekt.ps1 kopierar därifrån till projektets "80 Mallar kompassen", och
    # skillsen och md_to_word.py läser samma katalog. Setup skapar katalogen och
    # listar de mallar som skillsen behöver men som saknas.
    $dst = Join-Path $ConsultingDir "templates"
    if (-not (Test-Path $dst)) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }

    $kravda = @(
        "Mall Projektdirektiv.docx",
        "Mall Uppdragsdirektiv Små uppdrag.docx",
        "Mall anteckningar.docx"
    )
    $saknas = @($kravda | Where-Object { -not (Test-Path (Join-Path $dst $_)) })

    if ($saknas.Count -eq 0) {
        $antal = @(Get-ChildItem $dst -File).Count
        Write-Ok "Mallar: ~/consulting/templates ($antal filer)"
        return
    }

    Write-Warn "Ekans Office-mallar ingår inte i pluginet. Lägg dem själv i ~/consulting/templates/."
    Write-Warn "Hämta mallarna från Ekans SharePoint. Följande behövs av /ekan:projektdirektiv och Word-skriptet:"
    foreach ($m in $saknas) { Write-Warn "  - $m" }
    Write-Info "Övriga Kompassen-mallar du lägger i mappen kopieras in i varje nytt projekt."
}

function Install-Scripts {
    # Ramverkets CLAUDE.md hänvisar till scripts/read_office.py, md_to_word.py och
    # check_diakriter.py med relativ sökväg från ~/consulting/. Ingen
    # installationsväg har någonsin kopierat dem dit — de fanns bara hos konsulter
    # som klonat repot. Nya konsulter fick instruktioner som pekade i tomma luften.
    $src = Join-Path $PluginRoot "scripts"
    $dst = Join-Path $ConsultingDir "scripts"

    if (-not (Test-Path $src)) {
        Write-Warn "Saknar $src — hoppar över hjälpskript"
        return
    }

    if (-not (Test-Path $dst)) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }

    $antal = 0
    foreach ($fil in Get-ChildItem $src -File -Filter *.py) {
        Copy-MedBackup -Source $fil.FullName -Dest (Join-Path $dst $fil.Name)
        $antal++
    }
    Write-Ok "Hjälpskript installerade: ~/consulting/scripts ($antal filer)"
}

function Enable-MarketplaceAutoUpdate {
    # Marknadsplatser från tredje part uppdateras inte automatiskt som standard.
    # Utan autoUpdate ligger konsulten kvar på den version hen installerade,
    # och update-pingen i session-start.ps1 får aldrig något att visa.
    # Andra poster i extraKnownMarketplaces lämnas orörda.
    param([PSCustomObject]$Settings)

    if (-not $Settings.extraKnownMarketplaces) {
        $Settings | Add-Member -NotePropertyName extraKnownMarketplaces -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    $entry = $Settings.extraKnownMarketplaces.'ekan-plugins'
    if (-not $entry) {
        $Settings.extraKnownMarketplaces | Add-Member -NotePropertyName 'ekan-plugins' -NotePropertyValue ([PSCustomObject]@{
            source     = [PSCustomObject]@{ source = "github"; repo = "ekan-management/ekan-plugins" }
            autoUpdate = $true
        }) -Force
    } else {
        # Marknadsplatsen flyttade till organisationen ekan-management i 3.12.0.
        # Den gamla adressen är ett privat arkiv, så en post som pekar dit byts.
        if ($entry.source -and $entry.source.repo -eq "DaVincisfather/ekan-plugins") {
            $entry.source.repo = "ekan-management/ekan-plugins"
        }
        $entry | Add-Member -NotePropertyName autoUpdate -NotePropertyValue $true -Force
    }

    # autoUpdate ovan räcker inte när Claude Codes egen uppdatering är avstängd
    # ("autoUpdates": false i ~/.claude.json, vanligt vid npm-installation). Den
    # stänger av pluginuppdateringarna också. FORCE_AUTOUPDATE_PLUGINS släpper
    # igenom dem utan att slå på uppdateringen av själva Claude Code.
    # Prövat 2026-09-23: 12 min utan variabeln gav inget, med den hämtades
    # 3.7.0 efter 7 min.
    if (-not $Settings.env) {
        $Settings | Add-Member -NotePropertyName env -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    $Settings.env | Add-Member -NotePropertyName FORCE_AUTOUPDATE_PLUGINS -NotePropertyValue "1" -Force
}

function Test-EkanLegacyHook {
    # Känner igen Ekans hooks från tiden före pluginet: skripten i ~/.claude/hooks/
    # och påminnelsen efter komprimering. Allt annat räknas som konsultens eget.
    param([string]$Command)
    if ([string]::IsNullOrEmpty($Command)) { return $false }
    if ($Command -match '[\\/]\.claude[\\/]hooks[\\/](block-dangerous|compact-reminder|ekan-setup|jobb|nytt-projekt|session-start)\.ps1') { return $true }
    if ($Command -match 'Påminnelse efter komprimering') { return $true }
    return $false
}

function Remove-EkanLegacyHooks {
    # Före 3.12.1 togs hela hooks-blocket bort, även hooks som konsulten själv
    # lagt dit. Nu tas bara Ekans gamla poster bort. En grupp eller händelse som
    # blir tom tas bort, och hooks-blocket försvinner först när inget är kvar.
    # Returnerar antalet borttagna hooks.
    param([PSCustomObject]$Settings)
    if (-not ($Settings.PSObject.Properties.Name -contains 'hooks')) { return 0 }
    $hooks = $Settings.hooks
    if ($null -eq $hooks -or $hooks -isnot [System.Management.Automation.PSCustomObject]) { return 0 }

    $borttagna = 0
    foreach ($handelse in @($hooks.PSObject.Properties)) {
        $grupper = @()
        foreach ($grupp in @($handelse.Value)) {
            if ($null -eq $grupp) { continue }
            if (-not ($grupp.PSObject.Properties.Name -contains 'hooks')) {
                $grupper += $grupp
                continue
            }
            $kvar = @()
            foreach ($h in @($grupp.hooks)) {
                if ($null -eq $h) { continue }
                if (Test-EkanLegacyHook -Command $h.command) { $borttagna++ } else { $kvar += $h }
            }
            if ($kvar.Count -gt 0) {
                $grupp.hooks = $kvar
                $grupper += $grupp
            }
        }
        if ($grupper.Count -gt 0) {
            $hooks.($handelse.Name) = $grupper
        } else {
            $hooks.PSObject.Properties.Remove($handelse.Name)
        }
    }
    if (@($hooks.PSObject.Properties).Count -eq 0) {
        $Settings.PSObject.Properties.Remove('hooks')
    }
    return $borttagna
}

function Merge-Permissions {
    $settingsPath = Join-Path $ClaudeDir "settings.json"
    $templatePath = Join-Path $PluginRoot "config/permissions-template.json"

    if (-not (Test-Path $templatePath)) {
        Write-Warn "Saknar $templatePath — hoppar över permissions-merge"
        return
    }

    $template = Get-Content $templatePath -Raw -Encoding UTF8 | ConvertFrom-Json

    if (Test-Path $settingsPath) {
        $existing = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } else {
        $existing = [PSCustomObject]@{
            permissions = [PSCustomObject]@{ allow = @(); deny = @(); defaultMode = "auto" }
        }
    }

    # Ensure permissions-struktur finns
    if (-not $existing.permissions) {
        $existing | Add-Member -NotePropertyName permissions -NotePropertyValue ([PSCustomObject]@{ allow = @(); deny = @(); defaultMode = "auto" }) -Force
    }

    # Merge allow/deny som union (bevarar custom entries)
    $allowUnion = @($existing.permissions.allow) + @($template.permissions.allow) | Select-Object -Unique
    $denyUnion  = @($existing.permissions.deny)  + @($template.permissions.deny)  | Select-Object -Unique

    $existing.permissions.allow = $allowUnion
    $existing.permissions.deny = $denyUnion
    if (-not $existing.permissions.defaultMode) {
        $existing.permissions | Add-Member -NotePropertyName defaultMode -NotePropertyValue "auto" -Force
    }

    # Sätt language: swedish om saknas
    if (-not $existing.language) {
        $existing | Add-Member -NotePropertyName language -NotePropertyValue "swedish" -Force
    }

    # Ekans gamla hooks tas bort, eftersom pluginet levererar dem via
    # hooks/hooks.json. Konsultens egna hooks ligger kvar.
    $borttagna = Remove-EkanLegacyHooks -Settings $existing
    if ($borttagna -gt 0) {
        Write-Info "Tog bort $borttagna gamla Ekan-hooks ur settings.json. Egna hooks ligger kvar."
    }

    Enable-MarketplaceAutoUpdate -Settings $existing

    # Säkerställ att ~/.claude finns — på en helt ren maskin saknas katalogen,
    # och då kraschar WriteAllText på settings.json.tmp.
    if (-not (Test-Path $ClaudeDir)) {
        New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
    }

    $json = $existing | ConvertTo-Json -Depth 10
    $tmp = "$settingsPath.tmp"
    [System.IO.File]::WriteAllText($tmp, $json)
    Move-Item -Path $tmp -Destination $settingsPath -Force

    Write-Ok "Permissions mergade och automatisk uppdatering av ekan-plugins påslagen i ~/.claude/settings.json"
}

function Install-PythonPackages {
    if ($SkipPython) {
        Write-Info "Hoppar över Python-paket (SkipPython)"
        return
    }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
    if (-not $python) {
        Write-Warn "Python saknas — installera manuellt: python -m pip install --user python-docx pywin32 markitdown"
        return
    }
    try {
        & $python.Source -m pip install --user --quiet python-docx pywin32 markitdown 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Python-paket installerade"
        } else {
            Write-Warn "pip install misslyckades — kör manuellt: python -m pip install --user python-docx pywin32 markitdown"
        }
    }
    catch {
        Write-Warn "pip install fel: $_ — kör manuellt: python -m pip install --user python-docx pywin32 markitdown"
    }
}

function Invoke-EkanSetup {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  /ekan:setup — legacy-cleanup + ramverk" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # 0. Validera PluginRoot — krävs för att kopiera ramverks-CLAUDE.md och permissions-template
    if ([string]::IsNullOrWhiteSpace($PluginRoot)) {
        Write-Host "FEL: PluginRoot är inte satt." -ForegroundColor Red
        Write-Host "Detta hook ska köras av Claude Code via /ekan:setup. Vid manuell körning, ange en av:" -ForegroundColor Yellow
        Write-Host "  `$env:CLAUDE_PLUGIN_ROOT = '<path-till-plugin>'" -ForegroundColor Gray
        Write-Host "  -PluginRoot '<path-till-plugin>'" -ForegroundColor Gray
        throw "PluginRoot är inte satt — se felmeddelandet ovan."
    }

    # 1. Backup
    $ts = Backup-UserFiles

    # 1b. Migration: städa pre-2.1.2-backups
    Remove-LegacyBackups

    # 2. Detektera legacy
    $artifacts = Find-LegacyArtifacts
    $total = $artifacts.HookFiles.Count + $artifacts.SkillDirs.Count + $artifacts.CommandFiles.Count + ($(if ($artifacts.VersionFile) { 1 } else { 0 }))

    if ($total -gt 0) {
        Write-Host ""
        Write-Host "Följande legacy-artifakter hittades:" -ForegroundColor Yellow
        foreach ($f in $artifacts.HookFiles)   { Write-Host "  - $f" }
        foreach ($d in $artifacts.SkillDirs)   { Write-Host "  - $d" }
        foreach ($c in $artifacts.CommandFiles) { Write-Host "  - $c" }
        if ($artifacts.VersionFile) { Write-Host "  - $($artifacts.VersionFile)" }
        Write-Host ""

        # 3. Bekräftelse före radering
        if (-not $TestMode -and -not $Yes) {
            $answer = Read-Host "Städa upp dessa? (ja/nej)"

            # "$answer" måste citeras. Utan konsol-stdin returnerar Read-Host en tom
            # kollektion, inte $null — och `@() -notmatch '...'` är en filteroperation
            # som ger tom kollektion (falsy). Den ociterade varianten hoppade därför
            # över avbrytet och raderade utan bekräftelse. Citeringen tvingar till
            # sträng: "" -notmatch ... ger $true = avbryt.
            if ("$answer" -notmatch '^(ja|j|y|yes)$') {
                Write-Warn "Avbrutet. Inga ändringar gjorda."
                Write-Info "Kördes detta av Claude? Då finns ingen stdin att svara i —"
                Write-Info "be Claude köra om med -Yes efter att ha visat listan ovan."
                return
            }
        }

        # 4. Cleanup
        Remove-LegacyArtifacts -Artifacts $artifacts
        Write-Ok "Legacy-cleanup klar."
    }
    else {
        Write-Info "Inga legacy-artifakter hittades."
    }

    # 5. Consulting-struktur
    Install-ConsultingStructure

    # 6. Ramverks-CLAUDE.md
    Install-RamverkClaudeMd

    # 7. Kompassen-mallar (läggs dit av konsulten, setup kontrollerar)
    Test-Templates

    # 8. Hjälpskript
    Install-Scripts

    # 9. Permissions-merge
    Merge-Permissions

    # 10. Python-paket
    Install-PythonPackages

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Klar!" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Nästa steg: cd ~/consulting && claude, sen /ekan:intro" -ForegroundColor White
    Write-Host ""
    if ($ts) {
        Write-Host "Backup sparad till:" -ForegroundColor White
        Write-Host "  ~/.claude/backups/settings.json.bak-$ts" -ForegroundColor Gray
        Write-Host "Vid problem: kopiera tillbaka från backup-filen och kör /ekan:setup igen." -ForegroundColor White
    }
    if ($script:Bakade.Count -gt 0) {
        Write-Host ""
        Write-Host "Dessa filer skrevs över. Din tidigare version ligger bredvid som .bak:" -ForegroundColor White
        foreach ($f in $script:Bakade) { Write-Host "  $f.bak" -ForegroundColor Gray }
    }
}

Invoke-EkanSetup
