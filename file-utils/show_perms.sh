#!/bin/bash
# Displays file permissions in a human-readable format.

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <file_or_directory>"
    exit 1
fi

if [ ! -e "$TARGET" ]; then
    echo "Error: File or directory '$TARGET' not found."
    exit 1
fi

PERMS=$(stat -c "%a" "$TARGET")

echo "Permissions for '$TARGET' ($PERMS):"

# Function to decode permission digit
decode_perm() {
    local p=$1
    local r="-"
    local w="-"
    local x="-"
    [ $((p & 4)) -ne 0 ] && r="read"
    [ $((p & 2)) -ne 0 ] && w="write"
    [ $((p & 1)) -ne 0 ] && x="execute"
    echo "$r, $w, $x"
}

OWNER_PERM=$((PERMS / 100))
GROUP_PERM=$(((PERMS / 10) % 10))
OTHER_PERM=$((PERMS % 10))

echo "Owner: $(decode_perm $OWNER_PERM)"
echo "Group: $(decode_perm $GROUP_PERM)"
echo "Other: $(decode_perm $OTHER_PERM)"
