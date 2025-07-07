# This script stops all running Docker containers.

Write-Host "Stopping all running Docker containers..."

# Get all running container IDs and stop them.
# The `docker ps -q` command lists only the numeric IDs of running containers.
$runningContainers = docker ps -q

if ($runningContainers) {
    docker stop $runningContainers
    Write-Host "All running containers have been stopped."
} else {
    Write-Host "No running containers to stop."
}
