# Pester 5 tester för versionskonsistens.
# Kör: Invoke-Pester -Path tests/version.Tests.ps1 -Output Detailed
#
# Bakgrund: en release kräver att tre ställen håller ihop — VERSION (läses av
# session-start.ps1 för update-pingen), .claude-plugin/plugin.json (avgör om
# användare får uppdateringen) och CHANGELOG.md. Divergerar de tystnar antingen
# pingen eller uppdateringen. Marketplace-repot ekan-plugins måste dessutom
# bumpas separat; det kan inte kontrolleras härifrån, se ROADMAP.

BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
    $script:Version = (Get-Content (Join-Path $script:RepoRoot "VERSION") -Raw).Trim()
    $script:Manifest = Get-Content (Join-Path $script:RepoRoot ".claude-plugin/plugin.json") -Raw | ConvertFrom-Json
    # -Encoding UTF8: Windows PowerShell 5.1 läser annars filen som ANSI, och
    # "För konsulten" matchar aldrig.
    $script:Changelog = Get-Content (Join-Path $script:RepoRoot "CHANGELOG.md") -Raw -Encoding UTF8
}

Describe "Versionskonsistens" {
    It "VERSION följer semver" {
        $script:Version | Should -Match '^\d+\.\d+\.\d+$'
    }

    It "plugin.json har ett version-fält" {
        # Utan fältet faller `claude plugin validate --strict` på en varning,
        # och uppdateringar styrs i stället av commit-SHA.
        $script:Manifest.version | Should -Not -BeNullOrEmpty
    }

    It "plugin.json:s version matchar VERSION" {
        $script:Manifest.version | Should -Be $script:Version -Because "annars får konsulterna inte uppdateringen trots att VERSION bumpats"
    }

    It "CHANGELOG.md har en post för aktuell version" {
        $script:Changelog | Should -Match ([regex]::Escape("## $script:Version")) -Because "en release utan changelog-post går inte att härleda i efterhand"
    }

    It "CHANGELOG-posten för aktuell version har klarspråksrader under För konsulten" {
        # session-start.ps1 visar raderna för konsulten efter uppdateringen.
        # Saknas de får konsulten bara veta att något ändrats, inte vad.
        $post = ($script:Changelog -split "(?m)^## ") |
            Where-Object { $_ -match "^$([regex]::Escape($script:Version))\b" } |
            Select-Object -First 1
        $post | Should -Match "(?m)^### För konsulten\s*\r?\n\s*\r?\n- \S" -Because "konsulten ska få veta vad som är nytt i klarspråk"
    }
}
