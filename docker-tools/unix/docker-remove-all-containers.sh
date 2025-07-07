#!/bin/bash
#
# This script stops and removes all Docker containers.

echo "This will stop and remove ALL Docker containers."
read -p "Are you sure you want to continue? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Stopping and removing all containers..."
    # Get all container IDs (running and stopped)
    ALL_CONTAINERS=$(docker ps -a -q)
    if [ -n "$ALL_CONTAINERS" ]; then
        docker stop $ALL_CONTAINERS
        docker rm $ALL_CONTAINERS
        echo "All containers have been stopped and removed."
    else
        echo "No containers to remove."
    fi
else
    echo "Operation cancelled."
fi
