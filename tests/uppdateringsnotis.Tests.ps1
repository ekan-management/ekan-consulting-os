# Pester 5 tester för uppdateringsnotisen i hooks/session-start.ps1.
# Kör: Invoke-Pester -Path tests/uppdateringsnotis.Tests.ps1 -Output Detailed
#
# Efter en pluginuppdatering ska konsulten få veta vad som är nytt, i klarspråk.
# Texten kommer från avsnittet "### För konsulten" i CHANGELOG.md, för alla
# versioner konsulten hoppat över. Nya skills och kommandon som ingen rad nämner
# läggs till automatiskt, genom jämförelse med förra versionens lista.
#
# Pluginroten ligger som <bas>\ekan\9.9.9, så att förra versionen kan ligga
# bredvid som <bas>\ekan\9.8.0, precis som i Claude Codes plugincache.

BeforeAll {
    $script:ScriptPath = (Resolve-Path "$PSScriptRoot/../hooks/session-start.ps1").Path

    function Invoke-SessionStart {
        (& $script:ScriptPath) -join "`n"
    }

    function Get-Kontext {
        (Invoke-SessionStart | ConvertFrom-Json).hookSpecificOutput.additionalContext
    }

    function Skriv-Changelog {
        param([string]$Text)
        Set-Content -Path "$script:testPlugin\CHANGELOG.md" -Value $Text -Encoding UTF8
    }

    function Ny-Skill {
        param([string]$Rot, [string]$Namn)
        New-Item -ItemType Directory -Path "$Rot\skills\$Namn" -Force | Out-Null
        Set-Content "$Rot\skills\$Namn\SKILL.md" "---`nname: $Namn`n---"
    }

    function Nytt-Kommando {
        param([string]$Rot, [string]$Namn)
        New-Item -ItemType Directory -Path "$Rot\commands" -Force | Out-Null
        Set-Content "$Rot\commands\$Namn.md" "# $Namn"
    }
}

