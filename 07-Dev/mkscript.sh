#!/bin/bash
# Creates a new bash script with a basic template and execute permissions.

SCRIPT_NAME=$1

if [ -z "$SCRIPT_NAME" ]; then
    echo "Usage: $0 <new_script_name.sh>"
    exit 1
fi

if [ -e "$SCRIPT_NAME" ]; then
    echo "Error: File '$SCRIPT_NAME' already exists."
    exit 1
fi

echo "Creating script: $SCRIPT_NAME"

# Create the file with a template
cat > "$SCRIPT_NAME" << EOL
#!/bin/bash
#
# Description: A brief description of your script.
# Author: Your Name
# Date: $(date +%Y-%m-%d)

# --- Main Script ---
echo "Hello, World!"

EOL

# Make the script executable
chmod +x "$SCRIPT_NAME"

echo "Successfully created and made '$SCRIPT_NAME' executable."
