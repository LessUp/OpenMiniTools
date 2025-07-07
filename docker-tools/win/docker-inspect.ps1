# This script inspects a Docker container and displays its configuration details.

# Get all containers
$allContainers = docker ps -a --format '{{.ID}} {{.Names}}'
if (-not $allContainers) {
    Write-Host "No containers found."
    Read-Host "Press Enter to exit..."
    exit
}

$containerList = $allContainers | ForEach-Object { $_.Split(' ', 2) }

Write-Host "Select a container to inspect:"
for ($i = 0; $i -lt $containerList.Length; $i++) {
    Write-Host "$($i + 1))) $($containerList[$i][1])"
}

$selection = Read-Host "Enter selection (1-$($containerList.Length))"
if (-not ($selection -match '^\d+$') -or [int]$selection -lt 1 -or [int]$selection -gt $containerList.Length) {
    Write-Host "Invalid selection. Exiting." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

$index = [int]$selection - 1
$containerId = $containerList[$index][0]
Write-Host "Selected container: $($containerList[$index][1])"

Write-Host "Inspecting container $containerId..."
docker inspect $containerId | ConvertFrom-Json
