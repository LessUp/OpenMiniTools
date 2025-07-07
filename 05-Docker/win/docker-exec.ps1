# This script provides an interactive shell into a running container.

# Get running containers
$runningContainers = docker ps --format '{{.ID}} {{.Names}}'
if (-not $runningContainers) {
    Write-Host "No running containers found."
    Read-Host "Press Enter to exit..."
    exit
}

$containerList = $runningContainers | ForEach-Object { $_.Split(' ', 2) }

Write-Host "Select a container to connect to:"
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

$shell = Read-Host "Enter shell to use (e.g., /bin/bash, /bin/sh, powershell, cmd) [default: /bin/bash]"
if ([string]::IsNullOrWhiteSpace($shell)) {
    $shell = "/bin/bash"
}

Write-Host "Connecting to $containerId with shell '$shell'..."
docker exec -it $containerId $shell

Write-Host "Disconnected from container."
