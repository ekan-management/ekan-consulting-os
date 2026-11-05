# Pester 5 tester för filkodning.
# Kör: Invoke-Pester -Path tests/encoding.Tests.ps1 -Output Detailed
#
# Bakgrund: Windows PowerShell 5.1 antar Windows-1252 för .ps1-filer utan
# UTF-8 BOM. Svenska tecken läses då som fel byte-par, och råkar något av dem
# tolkas som citattecken bryts parsningen helt (nytt-projekt.ps1 gav 68
# parse-fel innan BOM lades till). PowerShell 7 antar UTF-8 och märker inget.
# hooks.json startar hookar med `powershell` (5.1) — därför måste BOM finnas,
# annars blir pwsh ett dolt krav.

BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path

    $script:PsFiles = Get-ChildItem -Path $script:RepoRoot -Filter *.ps1 -Recurse |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }
}

Describe "PowerShell-filer är UTF-8 med BOM" {
    It "hittar .ps1-filer att kontrollera" {
        $script:PsFiles.Count | Should -BeGreaterThan 0
    }

    It "alla .ps1-filer har UTF-8 BOM" {
        $utan = @()
        foreach ($f in $script:PsFiles) {
            $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
            $harBom = ($bytes.Length -ge 3 -and
                       $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
            if (-not $harBom) {
                $utan += $f.FullName.Substring($script:RepoRoot.Length + 1)
            }
        }
        $utan -join ", " | Should -BeNullOrEmpty -Because "filer utan BOM kraschar under Windows PowerShell 5.1"
    }

    It "alla .ps1-filer parsar utan fel i den aktuella värden" {
        $trasiga = @()
        foreach ($f in $script:PsFiles) {
            $fel = $null
            [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$null, [ref]$fel) | Out-Null
            if ($fel.Count) {
                $namn = $f.FullName.Substring($script:RepoRoot.Length + 1)
                $trasiga += "$namn ($($fel.Count) fel)"
            }
        }
        $trasiga -join ", " | Should -BeNullOrEmpty
    }
}
