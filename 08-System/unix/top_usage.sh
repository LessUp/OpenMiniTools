#!/bin/bash
# Displays top processes by CPU and Memory usage.

echo "--- Top 5 Processes by CPU Usage ---"
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head -n 6

echo

echo "--- Top 5 Processes by Memory Usage ---"
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%mem | head -n 6
