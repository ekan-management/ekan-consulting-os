# compact-reminder.ps1
# Injicerar påminnelse efter komprimering (SessionStart matcher "compact").
# Egen UTF-8-medveten hook i stället för rå `echo` — undviker citat-/teckenproblem
# mellan olika skal (cmd.exe vs sh) och kodsidor.

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# Claude Code läser additionalContext bara inuti hookSpecificOutput, se
# session-start.ps1.
$result = @{
    hookSpecificOutput = @{
        hookEventName     = "SessionStart"
        additionalContext = "Påminnelse efter komprimering: fortsätt med uppgiften där den var, utan projektöversikt. Sammanfattningen av samtalet är förkortad. Läs om källfilen innan du återger siffror, namn eller citat ur den."
    }
}
$result | ConvertTo-Json -Compress
