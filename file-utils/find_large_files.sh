#!/bin/bash
# Finds the top 10 largest files in a specified directory.

SEARCH_DIR=${1:-.}

if [ ! -d "$SEARCH_DIR" ]; then
    echo "Error: Directory '$SEARCH_DIR' not found." >&2
    exit 1
fi

echo "--- Finding Top 10 Largest Files in '$SEARCH_DIR' ---"

find "$SEARCH_DIR" -type f -exec du -h {} + | sort -rh | head -n 10
