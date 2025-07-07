# This script removes all stopped containers, all dangling images, all unused networks, and all unused volumes.

Write-Host "Cleaning up Docker resources..."

docker system prune -a -f --volumes

Write-Host "Docker cleanup complete."
