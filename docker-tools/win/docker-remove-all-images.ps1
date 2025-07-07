# This script removes all Docker images.

Write-Host "This will remove ALL Docker images."
$response = Read-Host "Are you sure you want to continue? [y/N]"

if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host "Removing all images..."
    # Get all image IDs
    $allImages = docker images -q
    if ($allImages) {
        docker rmi -f $allImages
        Write-Host "All images have been removed."
    } else {
        Write-Host "No images to remove."
    }
} else {
    Write-Host "Operation cancelled."
}
