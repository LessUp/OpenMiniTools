#!/bin/bash
#
# This script starts the services defined in a docker-compose.yml file in the current directory.
# It runs 'docker-compose up -d'.

if [ ! -f "docker-compose.yml" ] && [ ! -f "docker-compose.yaml" ]; then
    echo "Error: No docker-compose.yml or docker-compose.yaml found in the current directory."
    exit 1
fi

echo "Starting services from docker-compose file in detached mode..."
docker-compose up -d

echo "Services started."
