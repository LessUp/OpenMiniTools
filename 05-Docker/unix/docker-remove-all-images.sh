#!/bin/bash
#
# This script removes all Docker images.

echo "This will remove ALL Docker images."
read -p "Are you sure you want to continue? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Removing all images..."
    # Get all image IDs
    ALL_IMAGES=$(docker images -q)
    if [ -n "$ALL_IMAGES" ]; then
        docker rmi -f $ALL_IMAGES
        echo "All images have been removed."
    else
        echo "No images to remove."
    fi
else
    echo "Operation cancelled."
fi
