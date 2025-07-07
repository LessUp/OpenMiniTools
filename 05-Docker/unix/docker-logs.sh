#!/bin/bash
#
# This script displays the logs of a running container.

# Get running containers
RUNNING_CONTAINERS=($(docker ps --format "{{.ID}} {{.Names}}"))

if [ ${#RUNNING_CONTAINERS[@]} -eq 0 ]; then
    echo "No running containers found."
    exit 0
fi

echo "Select a container to view logs:"
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

read -p "Follow log output? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Following logs for container $CONTAINER_ID. Press [CTRL+C] to exit."
    docker logs -f $CONTAINER_ID
else
    docker logs $CONTAINER_ID
fi
