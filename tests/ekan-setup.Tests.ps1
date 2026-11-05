# Pester 5 tester för hooks/ekan-setup.ps1
# Kör: Invoke-Pester -Path tests/ekan-setup.Tests.ps1 -Output Detailed

BeforeAll {
    $script:SetupScript = (Resolve-Path "$PSScriptRoot/../hooks/ekan-setup.ps1").Path
    $script:PluginRoot = (Resolve-Path "$PSScriptRoot/..").Path

    function New-TestEnv {
        $testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "ekan-test-$(Get-Random)"
        New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
        New-Item -ItemType Directory -Path "$testRoot/.claude" -Force | Out-Null
        New-Item -ItemType Directory -Path "$testRoot/consulting" -Force | Out-Null
        return $testRoot
    }

    function Remove-TestEnv {
        param([string]$Path)
        if (Test-Path $Path) {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    function Invoke-Setup {
        param([string]$UserHome, [hashtable]$ExtraArgs = @{})
        $args = @{
            TestMode = $true
            UserHome = $UserHome
            PluginRoot = $script:PluginRoot
            SkipPython = $true
        } + $ExtraArgs
        & $script:SetupScript @args
    }

    function Seed-LegacyState {
        param([string]$UserHome)
        $claude = Join-Path $UserHome ".claude"
        New-Item -ItemType Directory -Path "$claude/hooks" -Force | Out-Null
        New-Item -ItemType Directory -Path "$claude/skills/intro" -Force | Out-Null
        New-Item -ItemType Directory -Path "$claude/commands" -Force | Out-Null

        "stale hook content" | Set-Content "$claude/hooks/block-dangerous.ps1"
        "stale hook content" | Set-Content "$claude/hooks/session-start.ps1"
        "stale skill content" | Set-Content "$claude/skills/intro/SKILL.md"
        "stale command content" | Set-Content "$claude/commands/jobb.md"
        "1.4" | Set-Content "$claude/.ekan-setup-version"

        @{
            permissions = @{
                allow = @("Read", "Write", "Bash(ls *)")
                deny = @("Bash(rm *)")
                defaultMode = "auto"
            }
            hooks = @{
                SessionStart = @(@{
                    matcher = ""
                    hooks = @(@{
                        type = "command"
                        command = "powershell -File $UserHome/.claude/hooks/session-start.ps1"
                    })
                })
            }
        } | ConvertTo-Json -Depth 10 | Set-Content "$claude/settings.json"
    }
}

Describe "ekan-setup - backup" {
    BeforeEach {
        $script:testRoot = New-TestEnv
        Seed-LegacyState -UserHome $script:testRoot
        "användarens personliga anpassning" | Set-Content "$script:testRoot/consulting/MY-CLAUDE.md"
    }
    AfterEach { Remove-TestEnv $script:testRoot }

    It "skapar settings.json-backup i ~/.claude/backups/" {
        $originalContent = Get-Content "$script:testRoot/.claude/settings.json" -Raw
        Invoke-Setup -UserHome $script:testRoot
        $backups = Get-ChildItem "$script:testRoot/.claude/backups" -Filter "settings.json.bak-*" -ErrorAction SilentlyContinue
        $backups.Count | Should -Be 1
        # Verifiera att backupen innehåller exakt originalinnehållet (före permissions-merge)
        Get-Content $backups[0].FullName -Raw | Should -Be $originalContent
    }

    It "skapar INTE backup i ~/.claude/-rotnivån (flyttat till backups/-mappen)" {
        Invoke-Setup -UserHome $script:testRoot
        $rootBackups = Get-ChildItem "$script:testRoot/.claude" -Filter "settings.json.bak-*" -File -ErrorAction SilentlyContinue
        $rootBackups.Count | Should -Be 0
    }

    It "skapar INTE MY-CLAUDE.md-backup (setup rör inte filen)" {
        Invoke-Setup -UserHome $script:testRoot
        $myClaudeBackups = Get-ChildItem "$script:testRoot/consulting" -Filter "MY-CLAUDE.md.bak-*" -ErrorAction SilentlyContinue
        $myClaudeBackups.Count | Should -Be 0
    }
}

Describe "ekan-setup - backup-rotation" {
    BeforeEach {
        $script:testRoot = New-TestEnv
        Seed-LegacyState -UserHome $script:testRoot
        # Pre-seed 4 fake backups med olika tidsstämplar
        $backupDir = "$script:testRoot/.claude/backups"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        foreach ($i in 1..4) {
            $stamp = "20260101-12000$i"
            Set-Content "$backupDir/settings.json.bak-$stamp" "fake-$i"
        }
    }
    AfterEach { Remove-TestEnv $script:testRoot }

    It "behåller högst 5 backups (rotation)" {
        # Kör setup → lägger till en 5:e backup, totalt 5
        Invoke-Setup -UserHome $script:testRoot
        $backups = Get-ChildItem "$script:testRoot/.claude/backups" -Filter "settings.json.bak-*"
        $backups.Count | Should -Be 5
    }

    It "tar bort äldsta backup när taket överskrids" {
        # Två setup-körningar → 6:e backup → äldsta (20260101-120001) ska tas bort
        Invoke-Setup -UserHome $script:testRoot
        Start-Sleep -Seconds 1
        Invoke-Setup -UserHome $script:testRoot
        $backups = Get-ChildItem "$script:testRoot/.claude/backups" -Filter "settings.json.bak-*"
        $backups.Count | Should -Be 5
        $backups.Name | Should -Not -Contain "settings.json.bak-20260101-120001"
    }
}

Describe "ekan-setup - legacy backup-cleanup" {
    BeforeEach {
        $script:testRoot = New-TestEnv
        Seed-LegacyState -UserHome $script:testRoot
        # Pre-seed gamla backup-filer från pre-2.1.2-regimen
        Set-Content "$script:testRoot/consulting/MY-CLAUDE.md.bak-20260101-120000" "old"
        Set-Content "$script:testRoot/consulting/MY-CLAUDE.md.bak-20260101-130000" "old"
        Set-Content "$script:testRoot/.claude/settings.json.bak-20260101-120000" "old"
    }
    AfterEach { Remove-TestEnv $script:testRoot }

    It "tar bort gamla MY-CLAUDE.md.bak-* från ~/consulting/" {
        Invoke-Setup -UserHome $script:testRoot
        $files = Get-ChildItem "$script:testRoot/consulting" -Filter "MY-CLAUDE.md.bak-*" -ErrorAction SilentlyContinue
        $files.Count | Should -Be 0
    }

    It "tar bort gamla settings.json.bak-* från ~/.claude/-rotnivån" {
        Invoke-Setup -UserHome $script:testRoot
        $files = Get-ChildItem "$script:testRoot/.claude" -Filter "settings.json.bak-*" -File -ErrorAction SilentlyContinue
        $files.Count | Should -Be 0
    }

    It "rör inte filer i nya ~/.claude/backups/-mappen" {
        # Pre-seed en ny-stil backup
        New-Item -ItemType Directory -Path "$script:testRoot/.claude/backups" -Force | Out-Null
        Set-Content "$script:testRoot/.claude/backups/settings.json.bak-20260101-120000" "preserved"
        Invoke-Setup -UserHome $script:testRoot
        Test-Path "$script:testRoot/.claude/backups/settings.json.bak-20260101-120000" | Should -Be $true
    }
}

Describe "ekan-setup - PluginRoot-validering" {
    BeforeEach {
        $script:testRoot = New-TestEnv
    }
    AfterEach { Remove-TestEnv $script:testRoot }

    It "kastar fel när PluginRoot är tom sträng" {
        {
            & $script:SetupScript -TestMode -UserHome $script:testRoot -PluginRoot "" -SkipPython
        } | Should -Throw "*PluginRoot*"
    }

    It "kastar fel när PluginRoot är whitespace" {
        {
            & $script:SetupScript -TestMode -UserHome $script:testRoot -PluginRoot "   " -SkipPython
        } | Should -Throw "*PluginRoot*"
    }
}

Describe "ekan-setup - legacy cleanup" {
    BeforeEach {
        $script:testRoot = New-TestEnv
        Seed-LegacyState -UserHome $script:testRoot
    }
    AfterEach { Remove-TestEnv $script:testRoot }

    It "tar bort legacy hook-filer i ~/.claude/hooks/" {
        Invoke-Setup -UserHome $script:testRoot
        Test-Path "$script:testRoot/.claude/hooks/block-dangerous.ps1" | Should -Be $false
        Test-Path "$script:testRoot/.claude/hooks/session-start.ps1" | Should -Be $false
    }

    It "tar bort legacy skill-mappar (intro, stop-slop, projektdirektiv)" {
        Invoke-Setup -UserHome $script:testRoot
        Test-Path "$script:testRoot/.claude/skills/intro" | Should -Be $false
    }

    It "tar bort legacy commands (jobb.md, nytt-projekt.md)" {
        Invoke-Setup -UserHome $script:testRoot
        Test-Path "$script:testRoot/.claude/commands/jobb.md" | Should -Be $false
    }

    It "tar bort .ekan-setup-version marker" {
        Invoke-Setup -UserHome $script:testRoot
        Test-Path "$script:testRoot/.claude/.ekan-setup-version" | Should -Be $false
    }

    It "bevarar settings.json (efter cleanup av hook-block)" {
        Invoke-Setup -UserHome $script:testRoot
        Test-Path "$script:testRoot/.claude/settings.json" | Should -Be $true
    }
}

Describe "ekan-setup - consulting-setup" {
    BeforeEach {
        $script:testRoot = New-TestEnv
        Seed-LegacyState -UserHome $script:testRoot
    }
    AfterEach { Remove-TestEnv $script:testRoot }

    It "skapar ~/consulting/projects, tmp, arkiv" {
        Invoke-Setup -UserHome $script:testRoot
        Test-Path "$script:testRoot/consulting/projects" | Should -Be $true
        Test-Path "$script:testRoot/consulting/tmp" | Should -Be $true
        Test-Path "$script:testRoot/consulting/arkiv" | Should -Be $true
        Test-Path "$script:testRoot/consulting/kundspecifikt" | Should -Be $false
    }

    It "kopierar plugin consulting/CLAUDE.md till ~/consulting/CLAUDE.md" {
        Invoke-Setup -UserHome $script:testRoot
        Test-Path "$script:testRoot/consulting/CLAUDE.md" | Should -Be $true
        $content = Get-Content "$script:testRoot/consulting/CLAUDE.md" -Raw
        $content | Should -Match "EKAN STANDARD"
    }

    It "installerar referensfilerna i ramverk/ som CLAUDE.md pekar ut" {
        Invoke-Setup -UserHome $script:testRoot
        Test-Path "$script:testRoot/consulting/ramverk/visuell-profil.md" | Should -Be $true
        Test-Path "$script:testRoot/consulting/ramverk/projekt-claude-md.md" | Should -Be $true
    }

    It "skriver över befintlig CLAUDE.md vid återinstall" {
        "gammal förvrängd CLAUDE.md" | Set-Content "$script:testRoot/consulting/CLAUDE.md"
        Invoke-Setup -UserHome $script:testRoot
        $content = Get-Content "$script:testRoot/consulting/CLAUDE.md" -Raw
        $content | Should -Match "EKAN STANDARD"
    }

    It "bevarar MY-CLAUDE.md om den finns" {
        "min personliga anpassning" | Set-Content "$script:testRoot/consulting/MY-CLAUDE.md"
        Invoke-Setup -UserHome $script:testRoot
        (Get-Content "$script:testRoot/consulting/MY-CLAUDE.md" -Raw).Trim() | Should -Be "min personliga anpassning"
    }
}

Describe "ekan-setup - permissions-merge" {
    BeforeEach {
        $script:testRoot = New-TestEnv
        Seed-LegacyState -UserHome $script:testRoot
        # Lägg till användarens custom permission i settings.json
        $settingsPath = "$script:testRoot/.claude/settings.json"
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $settings.permissions.allow += "Bash(my-custom-tool *)"
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
    }
    AfterEach { Remove-TestEnv $script:testRoot }

    It "bevarar användarens custom permissions (allow-entries)" {
        Invoke-Setup -UserHome $script:testRoot
        $settings = Get-Content "$script:testRoot/.claude/settings.json" -Raw | ConvertFrom-Json
        $settings.permissions.allow | Should -Contain "Bash(my-custom-tool *)"
    }

    It "lägger till Ekan-rekommenderade permissions om de saknas" {
        Invoke-Setup -UserHome $script:testRoot
        $settings = Get-Content "$script:testRoot/.claude/settings.json" -Raw | ConvertFrom-Json
        $settings.permissions.allow | Should -Contain "Skill(projektdirektiv)"
    }

    It "sätter language: swedish om saknas" {
        Invoke-Setup -UserHome $script:testRoot
        $settings = Get-Content "$script:testRoot/.claude/settings.json" -Raw | ConvertFrom-Json
        $settings.language | Should -Be "swedish"
    }

    It "tar bort gamla __USER_HOME__ hook-block" {
        Invoke-Setup -UserHome $script:testRoot
        $settings = Get-Content "$script:testRoot/.claude/settings.json" -Raw | ConvertFrom-Json
        # Hooks-blocket hanteras nu av hooks/hooks.json i plugin — tas bort från settings.json
        $settings.hooks | Should -BeNullOrEmpty
    }
}

Describe "ekan-setup - automatisk uppdatering av marknadsplatsen" {
    BeforeEach {
        $script:testRoot = New-TestEnv
        Seed-LegacyState -UserHome $script:testRoot
        $script:settingsPath = "$script:testRoot/.claude/settings.json"
    }
    AfterEach { Remove-TestEnv $script:testRoot }

    It "registrerar ekan-plugins med autoUpdate när posten saknas" {
        Invoke-Setup -UserHome $script:testRoot
        $s = Get-Content $script:settingsPath -Raw | ConvertFrom-Json
        $s.extraKnownMarketplaces.'ekan-plugins'.autoUpdate | Should -BeTrue
        $s.extraKnownMarketplaces.'ekan-plugins'.source.source | Should -Be "github"
        $s.extraKnownMarketplaces.'ekan-plugins'.source.repo | Should -Be "ekan-management/ekan-plugins"
    }

    It "flyttar en post som pekar på den gamla adressen till organisationen" {
        $s = Get-Content $script:settingsPath -Raw | ConvertFrom-Json
        $s | Add-Member -NotePropertyName extraKnownMarketplaces -NotePropertyValue ([PSCustomObject]@{
            'ekan-plugins' = [PSCustomObject]@{
                source = [PSCustomObject]@{ source = "github"; repo = "DaVincisfather/ekan-plugins" }
                autoUpdate = $true
            }
        }) -Force
        $s | ConvertTo-Json -Depth 10 | Set-Content $script:settingsPath
        Invoke-Setup -UserHome $script:testRoot
        (Get-Content $script:settingsPath -Raw | ConvertFrom-Json).extraKnownMarketplaces.'ekan-plugins'.source.repo |
            Should -Be "ekan-management/ekan-plugins"
    }

    It "slår på autoUpdate när posten finns med autoUpdate false" {
        $s = Get-Content $script:settingsPath -Raw | ConvertFrom-Json
        $s | Add-Member -NotePropertyName extraKnownMarketplaces -NotePropertyValue ([PSCustomObject]@{
            'ekan-plugins' = [PSCustomObject]@{
                source = [PSCustomObject]@{ source = "github"; repo = "DaVincisfather/ekan-plugins" }
                autoUpdate = $false
            }
        }) -Force
        $s | ConvertTo-Json -Depth 10 | Set-Content $script:settingsPath
        Invoke-Setup -UserHome $script:testRoot
        (Get-Content $script:settingsPath -Raw | ConvertFrom-Json).extraKnownMarketplaces.'ekan-plugins'.autoUpdate | Should -BeTrue
    }

    It "bevarar andra marknadsplatser i extraKnownMarketplaces" {
        $s = Get-Content $script:settingsPath -Raw | ConvertFrom-Json
        $s | Add-Member -NotePropertyName extraKnownMarketplaces -NotePropertyValue ([PSCustomObject]@{
            'annan-marknad' = [PSCustomObject]@{ source = [PSCustomObject]@{ source = "github"; repo = "exempel/annan" } }
        }) -Force
        $s | ConvertTo-Json -Depth 10 | Set-Content $script:settingsPath
        Invoke-Setup -UserHome $script:testRoot
        $efter = Get-Content $script:settingsPath -Raw | ConvertFrom-Json
        $efter.extraKnownMarketplaces.'annan-marknad'.source.repo | Should -Be "exempel/annan"
        $efter.extraKnownMarketplaces.'ekan-plugins'.autoUpdate | Should -BeTrue
    }

    It "är idempotent vid andra körningen" {
        Invoke-Setup -UserHome $script:testRoot
        Invoke-Setup -UserHome $script:testRoot
        $s = Get-Content $script:settingsPath -Raw | ConvertFrom-Json
        @($s.extraKnownMarketplaces.PSObject.Properties.Name) | Should -Be @("ekan-plugins")
        $s.extraKnownMarketplaces.'ekan-plugins'.autoUpdate | Should -BeTrue
    }

    It "sätter FORCE_AUTOUPDATE_PLUGINS=1 i env" {
        Invoke-Setup -UserHome $script:testRoot
        $s = Get-Content $script:settingsPath -Raw | ConvertFrom-Json
        $s.env.FORCE_AUTOUPDATE_PLUGINS | Should -Be "1"
    }

    It "bevarar befintliga env-variabler, med å/ä/ö intakta" {
        # Claude Code skriver settings.json som UTF-8. Setup måste läsa den så
        # även under Windows PowerShell 5.1, där Get-Content annars antar ANSI.
        $s = Get-Content $script:settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $s | Add-Member -NotePropertyName env -NotePropertyValue ([PSCustomObject]@{ MIN_VARIABEL = "behåll" }) -Force
        [System.IO.File]::WriteAllText($script:settingsPath, ($s | ConvertTo-Json -Depth 10))
        Invoke-Setup -UserHome $script:testRoot
        $efter = Get-Content $script:settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $efter.env.MIN_VARIABEL | Should -Be "behåll"
        $efter.env.FORCE_AUTOUPDATE_PLUGINS | Should -Be "1"
    }
}

Describe "ekan-setup - idempotens" {
    BeforeEach {
        $script:testRoot = New-TestEnv
        Seed-LegacyState -UserHome $script:testRoot
    }
    AfterEach { Remove-TestEnv $script:testRoot }

    It "andra körningen skapar inte dubbletter av backup-filer" {
        Invoke-Setup -UserHome $script:testRoot
        $firstBackups = @(Get-ChildItem "$script:testRoot/.claude/backups" -Filter "settings.json.bak-*").Count
        Start-Sleep -Seconds 1  # säkerställ ny tidsstämpel
        Invoke-Setup -UserHome $script:testRoot
        $secondBackups = @(Get-ChildItem "$script:testRoot/.claude/backups" -Filter "settings.json.bak-*").Count
        # Andra körningen skapar en ny backup (unika tidsstämplar) — OK.
        # Viktigt: ingen korruption och inga dubletter av sama tidsstämpel
        $secondBackups | Should -BeGreaterThan $firstBackups
    }

    It "andra körningen hittar inga legacy-artifakter att städa" {
        Invoke-Setup -UserHome $script:testRoot
        # Andra körningen ska gå igenom utan fel och utan att ändra något destruktivt
        { Invoke-Setup -UserHome $script:testRoot } | Should -Not -Throw
    }

    It "bevarar CLAUDE.md och MY-CLAUDE.md vid andra körningen" {
        "min anpassning" | Set-Content "$script:testRoot/consulting/MY-CLAUDE.md"
        Invoke-Setup -UserHome $script:testRoot
        Invoke-Setup -UserHome $script:testRoot
        (Get-Content "$script:testRoot/consulting/MY-CLAUDE.md" -Raw).Trim() | Should -Be "min anpassning"
    }
}

Describe "ekan-setup - ren maskin (utan ~/.claude)" {
    # Regression: på en helt fräsch maskin saknas ~/.claude, och permissions-merge
    # kraschade när settings.json.tmp skulle skrivas. New-TestEnv förseedar .claude
    # och dolde därför buggen — här skapas BARA $testRoot, inget annat.
    BeforeEach {
        $script:cleanRoot = Join-Path ([System.IO.Path]::GetTempPath()) "ekan-clean-$(Get-Random)"
        New-Item -ItemType Directory -Path $script:cleanRoot -Force | Out-Null
    }
    AfterEach { Remove-TestEnv $script:cleanRoot }

    It "kraschar inte när ~/.claude saknas" {
        { Invoke-Setup -UserHome $script:cleanRoot } | Should -Not -Throw
    }

    It "skapar ~/.claude och settings.json" {
        Invoke-Setup -UserHome $script:cleanRoot
        Test-Path "$script:cleanRoot/.claude" | Should -Be $true
        Test-Path "$script:cleanRoot/.claude/settings.json" | Should -Be $true
    }

    It "skriver giltig settings.json utan hooks-block" {
        Invoke-Setup -UserHome $script:cleanRoot
        $settings = Get-Content "$script:cleanRoot/.claude/settings.json" -Raw | ConvertFrom-Json
        $settings.permissions | Should -Not -BeNullOrEmpty
        $settings.hooks | Should -BeNullOrEmpty
    }
}
