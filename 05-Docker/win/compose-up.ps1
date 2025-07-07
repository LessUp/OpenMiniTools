# This script starts the services defined in a docker-compose.yml file in the current directory.
# It runs 'docker-compose up -d'.

if (-not (Test-Path -Path "./docker-compose.yml") -and -not (Test-Path -Path "./docker-compose.yaml")) {
    Write-Host "Error: No docker-compose.yml or docker-compose.yaml found in the current directory." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

Write-Host "Starting services from docker-compose file in detached mode..."
docker-compose up -d

Write-Host "Services started."
