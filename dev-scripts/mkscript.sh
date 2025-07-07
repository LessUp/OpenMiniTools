#!/bin/bash
# 创建一个新的bash脚本文件，包含基础模板和执行权限

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

# 使用示例：
#   ./mkscript.sh new_script.sh
#   这将创建一个名为new_script.sh的可执行文件
