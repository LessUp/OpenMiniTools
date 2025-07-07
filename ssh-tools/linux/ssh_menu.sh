#!/bin/bash
# Provides an interactive menu to connect to predefined SSH hosts.

CONFIG_FILE="ssh_hosts.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found."
    echo "Please create it with the format: NICKNAME,USER@HOSTNAME"
    echo "Example: web-server,admin@192.168.1.100"
    exit 1
fi

OLD_IFS=$IFS
IFS=$'\n'
HOSTS=($(grep -v '^#' $CONFIG_FILE | grep -v '^$')) # Read hosts, ignore comments and empty lines
IFS=$OLD_IFS

if [ ${#HOSTS[@]} -eq 0 ]; then
    echo "No hosts found in '$CONFIG_FILE'."
    exit 0
fi

echo "--- SSH Connection Menu ---"
PS3="Please select a host to connect to (or 'q' to quit): "

select opt in "${HOSTS[@]}"; do
    if [[ -n "$opt" ]]; then
        NICKNAME=$(echo "$opt" | cut -d',' -f1)
        CONNECTION_STRING=$(echo "$opt" | cut -d',' -f2)
        echo "Connecting to $NICKNAME ($CONNECTION_STRING)..."
        ssh $CONNECTION_STRING
        break
    else
        echo "Invalid option. Please try again."
    fi
done
