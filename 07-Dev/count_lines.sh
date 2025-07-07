#!/bin/bash
# Counts the total lines of code for common file types in the current directory.

echo "--- Counting Lines of Code in Current Directory ---"

# Define file patterns to search for
PATTERNS=(
    "*.sh" "*.py" "*.js" "*.html" "*.css" 
    "*.c" "*.h" "*.cpp" "*.hpp" "*.java" 
    "*.go" "*.rs" "*.rb" "*.php" "*.md"
)

# Use find to locate files and wc to count lines
find . -type f \( -name "${PATTERNS[0]}" $(printf -- " -o -name '%s'" "${PATTERNS[@]:1}") \) -print0 | xargs -0 wc -l
