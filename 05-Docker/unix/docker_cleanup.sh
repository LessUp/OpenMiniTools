#!/bin/bash
# Cleans up unused Docker resources (stopped containers, dangling images, unused networks).

if ! command -v docker &> /dev/null; then
    echo "Error: Docker command could not be found. Please make sure Docker is installed."
    exit 1
fi

echo "--- Docker Cleanup Utility ---"

echo "The following actions will be performed:"
echo "1. Remove all stopped containers."
echo "2. Remove all dangling images."
echo "3. Remove all unused networks."

read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "--- Removing stopped containers ---"
    docker container prune -f

    echo "--- Removing dangling images ---"
    docker image prune -f

    echo "--- Removing unused networks ---"
    docker network prune -f

    echo "Docker cleanup complete."
else
    echo "Operation cancelled."
fi
