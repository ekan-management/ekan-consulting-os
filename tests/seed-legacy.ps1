# Seedar legacy-state i en temp-profil för manuellt integration-test
param([Parameter(Mandatory)][string]$TestRoot)

New-Item -ItemType Directory -Path "$TestRoot/.claude/hooks" -Force | Out-Null
New-Item -ItemType Directory -Path "$TestRoot/.claude/skills/intro" -Force | Out-Null
New-Item -ItemType Directory -Path "$TestRoot/.claude/commands" -Force | Out-Null
New-Item -ItemType Directory -Path "$TestRoot/consulting" -Force | Out-Null

"stale" | Set-Content "$TestRoot/.claude/hooks/block-dangerous.ps1"
"stale" | Set-Content "$TestRoot/.claude/skills/intro/SKILL.md"
"stale" | Set-Content "$TestRoot/.claude/commands/jobb.md"
"1.4" | Set-Content "$TestRoot/.claude/.ekan-setup-version"
'{"permissions":{"allow":[],"deny":[]}}' | Set-Content "$TestRoot/.claude/settings.json"
"min MY-CLAUDE" | Set-Content "$TestRoot/consulting/MY-CLAUDE.md"

Write-Host "Legacy-state seedad i: $TestRoot"
