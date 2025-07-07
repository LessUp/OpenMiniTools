# Main menu script for Docker management tools.

while ($true) {
    Clear-Host
    Write-Host "======================================"
    Write-Host "    Docker Management Menu (Windows)" 
    Write-Host "======================================"
    Write-Host "INTERACTIVE:"
    Write-Host "  1) View Container Logs"
    Write-Host "  2) Interactive Shell in Container (Exec)"
    Write-Host "  3) Inspect a Container"
    Write-Host "  4) View Live Container Stats"
    Write-Host "--------------------------------------"
    Write-Host "GENERAL COMMANDS:"
    Write-Host "  5) Stop All Running Containers"
    Write-Host "  6) Clean Unused Docker Resources"
    Write-Host "--------------------------------------"
    Write-Host "DESTRUCTIVE COMMANDS (use with caution):"
    Write-Host "  7) Remove All Containers"
    Write-Host "  8) Remove All Images"
    Write-Host "  9) Full Docker Reset"
    Write-Host "--------------------------------------"
    Write-Host "  0) Exit"
    Write-Host "======================================"
    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        '1' { & "$PSScriptRoot\docker-logs.ps1" }
        '2' { & "$PSScriptRoot\docker-exec.ps1" }
        '3' { & "$PSScriptRoot\docker-inspect.ps1" }
        '4' { & "$PSScriptRoot\docker-stats.ps1" }
        '5' { & "$PSScriptRoot\docker-stop-all.ps1" }
        '6' { & "$PSScriptRoot\docker-clean.ps1" }
        '7' { & "$PSScriptRoot\docker-remove-all-containers.ps1" }
        '8' { & "$PSScriptRoot\docker-remove-all-images.ps1" }
        '9' { & "$PSScriptRoot\docker-full-reset.ps1" }
        '0' { Write-Host "Exiting."; return }
        default { Write-Host "Invalid choice. Please try again." -ForegroundColor Red }
    }
    Read-Host "Press Enter to return to the menu..."
}
