#!/bin/bash
# Test script for COBOL AI CLI

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables from .env file
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | xargs)
fi

# Run the CLI with the provided arguments
timeout 65 "$SCRIPT_DIR/bin/cobol-ai-cli" "$@"