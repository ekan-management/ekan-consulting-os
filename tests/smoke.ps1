<#
.SYNOPSIS
    Sandbox-smoketest for ekan-pluginet. Kor lokalt, ingen kollega/Desktop behovs.

.DESCRIPTION
    Validerar att pluginet laddar och fungerar utan att rora ditt riktiga ~/.claude:
      1. claude plugin validate --strict  (manifest, commands, hooks, skills)
      2. SessionStart-hookarna (5.1) ger giltig UTF-8 + JSON  (ingen mojibake)
      3. /ekan:setup kor idempotent mot en slang-bort HOME (plugin-vagen wirar
         INTE hooks i settings.json)

    Allt isoleras till temp-kataloger som stadas bort efter korning.

.EXAMPLE
    pwsh -File tests/smoke.ps1
#>
param(
    [string]$PluginDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$ClaudeCli = 'claude'
)

$ErrorActionPreference = 'Continue'
$results = [System.Collections.Generic.List[object]]::new()
function Add-Result($name, $ok, $msg) {
    $results.Add([pscustomobject]@{ Name = $name; Ok = [bool]$ok; Msg = $msg })
    $tag = if ($ok) { 'PASS' } else { 'FAIL' }
    Write-Host ("[{0}] {1} - {2}" -f $tag, $name, $msg)
}

Write-Host "Smoketest av plugin: $PluginDir`n"

# --- 1. Manifest-validering (CI-grade) -------------------------------------
$valOut = & $ClaudeCli plugin validate $PluginDir --strict 2>&1
$valOk = ($LASTEXITCODE -eq 0)
Add-Result 'plugin validate --strict' $valOk (($valOut | Select-Object -Last 1) -join ' ')

# --- 2. SessionStart-hookar: giltig UTF-8 + JSON ---------------------------
$ps51 = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
function Test-HookUtf8($relPath, $expect) {
    $script = Join-Path $PluginDir $relPath
    if (-not (Test-Path $ps51)) { Add-Result "hook $relPath" $true 'Windows PowerShell 5.1 saknas - hoppar over'; return }
    $out = [System.IO.Path]::GetTempFileName()
    # Isolerad HOME: hookarna skriver state (.ekan-last-version) och synkar
    # consulting/CLAUDE.md - utan detta muterar checken utvecklarens riktiga
    # ~/.claude och blir dessutom flaky (ping vid versionsskillnad).
    $hookHome = Join-Path ([System.IO.Path]::GetTempPath()) ('ekan-smoke-hook-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path (Join-Path $hookHome '.claude') -Force | Out-Null
    $origProfile = $env:USERPROFILE
    try {
        $env:USERPROFILE = $hookHome
        & cmd /c "`"$ps51`" -NoProfile -ExecutionPolicy Bypass -File `"$script`" > `"$out`"" 2>$null
    }
    finally {
        $env:USERPROFILE = $origProfile
        Remove-Item $hookHome -Recurse -Force -ErrorAction SilentlyContinue
    }
    $bytes = [System.IO.File]::ReadAllBytes($out)
    Remove-Item $out -Force -ErrorAction SilentlyContinue
    $strict = [System.Text.UTF8Encoding]::new($false, $true)
    try { $txt = $strict.GetString($bytes) }
    catch { Add-Result "hook $relPath" $false 'stdout ar inte giltig UTF-8 (mojibake)'; return }
    try { $json = $txt | ConvertFrom-Json }
    catch { Add-Result "hook $relPath" $false 'stdout ar inte giltig JSON'; return }
    # Sedan 3.9.3 ligger additionalContext i hookSpecificOutput, där Claude Code läser den.
    $ctx = $json.hookSpecificOutput.additionalContext
    if (-not $ctx) { Add-Result "hook $relPath" $false 'saknar hookSpecificOutput.additionalContext'; return }
    if ($expect -and ($ctx -notmatch $expect)) {
        Add-Result "hook $relPath" $false "additionalContext saknar forvantad text '$expect'"; return
    }
    Add-Result "hook $relPath" $true 'giltig UTF-8 JSON med additionalContext'
}
Test-HookUtf8 'hooks/session-start.ps1'    'Ekan-plugin'
Test-HookUtf8 'hooks/compact-reminder.ps1' 'komprimering'

# --- 3. /ekan:setup mot isolerad HOME --------------------------------------
$sandboxHome = Join-Path ([System.IO.Path]::GetTempPath()) ('ekan-smoke-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $sandboxHome -Force | Out-Null
try {
    $setup = Join-Path $PluginDir 'hooks/ekan-setup.ps1'
    # Kör setup i SAMMA värd som smoketestet startats i. Hårdkodat 'pwsh' gjorde
    # att en körning under Windows PowerShell 5.1 ändå testade PowerShell 7 —
    # alltså aldrig den värd hooks.json faktiskt använder.
    $vard = (Get-Process -Id $PID).Path
    & $vard -NoProfile -ExecutionPolicy Bypass -File $setup -TestMode -UserHome $sandboxHome -PluginRoot $PluginDir -SkipPython *> $null
    $setupCode = $LASTEXITCODE
    $consultMd = Test-Path (Join-Path $sandboxHome 'consulting/CLAUDE.md')
    # Mallarna ingår inte i pluginet sedan 3.12.0; setup ska bara skapa mappen.
    $mallmapp = Test-Path (Join-Path $sandboxHome 'consulting/templates')
    $settingsPath = Join-Path $sandboxHome '.claude/settings.json'
    $hooksWired = $false
    if (Test-Path $settingsPath) {
        $s = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $hooksWired = [bool]$s.hooks
    }
    $setupOk = ($setupCode -eq 0) -and $consultMd -and (-not $hooksWired) -and $mallmapp
    $detail = "exit=$setupCode, consulting/CLAUDE.md=$consultMd, templates-mapp=$mallmapp, hooks-i-settings=$hooksWired (ska vara False - plugin-vagen)"
    Add-Result '/ekan:setup (TestMode, isolerad HOME)' $setupOk $detail
}
finally {
    Remove-Item $sandboxHome -Recurse -Force -ErrorAction SilentlyContinue
}

# --- Sammanfattning --------------------------------------------------------
$failed = @($results | Where-Object { -not $_.Ok })
Write-Host ("`n{0}/{1} checkar gick igenom." -f ($results.Count - $failed.Count), $results.Count)
if ($failed.Count) { Write-Host "SMOKETEST FAILED"; exit 1 }
Write-Host "SMOKETEST OK"; exit 0
