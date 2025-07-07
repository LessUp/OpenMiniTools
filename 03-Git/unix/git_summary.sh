#!/bin/bash
# Displays a summary of the current git repository status.

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not inside a git repository."
    exit 1
fi

echo "--- Git Repository Summary ---"

# Current Branch
echo "Current Branch: $(git rev-parse --abbrev-ref HEAD)"

# Recent Commits
echo
echo "--- Recent Commits ---"
git log --oneline -n 5

# Repository Status
echo
echo "--- Repository Status ---"
git status -s

# Add a hint if there are untracked files or changes
if ! git diff-index --quiet HEAD --; then
    echo
    echo "Hint: You have changes that are not committed."
fi
