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

# Get the prompt. Reading it from a file avoids shell-quoting entirely,
# which matters once prompts carry file contents full of quotes and
# newlines. The positional form is kept for manual use.
if [ "$1" = "--prompt-file" ]; then
    PROMPT_FILE="$2"
    MODEL="${3:-$MODEL}"
    if [ ! -f "$PROMPT_FILE" ]; then
        echo "ERROR: prompt file not found: $PROMPT_FILE"
        exit 1
    fi
    PROMPT="$(cat "$PROMPT_FILE")"
else
    PROMPT="$1"
fi

if [ -z "$PROMPT" ]; then
    echo "Usage: $0 <prompt> [model]"
    echo "       $0 --prompt-file <path> [model]"
    exit 1
fi

# Use fixed response file location
RESPONSE_FILE="/tmp/cobol-ai-response.json"

# Build JSON payload. The backslash substitution must come first, or it
# would re-escape the backslashes introduced by the later ones. Newlines
# and tabs have to become escapes because a raw one is invalid inside a
# JSON string.
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\r'/}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

ESCAPED_PROMPT="$(json_escape "$PROMPT")"
JSON_PAYLOAD="{\"model\":\"$MODEL\",\"prompt\":\"$ESCAPED_PROMPT\",\"stream\":false}"

# Dry run: report the resolved configuration and make no network call.
# Used by the test suite to assert on config precedence without an API key.
if [ "${COBOL_AI_HELPER_DRY_RUN:-}" = "1" ]; then
    echo "MODEL=$MODEL"
    echo "BASE_URL=$BASE_URL"
    echo "PAYLOAD=$JSON_PAYLOAD"
    exit 0
fi

# Make API call. The HTTP status is written to its own file so the COBOL
# side can tell a rate limit apart from a bad key - retrying the former
# is correct, retrying the latter just wastes time.
STATUS_FILE="/tmp/cobol-ai-status.txt"
rm -f "$STATUS_FILE"

HTTP_CODE=$(curl -s -X POST "$BASE_URL/api/generate" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    -o "$RESPONSE_FILE" \
    -w '%{http_code}' \
    --max-time "$TIMEOUT_SEC")
CURL_RC=$?

if [ $CURL_RC -ne 0 ]; then
    # 000 means the request never got an HTTP reply: DNS failure,
    # connection refused, or timeout. All are worth retrying.
    echo "000" > "$STATUS_FILE"
    echo "ERROR: Failed to call API (curl exit $CURL_RC)"
    rm -f "$RESPONSE_FILE"
    exit 1
fi

echo "$HTTP_CODE" > "$STATUS_FILE"

if [ "$HTTP_CODE" -ge 400 ] 2>/dev/null; then
    echo "ERROR: API returned HTTP $HTTP_CODE"
    exit 1
fi