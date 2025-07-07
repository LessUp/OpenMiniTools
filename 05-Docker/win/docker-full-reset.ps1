# This script performs a full reset of Docker, removing all containers, images, volumes, and networks.

Write-Host "WARNING: This will stop and remove ALL Docker containers, images, volumes, and networks." -ForegroundColor Yellow
Write-Host "This is a destructive action and cannot be undone." -ForegroundColor Yellow
$response = Read-Host "Are you sure you want to continue? [y/N]"

if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host "Starting full Docker reset..."

    # Step 1: Stop all running containers
    Write-Host "Step 1: Stopping all running containers..."
    $runningContainers = docker ps -q
    if ($runningContainers) {
        docker stop $runningContainers
        Write-Host "All running containers stopped."
    } else {
        Write-Host "No running containers to stop."
    }

    # Step 2: Remove all containers
    Write-Host "Step 2: Removing all containers..."
    $allContainers = docker ps -a -q
    if ($allContainers) {
        docker rm $allContainers
        Write-Host "All containers removed."
    } else {
        Write-Host "No containers to remove."
    }

    # Step 3: Remove all images
    Write-Host "Step 3: Removing all images..."
    $allImages = docker images -q
    if ($allImages) {
        docker rmi -f $allImages
        Write-Host "All images have been removed."
    } else {
        Write-Host "No images to remove."
    }

    # Step 4: Prune system
    Write-Host "Step 4: Pruning system (volumes, networks, build cache)..."
    docker system prune -a -f --volumes
    Write-Host "System pruned."

    Write-Host "Full Docker reset complete." -ForegroundColor Green
} else {
    Write-Host "Operation cancelled."
}
