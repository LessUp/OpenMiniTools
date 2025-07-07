#!/bin/bash
# A simple log viewer.
# It shows the last N lines of the system log.

LINES=${1:-50} # Default to 50 lines, or use the first argument

echo "--- Displaying last $LINES lines of system log ---"

if command -v journalctl &> /dev/null; then
    journalctl -n $LINES -p 3 --no-pager
elif [ -f /var/log/syslog ]; then
    tail -n $LINES /var/log/syslog
elif [ -f /var/log/messages ]; then
    tail -n $LINES /var/log/messages
else
    echo "Could not find system log file."
    exit 1
fi
