#!/bin/bash
#
# This script displays a live stream of resource usage statistics for all running containers.

echo "Displaying live resource usage for all running containers..."
echo "Press [CTRL+C] to exit."

# The --all flag shows all containers (default shows just running)
# but since we only want running ones, we don't need it.
docker stats
