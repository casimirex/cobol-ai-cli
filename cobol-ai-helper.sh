#!/bin/bash
# COBOL AI CLI Helper - Handles API calls

# Read environment variables
if [ -f "$(dirname "$0")/.env" ]; then
    export $(cat "$(dirname "$0")/.env" | grep -v '^#' | xargs)
fi

# Set defaults
API_KEY="${AI_OLLAMA_API_KEY:-}"
BASE_URL="${AI_OLLAMA_BASE_URL:-https://ollama.com}"
MODEL="${AI_OLLAMA_DEFAULT_MODEL:-gpt-oss:120b}"
TIMEOUT="${AI_OLLAMA_TIMEOUT:-60000}"
TIMEOUT_SEC=$((TIMEOUT / 1000))

# Check for API key
if [ -z "$API_KEY" ]; then
    echo "ERROR: AI_OLLAMA_API_KEY not set"
    exit 1
fi

# Get prompt from arguments
PROMPT="$1"
if [ -z "$PROMPT" ]; then
    echo "Usage: $0 <prompt>"
    exit 1
fi

# Use fixed response file location
RESPONSE_FILE="/tmp/cobol-ai-response.json"

# Build JSON payload - properly escape special characters
ESCAPED_PROMPT=$(echo "$PROMPT" | sed 's/"/\\"/g' | sed 's/\\n/\\n/g')
JSON_PAYLOAD="{\"model\":\"$MODEL\",\"prompt\":\"$ESCAPED_PROMPT\",\"stream\":false}"

# Make API call
curl -s -X POST "$BASE_URL/api/generate" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    -o "$RESPONSE_FILE" \
    --max-time "$TIMEOUT_SEC"

# Check if curl succeeded
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to call API"
    rm -f "$RESPONSE_FILE"
    exit 1
fi