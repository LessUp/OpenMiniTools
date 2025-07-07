#!/bin/bash
# Starts a simple HTTP server in the current directory.

PORT=${1:-8000}

echo "--- Starting a simple HTTP server on port $PORT ---"
echo "Serving files from: $(pwd)"
echo "Access it at: http://<your-ip>:$PORT or http://localhost:$PORT"
echo "Press Ctrl+C to stop."

if command -v python3 &>/dev/null; then
    python3 -m http.server $PORT
elif command -v python &>/dev/null; then
    python -m SimpleHTTPServer $PORT
else
    echo "Error: Python is not installed. Cannot start the server."
    exit 1
fi
