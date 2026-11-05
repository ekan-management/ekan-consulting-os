# Pester 5 tester för hooks/session-start.ps1 — CLAUDE.md-autosynk.
# Kör: Invoke-Pester -Path tests/session-start.Tests.ps1 -Output Detailed
#
# Isolerar $env:USERPROFILE och $env:CLAUDE_PLUGIN_ROOT till temp-kataloger
# så riktiga ~/.claude och ~/consulting aldrig rörs.

BeforeAll {
    $script:ScriptPath = (Resolve-Path "$PSScriptRoot/../hooks/session-start.ps1").Path

    function Invoke-SessionStart {
        # Kör hooken i denna process med omdirigerad miljö; returnerar stdout som sträng.
        (& $script:ScriptPath) -join "`n"
    }
}

Describe "session-start.ps1 — CLAUDE.md-autosynk" {
    BeforeEach {
        $script:origHome = $env:USERPROFILE
        $script:origPluginRoot = $env:CLAUDE_PLUGIN_ROOT

        $rand = Get-Random
        $script:testHome = Join-Path ([System.IO.Path]::GetTempPath()) "ss-home-$rand"
        $script:testPlugin = Join-Path ([System.IO.Path]::GetTempPath()) "ss-plugin-$rand"
        New-Item -ItemType Directory -Path "$script:testHome\.claude" -Force | Out-Null
        New-Item -ItemType Directory -Path "$script:testHome\consulting" -Force | Out-Null
        New-Item -ItemType Directory -Path "$script:testPlugin\consulting" -Force | Out-Null
        Set-Content "$script:testPlugin\VERSION" "9.9.9" -NoNewline
        Set-Content "$script:testPlugin\consulting\CLAUDE.md" "NY EKAN-STANDARD"
        Set-Content "$script:testHome\consulting\CLAUDE.md" "GAMMAL EKAN-STANDARD"
        Set-Content "$script:testHome\consulting\MY-CLAUDE.md" "KONSULTENS EGNA"

        $env:USERPROFILE = $script:testHome
        $env:CLAUDE_PLUGIN_ROOT = $script:testPlugin
    }
    AfterEach {
        $env:USERPROFILE = $script:origHome
        $env:CLAUDE_PLUGIN_ROOT = $script:origPluginRoot
        Remove-Item $script:testHome, $script:testPlugin -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "synkar CLAUDE.md när innehållet skiljer sig från pluginets" {
        Invoke-SessionStart | Out-Null
        (Get-Content "$script:testHome\consulting\CLAUDE.md" -Raw).Trim() | Should -Be "NY EKAN-STANDARD"
    }

    It "tar backup av den gamla filen till CLAUDE.md.bak" {
        Invoke-SessionStart | Out-Null
        Test-Path "$script:testHome\consulting\CLAUDE.md.bak" | Should -Be $true
        (Get-Content "$script:testHome\consulting\CLAUDE.md.bak" -Raw).Trim() | Should -Be "GAMMAL EKAN-STANDARD"
    }

    It "nämner synken i additionalContext" {
        $out = Invoke-SessionStart
        $out | Should -Match "synkad"
        ($out | ConvertFrom-Json).hookSpecificOutput.additionalContext | Should -Not -BeNullOrEmpty
    }

    It "rör ALDRIG MY-CLAUDE.md" {
        Invoke-SessionStart | Out-Null
        (Get-Content "$script:testHome\consulting\MY-CLAUDE.md" -Raw).Trim() | Should -Be "KONSULTENS EGNA"
    }

    It "gör ingenting när filerna redan är identiska (ingen .bak skapas)" {
        Set-Content "$script:testHome\consulting\CLAUDE.md" "NY EKAN-STANDARD"
        Invoke-SessionStart | Out-Null
        Test-Path "$script:testHome\consulting\CLAUDE.md.bak" | Should -Be $false
    }

    It "hoppar över synk när ~/consulting saknas (setup har inte körts)" {
        Remove-Item "$script:testHome\consulting" -Recurse -Force
        { Invoke-SessionStart } | Should -Not -Throw
        Test-Path "$script:testHome\consulting" | Should -Be $false
    }

    It "saknad consulting/CLAUDE.md i plugin-root → ingen synk, ingen krasch" {
        Remove-Item "$script:testPlugin\consulting" -Recurse -Force
        { Invoke-SessionStart } | Should -Not -Throw
        (Get-Content "$script:testHome\consulting\CLAUDE.md" -Raw).Trim() | Should -Be "GAMMAL EKAN-STANDARD"
    }

    It "återskapar CLAUDE.md om den saknas men consulting-mappen finns" {
        Remove-Item "$script:testHome\consulting\CLAUDE.md"
        Invoke-SessionStart | Out-Null
        (Get-Content "$script:testHome\consulting\CLAUDE.md" -Raw).Trim() | Should -Be "NY EKAN-STANDARD"
    }

    It "output är fortsatt giltig JSON med additionalContext" {
        $out = Invoke-SessionStart
        $parsed = $out | ConvertFrom-Json
        $parsed.hookSpecificOutput.additionalContext | Should -Match "Ekan-plugin aktiv"
    }

    # Claude Code kastar additionalContext på toppnivå utan felmeddelande. Hooken
    # loggas då som lyckad men med tomt innehåll, så felet syns bara här.
    It "lägger kontexten i hookSpecificOutput med hookEventName SessionStart" {
        $parsed = Invoke-SessionStart | ConvertFrom-Json
        $parsed.hookSpecificOutput.hookEventName | Should -Be "SessionStart"
        $parsed.PSObject.Properties.Name | Should -Not -Contain "additionalContext"
    }

    It "uppdaterings-ping korrumperar inte JSON-outputen — pingen levereras i additionalContext" {
        # Körs i child-process så att ALLT på stdout fångas (Write-Host inkluderat) —
        # det är så Claude Code läser hooken.
        Set-Content "$script:testHome\.claude\.ekan-last-version" "1.0.0" -NoNewline
        $txt = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $script:ScriptPath) -join "`n"
        { $txt | ConvertFrom-Json -ErrorAction Stop } | Should -Not -Throw
        ($txt | ConvertFrom-Json).hookSpecificOutput.additionalContext | Should -Match "uppdaterad"
    }

    # systemMessage är det enda fältet Claude Code renderar för konsulten.
    # additionalContext går bara till modellen och syns därför först efter
    # konsultens första prompt — en session som bara öppnas missar notisen.
    It "renderar synk-notisen i systemMessage" {
        $parsed = Invoke-SessionStart | ConvertFrom-Json
        $parsed.systemMessage | Should -Match "synkad"
    }

    It "renderar uppdaterings-notisen i systemMessage" {
        Set-Content "$script:testHome\.claude\.ekan-last-version" "1.0.0" -NoNewline
        $parsed = Invoke-SessionStart | ConvertFrom-Json
        $parsed.systemMessage | Should -Match "uppdaterad: 1\.0\.0 -> 9\.9\.9"
    }

    It "håller banern och projektlistan utanför systemMessage" {
        # De hör i modellens kontext, inte på skärmen varje session.
        $parsed = Invoke-SessionStart | ConvertFrom-Json
        $parsed.systemMessage | Should -Not -Match "Ekan-plugin aktiv"
        $parsed.systemMessage | Should -Not -Match "Aktiva projekt"
    }

    It "utelämnar systemMessage när varken synk eller uppdatering skett" {
        Set-Content "$script:testHome\consulting\CLAUDE.md" "NY EKAN-STANDARD"
        Set-Content "$script:testHome\.claude\.ekan-last-version" "9.9.9" -NoNewline
        $parsed = Invoke-SessionStart | ConvertFrom-Json
        $parsed.systemMessage | Should -BeNullOrEmpty
        $parsed.hookSpecificOutput.additionalContext | Should -Match "Ekan-plugin aktiv"
    }
}

