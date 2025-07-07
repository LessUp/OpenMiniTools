#!/bin/bash
# Updates the system using the appropriate package manager.

echo "--- System Update Script ---"

PKG_MANAGER=""

if command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
elif command -v yum &>/dev/null; then
    PKG_MANAGER="yum"
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
elif command -v zypper &>/dev/null; then
    PKG_MANAGER="zypper"
else
    echo "Error: Could not detect a known package manager (apt, dnf, yum, pacman, zypper)."
    exit 1
fi

echo "Detected package manager: $PKG_MANAGER"
read -p "Do you want to proceed with updating the system? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled."
    exit 0
fi

case "$PKG_MANAGER" in
    "apt")
        sudo apt-get update && sudo apt-get upgrade -y
        ;;
    "dnf")
        sudo dnf upgrade -y
        ;;
    "yum")
        sudo yum update -y
        ;;
    "pacman")
        sudo pacman -Syu --noconfirm
        ;;
    "zypper")
        sudo zypper ref && sudo zypper dup -y
        ;;
esac

if [ $? -eq 0 ]; then
    echo "System update completed successfully."
else
    echo "System update failed."
fi
