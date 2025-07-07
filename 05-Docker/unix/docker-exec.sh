#!/bin/bash
#
# This script provides an interactive shell into a running container.

# Get running containers
RUNNING_CONTAINERS=($(docker ps --format "{{.ID}} {{.Names}}"))

if [ ${#RUNNING_CONTAINERS[@]} -eq 0 ]; then
    echo "No running containers found."
    exit 0
fi

echo "Select a container to connect to:"
i=0
while [ $i -lt ${#RUNNING_CONTAINERS[@]} ]; do
    echo "$(($i/2+1))) ${RUNNING_CONTAINERS[$(($i+1))]}"
    i=$(($i+2))
done

read -p "Enter selection (1-${#RUNNING_CONTAINERS[@]}/2): " SELECTION

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt $((${#RUNNING_CONTAINERS[@]}/2)) ]; then
    echo "Invalid selection. Exiting."
    exit 1
fi

CONTAINER_ID=${RUNNING_CONTAINERS[$(($SELECTION*2-2))]}
echo "Selected container: $(docker ps --format '{{.Names}}' -f id=$CONTAINER_ID)"

# Try to connect with /bin/bash, if it fails, try /bin/sh
echo "Attempting to connect to $CONTAINER_ID..."
docker exec -it $CONTAINER_ID /bin/bash

if [ $? -ne 0 ]; then
    echo "Failed to connect with /bin/bash. Trying /bin/sh..."
    docker exec -it $CONTAINER_ID /bin/sh
fi
