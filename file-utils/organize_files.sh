#!/bin/bash
# Organizes files in a directory into subdirectories based on file extension.

TARGET_DIR=${1:-.}

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' not found." >&2
    exit 1
fi

# Define categories
declare -A CATEGORIES
CATEGORIES=( [images]="jpg jpeg png gif bmp svg" [documents]="pdf doc docx xls xlsx ppt pptx txt odt" [archives]="zip tar gz bz2 7z rar" [audio]="mp3 wav ogg flac" [video]="mp4 avi mkv mov wmv" )

echo "--- File Organizer for '$TARGET_DIR' ---"

# Use find to get all files in the current directory (not recursively)
find "$TARGET_DIR" -maxdepth 1 -type f | while IFS= read -r file; do
    # Skip this script itself
    if [[ "$file" == *"organize_files.sh"* ]]; then
        continue
    fi

    EXTENSION="${file##*.}"
    if [ "$EXTENSION" == "$file" ]; then # No extension
        DEST_DIR="misc"
    else
        EXTENSION=${EXTENSION,,} # to lower case
        DEST_DIR=""
        for category in "${!CATEGORIES[@]}"; do
            if [[ " ${CATEGORIES[$category]} " =~ " $EXTENSION " ]]; then
                DEST_DIR=$category
                break
            fi
        done
        if [ -z "$DEST_DIR" ]; then
            DEST_DIR="misc"
        fi
    fi

    # Create destination directory if it doesn't exist
    mkdir -p "$TARGET_DIR/$DEST_DIR"
    
    echo "Moving '$file' to '$TARGET_DIR/$DEST_DIR/'"
    mv "$file" "$TARGET_DIR/$DEST_DIR/"
done

echo "Organization complete."
