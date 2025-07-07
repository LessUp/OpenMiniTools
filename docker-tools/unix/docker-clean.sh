#!/bin/bash
#
# This script removes all stopped containers, all dangling images, all unused networks, and all unused volumes.

echo "Cleaning up Docker resources..."

docker system prune -a -f --volumes

echo "Docker cleanup complete."