# Synken bär en manifestlista, inte bara CLAUDE.md. Bakgrund: standardens §2.1
# är en hård regel som slutar med `python scripts/check_diakriter.py`, men
# scripten installerades bara av /ekan:setup. När scriptet bytte namn stod
# regeln kvar hos konsulten och pekade på en fil som inte fanns.
Describe "session-start.ps1 — ramverkssynk av scripts och ROADMAP" {
    BeforeEach {
        $script:origHome = $env:USERPROFILE
        $script:origPluginRoot = $env:CLAUDE_PLUGIN_ROOT

        $rand = Get-Random
        $script:testHome = Join-Path ([System.IO.Path]::GetTempPath()) "ss-mani-home-$rand"
        $script:testPlugin = Join-Path ([System.IO.Path]::GetTempPath()) "ss-mani-plugin-$rand"
        New-Item -ItemType Directory -Path "$script:testHome\.claude" -Force | Out-Null
        New-Item -ItemType Directory -Path "$script:testHome\consulting" -Force | Out-Null
        New-Item -ItemType Directory -Path "$script:testPlugin\consulting" -Force | Out-Null
        New-Item -ItemType Directory -Path "$script:testPlugin\scripts" -Force | Out-Null

        Set-Content "$script:testPlugin\VERSION" "9.9.9" -NoNewline
        # CLAUDE.md identisk på båda sidor, så testerna mäter bara manifestet.
        Set-Content "$script:testPlugin\consulting\CLAUDE.md" "EKAN-STANDARD"
        Set-Content "$script:testHome\consulting\CLAUDE.md" "EKAN-STANDARD"
        Set-Content "$script:testPlugin\ROADMAP.md" "ROADMAP v9"
        Set-Content "$script:testPlugin\scripts\check_diakriter.py" "# diakriter v9"
        Set-Content "$script:testPlugin\scripts\read_office.py" "# read_office v9"

        $env:USERPROFILE = $script:testHome
        $env:CLAUDE_PLUGIN_ROOT = $script:testPlugin
    }
    AfterEach {
        $env:USERPROFILE = $script:origHome
        $env:CLAUDE_PLUGIN_ROOT = $script:origPluginRoot
        Remove-Item $script:testHome, $script:testPlugin -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "synkar hjälpskripten när ~/consulting/scripts saknas helt" {
        Invoke-SessionStart | Out-Null
        (Get-Content "$script:testHome\consulting\scripts\check_diakriter.py" -Raw).Trim() | Should -Be "# diakriter v9"
        (Get-Content "$script:testHome\consulting\scripts\read_office.py" -Raw).Trim() | Should -Be "# read_office v9"
    }

    It "synkar ROADMAP.md, så att standardens relativa referenser går att följa" {
        Invoke-SessionStart | Out-Null
        (Get-Content "$script:testHome\consulting\ROADMAP.md" -Raw).Trim() | Should -Be "ROADMAP v9"
    }

    It "skriver över ett script med äldre innehåll och lämnar en .bak" {
        New-Item -ItemType Directory -Path "$script:testHome\consulting\scripts" -Force | Out-Null
        Set-Content "$script:testHome\consulting\scripts\check_diakriter.py" "# diakriter v1"
        Invoke-SessionStart | Out-Null
        (Get-Content "$script:testHome\consulting\scripts\check_diakriter.py" -Raw).Trim() | Should -Be "# diakriter v9"
        (Get-Content "$script:testHome\consulting\scripts\check_diakriter.py.bak" -Raw).Trim() | Should -Be "# diakriter v1"
    }

    It "rör ALDRIG konsultens egna script i samma mapp" {
        # ~/consulting/scripts innehåller konsultens egna verktyg. Synken får
        # kopiera in ramverkets filer, aldrig radera eller röra något annat.
        New-Item -ItemType Directory -Path "$script:testHome\consulting\scripts" -Force | Out-Null
        Set-Content "$script:testHome\consulting\scripts\fill_projektdirektiv.py" "KONSULTENS EGET"
        Invoke-SessionStart | Out-Null
        (Get-Content "$script:testHome\consulting\scripts\fill_projektdirektiv.py" -Raw).Trim() | Should -Be "KONSULTENS EGET"
        Test-Path "$script:testHome\consulting\scripts\fill_projektdirektiv.py.bak" | Should -Be $false
    }

    It "namnger de synkade filerna i notisen" {
        $parsed = Invoke-SessionStart | ConvertFrom-Json
        $parsed.systemMessage | Should -Match "ROADMAP\.md"
        $parsed.systemMessage | Should -Match "scripts/check_diakriter\.py"
    }

    It "gör ingenting när allt redan är i takt" {
        Invoke-SessionStart | Out-Null
        Set-Content "$script:testHome\.claude\.ekan-last-version" "9.9.9" -NoNewline
        $parsed = Invoke-SessionStart | ConvertFrom-Json
        $parsed.systemMessage | Should -BeNullOrEmpty
        Test-Path "$script:testHome\consulting\scripts\check_diakriter.py.bak" | Should -Be $false
    }

    It "skapar ingen scriptmapp när ~/consulting saknas (halv install)" {
        Remove-Item "$script:testHome\consulting" -Recurse -Force
        { Invoke-SessionStart } | Should -Not -Throw
        Test-Path "$script:testHome\consulting" | Should -Be $false
    }

    It "saknad scripts/ i plugin-roten → ingen synk, ingen krasch" {
        Remove-Item "$script:testPlugin\scripts" -Recurse -Force
        { Invoke-SessionStart } | Should -Not -Throw
        Test-Path "$script:testHome\consulting\scripts" | Should -Be $false
    }

    It "synkar referensfilerna i ramverk/, som CLAUDE.md pekar ut" {
        New-Item -ItemType Directory -Path "$script:testPlugin\consulting\ramverk" -Force | Out-Null
        Set-Content "$script:testPlugin\consulting\ramverk\visuell-profil.md" "PROFIL v9"
        $parsed = Invoke-SessionStart | ConvertFrom-Json
        (Get-Content "$script:testHome\consulting\ramverk\visuell-profil.md" -Raw).Trim() | Should -Be "PROFIL v9"
        $parsed.systemMessage | Should -Match "ramverk/visuell-profil\.md"
    }

    It "tar bort en ramverksfil som inte längre finns i pluginet" {
        # En kvarlämnad referensfil kan läsas som gällande regel.
        New-Item -ItemType Directory -Path "$script:testPlugin\consulting\ramverk" -Force | Out-Null
        Set-Content "$script:testPlugin\consulting\ramverk\visuell-profil.md" "PROFIL v9"
        New-Item -ItemType Directory -Path "$script:testHome\consulting\ramverk" -Force | Out-Null
        Set-Content "$script:testHome\consulting\ramverk\gammal-regel.md" "INAKTUELL"
        $parsed = Invoke-SessionStart | ConvertFrom-Json
        Test-Path "$script:testHome\consulting\ramverk\gammal-regel.md" | Should -Be $false
        Test-Path "$script:testHome\consulting\ramverk\visuell-profil.md" | Should -Be $true
        $parsed.systemMessage | Should -Match "gammal-regel\.md \(borttagen\)"
    }

    It "saknad ramverk/ i plugin-roten → konsultens mapp rörs inte" {
        New-Item -ItemType Directory -Path "$script:testHome\consulting\ramverk" -Force | Out-Null
        Set-Content "$script:testHome\consulting\ramverk\visuell-profil.md" "PROFIL v8"
        Invoke-SessionStart | Out-Null
        Test-Path "$script:testHome\consulting\ramverk\visuell-profil.md" | Should -Be $true
    }

    It "saknad ramverk/ i plugin-roten → ingen mapp skapas, ingen krasch" {
        { Invoke-SessionStart } | Should -Not -Throw
        Test-Path "$script:testHome\consulting\ramverk" | Should -Be $false
    }

    It "output är fortsatt giltig JSON när flera filer synkas" {
        $out = Invoke-SessionStart
        { $out | ConvertFrom-Json -ErrorAction Stop } | Should -Not -Throw
        ($out | ConvertFrom-Json).hookSpecificOutput.additionalContext | Should -Match "Ekan-plugin aktiv"
    }
}

Describe "compact-reminder.ps1 — outputformat" {
    It "lägger påminnelsen i hookSpecificOutput med hookEventName SessionStart" {
        $path = (Resolve-Path "$PSScriptRoot/../hooks/compact-reminder.ps1").Path
        $parsed = ((& $path) -join "`n") | ConvertFrom-Json
        $parsed.hookSpecificOutput.hookEventName | Should -Be "SessionStart"
        $parsed.hookSpecificOutput.additionalContext | Should -Match "Påminnelse efter komprimering"
        $parsed.PSObject.Properties.Name | Should -Not -Contain "additionalContext"
    }

    It "ber inte om projektöversikt mitt i en session" {
        # Komprimering sker mitt i arbetet. Fram till 3.10.0 bad påminnelsen
        # Claude visa projektöversikten som första meddelande, vilket avbröt uppgiften.
        $path = (Resolve-Path "$PSScriptRoot/../hooks/compact-reminder.ps1").Path
        $parsed = ((& $path) -join "`n") | ConvertFrom-Json
        $parsed.hookSpecificOutput.additionalContext | Should -Not -Match "FÖRSTA meddelande"
        $parsed.hookSpecificOutput.additionalContext | Should -Match "källfilen"
    }
}
