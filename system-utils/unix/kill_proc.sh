#!/bin/bash
# Finds and kills a process by name with confirmation.

PROC_NAME=$1

if [ -z "$PROC_NAME" ]; then
    echo "Usage: $0 <process_name>"
    exit 1
fi

# Find process IDs
pids=$(pgrep -f "$PROC_NAME")

if [ -z "$pids" ]; then
    echo "No process found with name containing '$PROC_NAME'."
    exit 0
fi

echo "Found the following processes:"
ps -f -p $pids

read -p "Are you sure you want to kill these processes? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Killing processes..."
    kill -9 $pids
    echo "Done."
else
    echo "Kill operation cancelled."
fi
