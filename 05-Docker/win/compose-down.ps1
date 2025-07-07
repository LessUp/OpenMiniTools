# This script stops and removes the services defined in a docker-compose.yml file.
# It runs 'docker-compose down'.

if (-not (Test-Path -Path "./docker-compose.yml") -and -not (Test-Path -Path "./docker-compose.yaml")) {
    Write-Host "Error: No docker-compose.yml or docker-compose.yaml found in the current directory." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

Write-Host "Stopping and removing services from docker-compose file..."
docker-compose down

Write-Host "Services stopped and removed."
