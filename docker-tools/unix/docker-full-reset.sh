#!/bin/bash
#
# This script performs a full reset of Docker, removing all containers, images, volumes, and networks.

echo "WARNING: This will stop and remove ALL Docker containers, images, volumes, and networks."
echo "This is a destructive action and cannot be undone."
read -p "Are you sure you want to continue? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Starting full Docker reset..."

    # Stop all running containers
    echo "Step 1: Stopping all running containers..."
    RUNNING_CONTAINERS=$(docker ps -q)
    if [ -n "$RUNNING_CONTAINERS" ]; then
      docker stop $RUNNING_CONTAINERS
      echo "All running containers stopped."
    else
      echo "No running containers to stop."
    fi

    # Remove all containers
    echo "Step 2: Removing all containers..."
    ALL_CONTAINERS=$(docker ps -a -q)
    if [ -n "$ALL_CONTAINERS" ]; then
        docker rm $ALL_CONTAINERS
        echo "All containers removed."
    else
        echo "No containers to remove."
    fi

    # Remove all images
    echo "Step 3: Removing all images..."
    ALL_IMAGES=$(docker images -q)
    if [ -n "$ALL_IMAGES" ]; then
        docker rmi -f $ALL_IMAGES
        echo "All images removed."
    else
        echo "No images to remove."
    fi

    # Prune system
    echo "Step 4: Pruning system (volumes, networks, build cache)..."
    docker system prune -a -f --volumes
    echo "System pruned."

    echo "Full Docker reset complete."
else
    echo "Operation cancelled."
fi
