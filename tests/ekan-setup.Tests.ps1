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

    It "sparar en egen CLAUDE.md som .bak innan den skrivs över" {
        "min egen CLAUDE.md" | Set-Content "$script:testRoot/consulting/CLAUDE.md"
        Invoke-Setup -UserHome $script:testRoot
        (Get-Content "$script:testRoot/consulting/CLAUDE.md.bak" -Raw).Trim() | Should -Be "min egen CLAUDE.md"
    }

    It "skriver ingen .bak när CLAUDE.md redan är Ekans version" {
        Invoke-Setup -UserHome $script:testRoot
        Invoke-Setup -UserHome $script:testRoot
        Test-Path "$script:testRoot/consulting/CLAUDE.md.bak" | Should -Be $false
    }

    It "sparar ett eget hjälpskript med samma namn som .bak" {
        New-Item -ItemType Directory -Path "$script:testRoot/consulting/scripts" -Force | Out-Null
        "# mitt eget skript" | Set-Content "$script:testRoot/consulting/scripts/read_office.py"
        Invoke-Setup -UserHome $script:testRoot
        (Get-Content "$script:testRoot/consulting/scripts/read_office.py.bak" -Raw).Trim() | Should -Be "# mitt eget skript"
    }

    It "rör inte konsultens övriga skript" {
        New-Item -ItemType Directory -Path "$script:testRoot/consulting/scripts" -Force | Out-Null
        "# annat skript" | Set-Content "$script:testRoot/consulting/scripts/mitt_verktyg.py"
        Invoke-Setup -UserHome $script:testRoot
        (Get-Content "$script:testRoot/consulting/scripts/mitt_verktyg.py" -Raw).Trim() | Should -Be "# annat skript"
        Test-Path "$script:testRoot/consulting/scripts/mitt_verktyg.py.bak" | Should -Be $false
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

Describe "ekan-setup - egna hooks bevaras" {
    BeforeEach {
        $script:testRoot = New-TestEnv
        $settingsPath = "$script:testRoot/.claude/settings.json"
        # Blandning av Ekans gamla hooks och konsultens egna, i samma grupp och i
        # egna grupper. Skrivs som rå JSON så att strukturen är exakt den som
        # Claude Code läser.
        $home2 = $script:testRoot -replace '\\', '/'
        @"
{
  "permissions": { "allow": ["Read"], "deny": [] },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "powershell -NoProfile -File $home2/.claude/hooks/session-start.ps1", "timeout": 15 },
          { "type": "command", "command": "echo min egen start" }
        ]
      },
      {
        "matcher": "compact",
        "hooks": [
          { "type": "command", "command": "echo 'Påminnelse efter komprimering: Visa ALLTID projektöversikt'" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [ { "type": "command", "command": "python C:/verktyg/min-vakt.py" } ]
      }
    ]
  }
}
"@ | Set-Content $settingsPath -Encoding UTF8
    }
    AfterEach { Remove-TestEnv $script:testRoot }

    It "behåller konsultens egen hook i samma grupp som Ekans gamla" {
        Invoke-Setup -UserHome $script:testRoot
        $s = Get-Content "$script:testRoot/.claude/settings.json" -Raw | ConvertFrom-Json
        @($s.hooks.SessionStart).Count | Should -Be 1
        @($s.hooks.SessionStart[0].hooks).Count | Should -Be 1
        $s.hooks.SessionStart[0].hooks[0].command | Should -Be "echo min egen start"
    }

    It "tar bort en grupp som bara innehöll Ekans gamla hook" {
        Invoke-Setup -UserHome $script:testRoot
        $s = Get-Content "$script:testRoot/.claude/settings.json" -Raw | ConvertFrom-Json
        @($s.hooks.SessionStart | Where-Object { $_.matcher -eq "compact" }).Count | Should -Be 0
    }

    It "behåller konsultens egna händelser orörda" {
        Invoke-Setup -UserHome $script:testRoot
        $s = Get-Content "$script:testRoot/.claude/settings.json" -Raw | ConvertFrom-Json
        $s.hooks.PreToolUse[0].matcher | Should -Be "Bash"
        $s.hooks.PreToolUse[0].hooks[0].command | Should -Be "python C:/verktyg/min-vakt.py"
    }

    It "skriver kvarvarande grupper och hooks som JSON-arrayer" {
        # PowerShell 5.1 kan göra en array med ett element till ett ensamt objekt.
        # Claude Code kräver arrayer.
        Invoke-Setup -UserHome $script:testRoot
        $raw = Get-Content "$script:testRoot/.claude/settings.json" -Raw
        $raw | Should -Match '"SessionStart":\s*\['
        $raw | Should -Match '"PreToolUse":\s*\['
        $raw | Should -Match '"hooks":\s*\[\s*\{\s*"type"'
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

Describe "ekan-setup - mallmapp och slutkontroll" {
    BeforeAll {
        function New-TestMall {
            # En minimal .docx: zip-arkiv med word/document.xml.
            param([string]$Path)
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "ekan-mall-$(Get-Random)"
            New-Item -ItemType Directory -Path "$tmp/word" -Force | Out-Null
            Set-Content -Path "$tmp/word/document.xml" -Value "<w:document/>"
            if (Test-Path $Path) { Remove-Item $Path -Force }
            [System.IO.Compression.ZipFile]::CreateFromDirectory($tmp, $Path)
            Remove-Item $tmp -Recurse -Force
        }
        $script:Mallnamn = @("Mall Projektdirektiv.docx", "Mall Uppdragsdirektiv Små uppdrag.docx", "Mall anteckningar.docx")
    }
    BeforeEach {
        $script:testRoot = New-TestEnv
        $script:synkad = Join-Path $script:testRoot "Ekan AB\Kompassen - Mallar"
        New-Item -ItemType Directory -Path $script:synkad -Force | Out-Null
        foreach ($m in $script:Mallnamn) { New-TestMall -Path (Join-Path $script:synkad $m) }
    }
    AfterEach { Remove-TestEnv $script:testRoot }

    It "sparar -Mallmapp som EKAN_MALLAR i settings.json" {
        Invoke-Setup -UserHome $script:testRoot -ExtraArgs @{ Mallmapp = $script:synkad }
        $s = Get-Content "$script:testRoot/.claude/settings.json" -Raw -Encoding UTF8 | ConvertFrom-Json
        $s.env.EKAN_MALLAR | Should -Be $script:synkad
    }

    It "behåller sparad mallmapp när setup körs om utan -Mallmapp" {
        Invoke-Setup -UserHome $script:testRoot -ExtraArgs @{ Mallmapp = $script:synkad }
        Invoke-Setup -UserHome $script:testRoot
        $s = Get-Content "$script:testRoot/.claude/settings.json" -Raw -Encoding UTF8 | ConvertFrom-Json
        $s.env.EKAN_MALLAR | Should -Be $script:synkad
    }

    It "skapar inte ~/consulting/templates när mallmappen pekar på annan plats" {
        Invoke-Setup -UserHome $script:testRoot -ExtraArgs @{ Mallmapp = $script:synkad }
        Test-Path "$script:testRoot/consulting/templates" | Should -Be $false
    }

    It "skriver aldrig till mallmappen" {
        $fore = @(Get-ChildItem $script:synkad | ForEach-Object { "$($_.Name)|$($_.Length)|$($_.LastWriteTimeUtc.Ticks)" })
        Invoke-Setup -UserHome $script:testRoot -ExtraArgs @{ Mallmapp = $script:synkad }
        $efter = @(Get-ChildItem $script:synkad | ForEach-Object { "$($_.Name)|$($_.Length)|$($_.LastWriteTimeUtc.Ticks)" })
        $efter | Should -Be $fore
    }

    It "tvingar HTTPS för pluginuppdateringar" {
        Invoke-Setup -UserHome $script:testRoot
        $s = Get-Content "$script:testRoot/.claude/settings.json" -Raw -Encoding UTF8 | ConvertFrom-Json
        $s.env.CLAUDE_CODE_PLUGIN_PREFER_HTTPS | Should -Be "1"
    }

    It "-Kontroll godkänner en komplett miljö" {
        Invoke-Setup -UserHome $script:testRoot -ExtraArgs @{ Mallmapp = $script:synkad }
        $ut = & powershell -NoProfile -ExecutionPolicy Bypass -File $script:SetupScript -UserHome $script:testRoot -PluginRoot $script:PluginRoot -Kontroll 6>&1 | Out-String
        $LASTEXITCODE | Should -Be 0
        $ut | Should -Match "Allt är på plats"
        $ut | Should -Not -Match "(?m)^SAKNAS"
    }

    It "-Kontroll underkänner en mall som inte går att öppna" {
        Invoke-Setup -UserHome $script:testRoot -ExtraArgs @{ Mallmapp = $script:synkad }
        Set-Content -Path (Join-Path $script:synkad "Mall anteckningar.docx") -Value "inte en docx"
        $ut = & powershell -NoProfile -ExecutionPolicy Bypass -File $script:SetupScript -UserHome $script:testRoot -PluginRoot $script:PluginRoot -Kontroll 6>&1 | Out-String
        $LASTEXITCODE | Should -Be 1
        $ut | Should -Match "SAKNAS\s+Mall som går att öppna: Mall anteckningar\.docx"
    }

    It "-Kontroll räknar mallar som inte kopierats än som SENARE, inte som fel" {
        Invoke-Setup -UserHome $script:testRoot
        $ut = & powershell -NoProfile -ExecutionPolicy Bypass -File $script:SetupScript -UserHome $script:testRoot -PluginRoot $script:PluginRoot -Kontroll 6>&1 | Out-String
        $LASTEXITCODE | Should -Be 0
        $ut | Should -Match "SENARE\s+Mall saknas: Mall Projektdirektiv\.docx"
        $ut | Should -Not -Match "(?m)^SAKNAS"
    }

    It "-Kontroll ändrar ingenting" {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $script:SetupScript -UserHome $script:testRoot -PluginRoot $script:PluginRoot -Kontroll *> $null
        Test-Path "$script:testRoot/.claude/settings.json" | Should -Be $false
        Test-Path "$script:testRoot/consulting/CLAUDE.md" | Should -Be $false
    }

    It "lämnar en ogiltig settings.json orörd och installerar resten" {
        $trasig = '{ "permissions": { "allow": ["x"], } // kommentar'
        Set-Content -Path "$script:testRoot/.claude/settings.json" -Value $trasig -Encoding utf8
        { Invoke-Setup -UserHome $script:testRoot } | Should -Not -Throw
        (Get-Content "$script:testRoot/.claude/settings.json" -Raw).Trim() | Should -Be $trasig
        Test-Path "$script:testRoot/consulting/CLAUDE.md" | Should -Be $true
    }
}
