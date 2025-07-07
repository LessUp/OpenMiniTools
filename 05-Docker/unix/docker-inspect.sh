#!/bin/bash
#
# This script inspects a Docker container and displays its configuration details.

# Get all containers
ALL_CONTAINERS=($(docker ps -a --format "{{.ID}} {{.Names}}"))

if [ ${#ALL_CONTAINERS[@]} -eq 0 ]; then
    echo "No containers found."
    exit 0
fi

echo "Select a container to inspect:"
i=0
while [ $i -lt ${#ALL_CONTAINERS[@]} ]; do
    echo "$(($i/2+1))) ${ALL_CONTAINERS[$(($i+1))]}"
    i=$(($i+2))
done

read -p "Enter selection (1-${#ALL_CONTAINERS[@]}/2): " SELECTION

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt $((${#ALL_CONTAINERS[@]}/2)) ]; then
    echo "Invalid selection. Exiting."
    exit 1
fi

CONTAINER_ID=${ALL_CONTAINERS[$(($SELECTION*2-2))]}
echo "Selected container: $(docker ps -a --format '{{.Names}}' -f id=$CONTAINER_ID)"

echo "Inspecting container $CONTAINER_ID..."
# Check if jq is installed for pretty printing
if command -v jq &> /dev/null
then
    docker inspect $CONTAINER_ID | jq .
else
    echo "'jq' is not installed. Displaying raw JSON output."
    docker inspect $CONTAINER_ID
fi
