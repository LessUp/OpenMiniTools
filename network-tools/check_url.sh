#!/bin/bash
# Checks the status of a URL.

URL=$1

if [ -z "$URL" ]; then
    echo "Usage: $0 <URL>"
    exit 1
fi

echo "--- Checking URL: $URL ---"

# Use curl to get headers and status
# -s for silent, -o /dev/null to discard body, -w for custom output
curl -s -o /dev/null -w "HTTP Status: %{http_code}\\nResponse Time: %{time_total}s\\n" "$URL"

echo "--- Response Headers ---"
curl -s -I "$URL"