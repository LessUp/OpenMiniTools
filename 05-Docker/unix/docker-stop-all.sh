#!/bin/bash
#
# This script stops all running Docker containers.

echo "Stopping all running Docker containers..."

# Get all running container IDs and stop them.
# The `docker ps -q` command lists only the numeric IDs of running containers.
# If there are no running containers, the command returns an empty string, and `docker stop` does nothing.
RUNNING_CONTAINERS=$(docker ps -q)
if [ -n "$RUNNING_CONTAINERS" ]; then
  docker stop $RUNNING_CONTAINERS
  echo "All running containers have been stopped."
else
  echo "No running containers to stop."
fi
