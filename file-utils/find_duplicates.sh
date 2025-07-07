#!/bin/bash
# Finds duplicate files in a directory based on MD5 hash.

SEARCH_DIR=${1:-.}

if [ ! -d "$SEARCH_DIR" ]; then
    echo "Error: Directory '$SEARCH_DIR' not found." >&2
    exit 1
fi

echo "--- Finding duplicate files in '$SEARCH_DIR' ---"
echo "(This may take a while for large directories...)"

# Find all files, calculate their MD5 hashes, sort by hash, and find duplicates
find "$SEARCH_DIR" -type f -exec md5sum {} + | sort | uniq -w32 --all-repeated=separate > duplicates.log

if [ -s duplicates.log ]; then
    echo "Found duplicates! See the 'duplicates.log' file for details."
    cat duplicates.log
else
    echo "No duplicate files found."
    rm duplicates.log
fi
