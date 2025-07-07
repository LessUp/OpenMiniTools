#!/bin/bash
# Creates a compressed backup of a specified file or directory.

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <file_or_directory>"
    exit 1
fi

if [ ! -e "$TARGET" ]; then
    echo "Error: File or directory '$TARGET' not found."
    exit 1
fi

BACKUP_FILENAME="backup_$(basename ${TARGET})_$(date +%Y%m%d_%H%M%S).tar.gz"
echo "Backing up '$TARGET' to '$BACKUP_FILENAME'..."

tar -czvf "$BACKUP_FILENAME" "$TARGET"

if [ $? -eq 0 ]; then
    echo "Backup created successfully: $BACKUP_FILENAME"
else
    echo "Backup failed."
    exit 1
fi
