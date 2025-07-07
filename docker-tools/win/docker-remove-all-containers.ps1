# This script stops and removes all Docker containers.

Write-Host "This will stop and remove ALL Docker containers."
$response = Read-Host "Are you sure you want to continue? [y/N]"

if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host "Stopping and removing all containers..."
    # Get all container IDs (running and stopped)
    $allContainers = docker ps -a -q
    if ($allContainers) {
        docker stop $allContainers
        docker rm $allContainers
        Write-Host "All containers have been stopped and removed."
    } else {
        Write-Host "No containers to remove."
    }
} else {
    Write-Host "Operation cancelled."
}
