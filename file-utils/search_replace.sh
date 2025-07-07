#!/bin/bash
# Recursively finds and replaces a string in files.

SEARCH_TERM=$1
REPLACE_TERM=$2
FILE_PATTERN=$3
TARGET_DIR=${4:-.}

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <search_term> <replace_term> <file_pattern> [target_dir]"
    echo "Example: $0 'foo' 'bar' '*.txt' ./my_project"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' not found." >&2
    exit 1
fi

# Use grep to find files containing the search term
FILES=$(grep -rl "$SEARCH_TERM" "$TARGET_DIR" --include="$FILE_PATTERN")

if [ -z "$FILES" ]; then
    echo "No files found containing '$SEARCH_TERM' matching pattern '$FILE_PATTERN' in '$TARGET_DIR'."
    exit 0
fi

echo "The following files will be modified:"
echo "$FILES"

read -p "Are you sure you want to replace '$SEARCH_TERM' with '$REPLACE_TERM' in these files? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Replacing..."
    # Use a loop to handle filenames with spaces
    echo "$FILES" | while IFS= read -r file; do
        # Use sed with a different delimiter to avoid issues with slashes in terms
        sed -i "s|$SEARCH_TERM|$REPLACE_TERM|g" "$file"
        echo "Modified: $file"
    done
    echo "Replacement complete."
else
    echo "Operation cancelled."
fi
