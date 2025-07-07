#!/bin/bash
#
# Main menu script for Docker management tools.

SCRIPT_DIR=$(dirname "$0")

while true; do
    clear
    echo "===================================="
    echo "    Docker Management Menu (Linux)" 
    echo "===================================="
    echo "INTERACTIVE:"
    echo "  1) View Container Logs"
    echo "  2) Interactive Shell in Container (Exec)"
    echo "  3) Inspect a Container"
    echo "  4) View Live Container Stats"
    echo "------------------------------------"
    echo "GENERAL COMMANDS:"
    echo "  5) Stop All Running Containers"
    echo "  6) Clean Unused Docker Resources"
    echo "------------------------------------"
    echo "DESTRUCTIVE COMMANDS (use with caution):"
    echo "  7) Remove All Containers"
    echo "  8) Remove All Images"
    echo "  9) Full Docker Reset"
    echo "------------------------------------"
    echo "  0) Exit"
    echo "===================================="
    read -p "Enter your choice: " choice

    case $choice in
        1) bash "$SCRIPT_DIR/docker-logs.sh" ;;
        2) bash "$SCRIPT_DIR/docker-exec.sh" ;;
        3) bash "$SCRIPT_DIR/docker-inspect.sh" ;;
        4) bash "$SCRIPT_DIR/docker-stats.sh" ;;
        5) bash "$SCRIPT_DIR/docker-stop-all.sh" ;;
        6) bash "$SCRIPT_DIR/docker-clean.sh" ;;
        7) bash "$SCRIPT_DIR/docker-remove-all-containers.sh" ;;
        8) bash "$SCRIPT_DIR/docker-remove-all-images.sh" ;;
        9) bash "$SCRIPT_DIR/docker-full-reset.sh" ;;
        0) echo "Exiting."; exit 0 ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
    read -p "Press Enter to return to the menu..."
done
