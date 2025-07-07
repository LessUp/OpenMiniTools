#!/bin/bash
# Displays network information, including IP addresses and listening ports.

echo "--- Network Interfaces and IP Addresses ---"
ip -c addr show

echo
echo "--- Listening TCP/UDP Ports ---"
if command -v ss &> /dev/null; then
    ss -tuln
elif command -v netstat &> /dev/null; then
    netstat -tuln
else
    echo "Could not find 'ss' or 'netstat' command to show listening ports."
fi
