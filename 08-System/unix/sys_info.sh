#!/bin/bash
# Displays a summary of system information.

echo "--- System Information ---"

# Hostname
echo "Hostname: $(hostname)"

# OS Information
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "OS: $PRETTY_NAME"
elif type lsb_release >/dev/null 2>&1; then
    echo "OS: $(lsb_release -ds)"
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    echo "OS: $DISTRIB_DESCRIPTION"
elif [ -f /etc/debian_version ]; then
    echo "OS: Debian $(cat /etc/debian_version)"
else
    echo "OS: $(uname -s)"
fi

# Kernel Version
echo "Kernel: $(uname -r)"

# Uptime
echo "Uptime: $(uptime -p)"

# CPU Information
echo "CPU: $(grep 'model name' /proc/cpuinfo | uniq | cut -d ':' -f 2 | sed -e 's/^[ \t]*//')"

# Memory Usage
echo "--- Memory Usage ---"
free -h

# Disk Usage
echo "--- Disk Usage ---"
df -h
