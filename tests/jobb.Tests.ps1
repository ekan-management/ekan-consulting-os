# Pester 5 tester för hooks/jobb.ps1 — vilka rader som blir öppna uppgifter.
# Kör: Invoke-Pester -Path tests/jobb.Tests.ps1 -Output Detailed
#
# Isolerar $env:USERPROFILE till en temp-katalog så riktiga ~/consulting aldrig rörs.

BeforeAll {
    $script:ScriptPath = (Resolve-Path "$PSScriptRoot/../hooks/jobb.ps1").Path

    function New-Projekt($namn, $innehall) {
        $dir = Join-Path $script:testHome "consulting\projects\$namn"
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $dir "CLAUDE.md"), $innehall, [System.Text.UTF8Encoding]::new($false))
    }

    function Invoke-Jobb {
        # Write-Host går till informationsströmmen (6) och fångas därifrån.
        (& $script:ScriptPath 6>&1 | Out-String)
    }
}

Describe "jobb.ps1 — öppna uppgifter" {
    BeforeEach {
        $script:origHome = $env:USERPROFILE
        $script:origEncoding = [Console]::OutputEncoding
        $script:testHome = Join-Path ([System.IO.Path]::GetTempPath()) "jobb-home-$(Get-Random)"
        New-Item -ItemType Directory -Path "$script:testHome\consulting\projects" -Force | Out-Null
        $env:USERPROFILE = $script:testHome
    }
    AfterEach {
        $env:USERPROFILE = $script:origHome
        [Console]::OutputEncoding = $script:origEncoding
        Remove-Item $script:testHome -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "tar med punkter under en underrubrik till Öppet" {
        # Frågorna ligger under ### direkt efter ## Öppet.
        New-Projekt "exempelstaden" @"
# Projekt

## Öppet

### Frågor som väntar på svar

- **Ärendevolymen.** Hur många ärenden per månad
- **Helårsvolymer.** Fråga beställaren

### Avgjort 22 september

- Lokalkostnaden räknas på 50 procent

## Plan

- Slutpresentation 14 okt
"@
        $ut = Invoke-Jobb
        $ut | Should -Match '=== exempelstaden ==='
        $ut | Should -Match 'Ärendevolymen'
        $ut | Should -Match 'Helårsvolymer'
        # "### Avgjort" är en avslutsrubrik — dess punkter är klara, inte öppna.
        $ut | Should -Not -Match 'Lokalkostnaden'
    }

    It "stänger Öppet vid en avslutsrubrik, oavsett djup" {
        New-Projekt "p" @"
## Öppet

### Avgjort 1 september

- Redan löst, inte en uppgift

### Nya frågor

- Också stängd — kommer efter en avslutsrubrik på samma nivå
"@
        $ut = Invoke-Jobb
        $ut | Should -Not -Match 'Redan löst'
        $ut | Should -Not -Match 'Också stängd'
    }

    It "avslutar Öppet vid nästa rubrik på samma nivå" {
        New-Projekt "p" @"
## Öppet

### Frågor

- Öppen fråga

## Plan

- Planpunkt som inte är en uppgift
"@
        $ut = Invoke-Jobb
        $ut | Should -Match 'Öppen fråga'
        $ut | Should -Not -Match 'Planpunkt'
    }

    It "avslutar Öppet vid en överordnad rubrik" {
        New-Projekt "p" @"
## Status

### Öppna frågor

- Öppen fråga

## Team

- Teammedlem
"@
        $ut = Invoke-Jobb
        $ut | Should -Match 'Öppen fråga'
        $ut | Should -Not -Match 'Teammedlem'
    }

    It "räknar inte avklarade och skippade punkter under Öppet" {
        New-Projekt "p" @"
## Öppet

### Frågor

- [x] Klar sak
- [~] Parkerad sak
- Kvar att göra
"@
        $ut = Invoke-Jobb
        $ut | Should -Match 'Kvar att göra'
        $ut | Should -Not -Match 'Klar sak'
        $ut | Should -Not -Match 'Parkerad sak'
    }

    It "visar inte ett projekt vars punkter alla är parkerade" {
        New-Projekt "parkerat" @"
## Roadmap

- [~] Parkerad punkt
"@
        Invoke-Jobb | Should -Not -Match 'parkerat'
    }
}
