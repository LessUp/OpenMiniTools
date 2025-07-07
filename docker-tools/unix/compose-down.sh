#!/bin/bash
#
# This script stops and removes the services defined in a docker-compose.yml file.
# It runs 'docker-compose down'.

if [ ! -f "docker-compose.yml" ] && [ ! -f "docker-compose.yaml" ]; then
    echo "Error: No docker-compose.yml or docker-compose.yaml found in the current directory."
    exit 1
fi

echo "Stopping and removing services from docker-compose file..."
docker-compose down

echo "Services stopped and removed."
