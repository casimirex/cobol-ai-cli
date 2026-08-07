#!/bin/bash
# COBOL AI CLI Helper - Handles API calls

# Read environment variables from .env, but let an already-exported
# variable win - otherwise .env silently overrides the caller and the
# program cannot change any setting at runtime.
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    while IFS='=' read -r key value; do
        key="${key%%[[:space:]]*}"
        [[ -z "$key" || "$key" == \#* ]] && continue
        [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
        [[ -n "${!key:-}" ]] && continue
        export "$key=${value%$'\r'}"
    done < "$ENV_FILE"
fi

# Set defaults - the model may be overridden per call by argument 2,
# which is how the interactive `model <name>` command takes effect.
API_KEY="${AI_OLLAMA_API_KEY:-}"
BASE_URL="${AI_OLLAMA_BASE_URL:-https://ollama.com}"
MODEL="${2:-${AI_OLLAMA_DEFAULT_MODEL:-gpt-oss:120b}}"
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

# Dry run: report the resolved configuration and make no network call.
# Used by the test suite to assert on config precedence without an API key.
if [ "${COBOL_AI_HELPER_DRY_RUN:-}" = "1" ]; then
    echo "MODEL=$MODEL"
    echo "BASE_URL=$BASE_URL"
    echo "PAYLOAD=$JSON_PAYLOAD"
    exit 0
fi

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