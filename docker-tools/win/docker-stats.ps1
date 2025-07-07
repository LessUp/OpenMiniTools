# This script displays a live stream of resource usage statistics for all running containers.

Write-Host "Displaying live resource usage for all running containers..."
Write-Host "Press [CTRL+C] to exit."

# The --all flag shows all containers (default shows just running)
# but since we only want running ones, we don't need it.
docker stats
