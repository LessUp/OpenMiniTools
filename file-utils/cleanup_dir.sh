#!/bin/bash
# Cleans up temporary files in a directory.

TARGET_DIR=${1:-.} # Default to current directory, or use the first argument

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' not found." >&2
    exit 1
fi

echo "Searching for temporary files (*.tmp, *.bak, *.log) in '$TARGET_DIR'"

# Find files and store them in an array
readarray -t files < <(find "$TARGET_DIR" -maxdepth 1 -type f \( -name '*.tmp' -o -name '*.bak' -o -name '*.log' \))

if [ ${#files[@]} -eq 0 ]; then
    echo "No temporary files found to clean up."
    exit 0
fi

echo "Found the following files to delete:"
printf '%s\n' "${files[@]}"

read -p "Are you sure you want to delete these ${#files[@]} files? (y/N) " -n 1 -r
echo # Move to a new line

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting files..."
    for file in "${files[@]}"; do
        rm -v "$file"
    done
    echo "Cleanup complete."
else
    echo "Cleanup cancelled."
fi
