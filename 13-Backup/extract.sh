#!/bin/bash
# Extracts any archive file using the appropriate command.

FILE=$1

if [ -z "$FILE" ]; then
    echo "Usage: $0 <archive_file>"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found."
    exit 1
fi

case "$FILE" in
    *.tar.bz2|*.tbz2)
        tar xvjf "$FILE"    ;;
    *.tar.gz|*.tgz)
        tar xvzf "$FILE"    ;;
    *.tar.xz|*.txz)
        tar xvJf "$FILE"    ;;
    *.tar)
        tar xvf "$FILE"     ;;
    *.zip)
        unzip "$FILE"       ;;
    *.rar)
        unrar x "$FILE"     ;;
    *.7z)
        7z x "$FILE"        ;;
    *)
        echo "Error: Don't know how to extract '$FILE'..."
        exit 1
        ;;
esac

echo "Successfully extracted '$FILE'"
