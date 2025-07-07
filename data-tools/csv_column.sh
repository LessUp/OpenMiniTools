#!/bin/bash
# Extracts a specific column from a CSV file.

FILE=$1
COLUMN_NUM=$2
DELIMITER=${3:-,} # Default delimiter is a comma

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <csv_file> <column_number> [delimiter]"
    echo "Example: $0 data.csv 3"
    echo "Example with pipe delimiter: $0 data.csv 2 '|'"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found."
    exit 1
fi

if ! [[ "$COLUMN_NUM" =~ ^[0-9]+$ ]] || [ "$COLUMN_NUM" -lt 1 ]; then
    echo "Error: Column number must be a positive integer."
    exit 1
fi

awk -F"$DELIMITER" '{print $'$COLUMN_NUM'}' "$FILE"