Describe "session-start.ps1 — uppdateringsnotis i klarspråk" {
    BeforeEach {
        $script:origHome = $env:USERPROFILE
        $script:origPluginRoot = $env:CLAUDE_PLUGIN_ROOT

        $rand = Get-Random
        $script:testHome = Join-Path ([System.IO.Path]::GetTempPath()) "un-home-$rand"
        $script:testBas = Join-Path ([System.IO.Path]::GetTempPath()) "un-plugin-$rand"
        $script:testPlugin = "$script:testBas\ekan\9.9.9"
        $script:forraPlugin = "$script:testBas\ekan\9.8.0"
        New-Item -ItemType Directory -Path "$script:testHome\.claude" -Force | Out-Null
        New-Item -ItemType Directory -Path $script:testPlugin -Force | Out-Null

        Set-Content "$script:testPlugin\VERSION" "9.9.9" -NoNewline
        Set-Content "$script:testHome\.claude\.ekan-last-version" "9.8.0" -NoNewline
        Skriv-Changelog @"
# Changelog

## 9.9.9 — 2026-10-09

### För konsulten

- Ny sak i nio.

### Rättat

- **Teknisk rubrik som inte ska visas.** Brödtext.

## 9.9.0 — 2026-10-01

### För konsulten

- Sak från 9.9.0 som
  fortsätter på nästa rad.
- Andra saken i 9.9.0.

## 9.8.0 — 2026-09-01

### För konsulten

- Gammal sak som konsulten redan sett.
"@
        Ny-Skill $script:testPlugin "intro"
        Nytt-Kommando $script:testPlugin "jobb"

        $env:USERPROFILE = $script:testHome
        $env:CLAUDE_PLUGIN_ROOT = $script:testPlugin
    }
    AfterEach {
        $env:USERPROFILE = $script:origHome
        $env:CLAUDE_PLUGIN_ROOT = $script:origPluginRoot
        Remove-Item $script:testHome, $script:testBas -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "listar klarspråksraderna för versionerna efter den senast sedda" {
        $kontext = Get-Kontext
        $kontext | Should -Match "Ny sak i nio\."
        $kontext | Should -Match "Andra saken i 9\.9\.0\."
        $kontext | Should -Not -Match "Gammal sak"
    }

    It "visar inte de tekniska avsnitten" {
        Get-Kontext | Should -Not -Match "Teknisk rubrik"
    }

    It "slår ihop en punkt som fortsätter på nästa rad" {
        Get-Kontext | Should -Match "Sak från 9\.9\.0 som fortsätter på nästa rad\."
    }

    It "numrerar listan med nyaste versionen först" {
        $kontext = Get-Kontext
        $kontext | Should -Match "(?m)^1\. Ny sak i nio\."
        $kontext | Should -Match "(?m)^3\. Andra saken i 9\.9\.0\."
    }

    It "ber Claude visa listan ordagrant" {
        Get-Kontext | Should -Match "ordagrant"
    }

    It "lägger listan även i systemMessage" {
        $parsed = Invoke-SessionStart | ConvertFrom-Json
        $parsed.systemMessage | Should -Match "uppdaterad: 9\.8\.0 -> 9\.9\.9"
        $parsed.systemMessage | Should -Match "Ny sak i nio\."
    }

    It "visar ingen lista vid första installationen" {
        Remove-Item "$script:testHome\.claude\.ekan-last-version"
        Invoke-SessionStart | Should -Not -Match "Ny sak i nio"
    }

    It "visar ingen lista när versionen är oförändrad" {
        Set-Content "$script:testHome\.claude\.ekan-last-version" "9.9.9" -NoNewline
        Invoke-SessionStart | Should -Not -Match "Ny sak i nio"
    }

    It "visar högst tio punkter och säger hur många som återstår" {
        $punkter = (1..12 | ForEach-Object { "- Punkt nummer $_." }) -join "`n"
        Skriv-Changelog "## 9.9.9 — 2026-10-09`n`n### För konsulten`n`n$punkter`n"
        $kontext = Get-Kontext
        $kontext | Should -Match "(?m)^10\. Punkt nummer 10\."
        $kontext | Should -Not -Match "Punkt nummer 11\."
        $kontext | Should -Match "2 ändringar till"
    }

    It "säger ändå att pluginet uppdaterats när klarspråksrader saknas" {
        Skriv-Changelog "## 9.9.9 — 2026-10-09`n`n### Rättat`n`n- **Bara teknik.**`n"
        Get-Kontext | Should -Match "uppdaterad: 9\.8\.0 -> 9\.9\.9"
    }

    It "klarar att CHANGELOG.md saknas" {
        Remove-Item "$script:testPlugin\CHANGELOG.md"
        { $script:kontext = Get-Kontext } | Should -Not -Throw
        $script:kontext | Should -Match "uppdaterad: 9\.8\.0 -> 9\.9\.9"
    }

    Context "nya skills och kommandon" {
        It "nämner en ny skill jämfört med den sparade listan" {
            Ny-Skill $script:testPlugin "kravmatris"
            Set-Content "$script:testHome\.claude\.ekan-last-skills" "intro`njobb"
            Get-Kontext | Should -Match "Ny skill: /ekan:kravmatris"
        }

        It "nämner ett nytt kommando jämfört med den sparade listan" {
            Nytt-Kommando $script:testPlugin "veckorapport"
            Set-Content "$script:testHome\.claude\.ekan-last-skills" "intro`njobb"
            Get-Kontext | Should -Match "Ny skill: /ekan:veckorapport"
        }

        It "nämner inte skills som fanns förut" {
            Set-Content "$script:testHome\.claude\.ekan-last-skills" "intro`njobb"
            Get-Kontext | Should -Not -Match "Ny skill"
        }

        It "hoppar över en ny skill som klarspråksraderna redan nämner" {
            Ny-Skill $script:testPlugin "kravmatris"
            Set-Content "$script:testHome\.claude\.ekan-last-skills" "intro`njobb"
            Skriv-Changelog "## 9.9.9 — 2026-10-09`n`n### För konsulten`n`n- Ny skill ``/ekan:kravmatris`` gör kravmatriser.`n"
            Get-Kontext | Should -Not -Match "Ny skill: /ekan:kravmatris"
        }

        It "jämför med förra versionen i plugincachen när listan inte är sparad" {
            Ny-Skill $script:testPlugin "kravmatris"
            Ny-Skill $script:forraPlugin "intro"
            Nytt-Kommando $script:forraPlugin "jobb"
            Get-Kontext | Should -Match "Ny skill: /ekan:kravmatris"
        }

        It "nämner inga skills när förra listan inte går att hitta" {
            Ny-Skill $script:testPlugin "kravmatris"
            Get-Kontext | Should -Not -Match "Ny skill"
        }

        It "sparar aktuell lista till nästa uppdatering" {
            Ny-Skill $script:testPlugin "kravmatris"
            Invoke-SessionStart | Out-Null
            $sparad = @(Get-Content "$script:testHome\.claude\.ekan-last-skills")
            $sparad | Should -Contain "intro"
            $sparad | Should -Contain "jobb"
            $sparad | Should -Contain "kravmatris"
        }

        It "skapar listan även när versionen är oförändrad men listan saknas" {
            Set-Content "$script:testHome\.claude\.ekan-last-version" "9.9.9" -NoNewline
            Invoke-SessionStart | Out-Null
            Test-Path "$script:testHome\.claude\.ekan-last-skills" | Should -Be $true
        }
    }

    # 9 okt 2026: appen återupptog en vilande session två minuter efter en
    # release. Hooken markerade versionen som sedd där, och konsultens nästa
    # nya session fick ingen notis.
    Context "notisens livslängd" {
        It "visar notisen igen i nästa nya session samma dygn" {
            Invoke-SessionStart | Out-Null
            Get-Kontext | Should -Match "Ny sak i nio\."
        }

        It "visar inte notisen när den upptäcktes för mer än ett dygn sedan" {
            Invoke-SessionStart | Out-Null
            $fil = "$script:testHome\.claude\.ekan-update-notice.json"
            $notis = Get-Content $fil -Raw -Encoding UTF8 | ConvertFrom-Json
            $notis.upptackt = [DateTimeOffset]::UtcNow.AddHours(-25).ToUnixTimeSeconds()
            Set-Content $fil ($notis | ConvertTo-Json -Compress) -Encoding utf8
            Get-Kontext | Should -Not -Match "Ny sak i nio"
        }

        It "visar inte en sparad notis för en annan version än den installerade" {
            Invoke-SessionStart | Out-Null
            Set-Content "$script:testPlugin\VERSION" "9.9.10" -NoNewline
            Set-Content "$script:testHome\.claude\.ekan-last-version" "9.9.10" -NoNewline
            Get-Kontext | Should -Not -Match "Ny sak i nio"
        }

        It "en återupptagen session varken visar eller förbrukar notisen" {
            $ut = ('{"source":"resume","session_id":"x"}' | & $script:ScriptPath) -join "`n"
            ($ut | ConvertFrom-Json).hookSpecificOutput.additionalContext | Should -Not -Match "Ny sak i nio"
            (Get-Content "$script:testHome\.claude\.ekan-last-version" -Raw).Trim() | Should -Be "9.8.0"
            Get-Kontext | Should -Match "Ny sak i nio\."
        }

        It "visar inte notisen efter komprimering mitt i en session" {
            Invoke-SessionStart | Out-Null
            $ut = ('{"source":"compact"}' | & $script:ScriptPath) -join "`n"
            ($ut | ConvertFrom-Json).hookSpecificOutput.additionalContext | Should -Not -Match "Ny sak i nio"
        }

        It "visar notisen efter /clear" {
            Invoke-SessionStart | Out-Null
            $ut = ('{"source":"clear"}' | & $script:ScriptPath) -join "`n"
            ($ut | ConvertFrom-Json).hookSpecificOutput.additionalContext | Should -Match "Ny sak i nio\."
        }

        It "klarar en trasig notisfil" {
            Set-Content "$script:testHome\.claude\.ekan-last-version" "9.9.9" -NoNewline
            Set-Content "$script:testHome\.claude\.ekan-update-notice.json" "{inte json" -Encoding utf8
            { Invoke-SessionStart | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    It "läser å, ä och ö rätt under Windows PowerShell 5.1" {
        # hooks.json startar hooken med `powershell`, alltså 5.1, som läser
        # filer som ANSI om kodningen inte anges.
        Skriv-Changelog "## 9.9.9 — 2026-10-09`n`n### För konsulten`n`n- Rättat så att å, ä och ö syns.`n"
        $forra = [Console]::OutputEncoding
        try {
            [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
            $txt = (& powershell -NoProfile -ExecutionPolicy Bypass -File $script:ScriptPath) -join "`n"
        }
        finally {
            [Console]::OutputEncoding = $forra
        }
        ($txt | ConvertFrom-Json).hookSpecificOutput.additionalContext | Should -Match "Rättat så att å, ä och ö syns\."
    }
}
