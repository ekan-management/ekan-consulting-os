# Pester 5 tester för onboarding-prompten i onboarding/klistra-in.md.
# Kör: Invoke-Pester -Path tests/onboarding.Tests.ps1 -Output Detailed
#
# Prompten klistras in av nya konsulter och anropar ekan-setup.ps1 med flaggor.
# Byter en flagga namn i skriptet men inte i prompten märks det först hos en
# nyanställd. Testerna håller ihop de två.

BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
    $script:Prompt = Get-Content (Join-Path $script:RepoRoot "onboarding/klistra-in.md") -Raw -Encoding UTF8
    $script:Setup = Get-Content (Join-Path $script:RepoRoot "hooks/ekan-setup.ps1") -Raw -Encoding UTF8
    $script:Version = (Get-Content (Join-Path $script:RepoRoot "VERSION") -Raw).Trim()
}

Describe "Onboarding-prompten" {
    It "använder bara flaggor som ekan-setup.ps1 har" {
        $flaggor = [regex]::Matches($script:Prompt, 'ekan-setup\.ps1"[^\r\n]*') |
            ForEach-Object { [regex]::Matches($_.Value, '\s-([A-Za-z]+)') } |
            ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
        $flaggor | Should -Not -BeNullOrEmpty
        foreach ($f in $flaggor) {
            $script:Setup | Should -Match "\`$$f\b" -Because "prompten anropar setup med -$f"
        }
    }

    It "nämner -Yes bara som svar på en bekräftelse" {
        $script:Prompt | Should -Match 'fråga om de ska tas bort och kör i så fall om med `-Yes`'
    }

    It "innehåller ingen intern adress" {
        # Repot är publikt. Prompten ska gå att klistra in som den är, utan
        # adresser till Ekans Teamsytor och utan platshållare att fylla i.
        $script:Prompt | Should -Not -Match 'sharepoint\.com'
        $script:Prompt | Should -Not -Match '\{\{'
    }

    It "håller Claude borta från synkade mappar" {
        # Ekan har inte riskbedömt att Claude läser i Teamsytor. Prompten får
        # varken leta i synkade mappar eller peka mallmappen dit.
        $script:Prompt | Should -Match 'Öppna aldrig mappar som synkas från Teams eller OneDrive'
        $script:Prompt | Should -Not -Match 'OneDriveCommercial'
        $script:Prompt | Should -Not -Match '(?i)-Mallmapp'
    }

    It "anger en pluginversion som inte är nyare än VERSION" {
        $script:Prompt -match 'Gäller plugin (\d+\.\d+\.\d+)' | Should -Be $true
        ([version]$Matches[1]) -le ([version]$script:Version) | Should -Be $true
    }

    It "ber aldrig konsulten öppna en terminal" {
        $script:Prompt | Should -Not -Match '(?i)öppna (en )?(terminal|kommandotolk|powershell)(?! eller)'
    }
}
