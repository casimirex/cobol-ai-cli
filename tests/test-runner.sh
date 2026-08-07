#!/bin/bash
# COBOL AI CLI - Test Runner
#
# Behavioural tests for the compiled CLI. Every test below asserts on real
# program output; none of them pass unconditionally.
#
# The suite runs OFFLINE and costs nothing: the response cache is file
# backed, so seeding it lets the program answer from cache without ever
# calling the API. State is redirected into test-output via XDG_STATE_HOME,
# so a run never touches the developer's real cache or history. Tests that must exercise a cache MISS
# point the base URL at a dead local port so the request fails immediately
# instead of reaching the real endpoint with real credentials.
#
# Usage: ./tests/test-runner.sh          (or: make test)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_NAMES=()

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BIN_DIR="$PROJECT_ROOT/bin"
TEST_OUTPUT="$PROJECT_ROOT/test-output"
CLI="$PROJECT_ROOT/cobol-ai.bin"

# Isolate all persistent state in the test output directory, and pin the
# run id so the per-request scratch paths are predictable.
export XDG_STATE_HOME="$TEST_OUTPUT/state"
export COBOL_AI_RUN_ID="testrun"
STATE_DIR="$XDG_STATE_HOME/cobol-ai-cli"
CACHE_FILE="$STATE_DIR/cache.dat"
SCRATCH_PREFIX="/tmp/cobol-ai-${COBOL_AI_RUN_ID}-"

mkdir -p "$TEST_OUTPUT"
cd "$PROJECT_ROOT" || exit 1

# ---------------------------------------------------------------------------
# Test environment
#
# Deliberately fake. The API key only has to survive the program's own
# validation (>= 10 chars); nothing here can reach a real endpoint. The model
# is pinned so cache keys are deterministic across machines.
# ---------------------------------------------------------------------------
export AI_OLLAMA_API_KEY="test-key-0123456789"
export AI_OLLAMA_BASE_URL="http://127.0.0.1:1"
export AI_OLLAMA_DEFAULT_MODEL="test-model"
export AI_OLLAMA_TIMEOUT="2000"
TEST_MODEL="test-model"

# ---------------------------------------------------------------------------
# Assertion helpers
# ---------------------------------------------------------------------------
CURRENT_TEST=""
CURRENT_LOG=""

begin_test() {
    CURRENT_TEST="$1"
    CURRENT_LOG="$TEST_OUTPUT/${1}.log"
    TESTS_RUN=$((TESTS_RUN + 1))
    printf '  %-38s ' "$1"
}

pass_test() {
    echo -e "${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail_test() {
    echo -e "${RED}FAIL${NC}"
    echo "      $1"
    [[ -n "$CURRENT_LOG" ]] && echo "      log: $CURRENT_LOG"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_NAMES+=("$CURRENT_TEST")
}

# assert_output_has <file> <needle> [more needles...]
assert_output_has() {
    local file="$1"; shift
    local needle
    for needle in "$@"; do
        if ! grep -qF -- "$needle" "$file"; then
            fail_test "expected output to contain: $needle"
            return 1
        fi
    done
    return 0
}

# assert_output_lacks <file> <needle> [more needles...]
assert_output_lacks() {
    local file="$1"; shift
    local needle
    for needle in "$@"; do
        if grep -qF -- "$needle" "$file"; then
            fail_test "output should NOT contain: $needle"
            return 1
        fi
    done
    return 0
}

# ---------------------------------------------------------------------------
# Cache seeding
#
# Mirrors BUILD-CACHE-KEY in src/main.cob: a rolling polynomial hash over
# "<model>|<prompt>", rendered as 12 hash digits + 4 length digits + the
# first 48 characters of the key. GnuCOBOL's FUNCTION ORD is the ASCII code
# plus one, hence the "+ 1" below.
# ---------------------------------------------------------------------------
cache_hash() {
    local key="$1|$2"
    local acc=0 i char code
    for (( i = 0; i < ${#key}; i++ )); do
        char="${key:i:1}"
        printf -v code '%d' "'$char"
        acc=$(( (acc * 31 + code + 1) % 999999937 ))
    done
    printf '%012d%04d%-48.48s' "$acc" "${#key}" "$key"
}

# cache_record <prompt> <response> [yyyymmddhhmmss]
cache_record() {
    local prompt="$1" response="$2" stamp="${3:-$(date +%Y%m%d%H%M%S)}"
    printf '%s%s%s%s\n' "$(cache_hash "$TEST_MODEL" "$prompt")" \
        "$stamp" "Y" "$response"
}

reset_cache() {
    rm -rf "$STATE_DIR"
    mkdir -p "$STATE_DIR"
}

# run_cli <log> <args...> - one-shot mode
run_cli() {
    local log="$1"; shift
    timeout 60 "$CLI" "$@" > "$log" 2>&1
}

# run_cli_input <log> <stdin text> - interactive mode
run_cli_input() {
    local log="$1" input="$2"
    printf '%b' "$input" | timeout 60 "$CLI" > "$log" 2>&1
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
echo "========================================"
echo "       COBOL AI CLI - Test Suite"
echo "========================================"
echo ""

for dep in cobc curl timeout; do
    if ! command -v "$dep" &> /dev/null; then
        echo -e "${RED}ERROR: required tool '$dep' not found${NC}"
        exit 1
    fi
done
echo -e "${GREEN}OK${NC} $(cobc --version | head -1)"

echo ""
echo "Building..."
if ! make all > "$TEST_OUTPUT/build.log" 2>&1; then
    echo -e "${RED}BUILD FAILED${NC} - see $TEST_OUTPUT/build.log"
    exit 1
fi
echo -e "${GREEN}OK${NC} build succeeded"
echo ""

# ---------------------------------------------------------------------------
echo -e "${CYAN}Build artifacts${NC}"
# ---------------------------------------------------------------------------

begin_test "binaries-exist"
if [[ -x "$CLI" && -x "$BIN_DIR/cobol-ai-cli" && -x "$PROJECT_ROOT/cobol-ai" ]]; then
    pass_test
else
    fail_test "expected cobol-ai, cobol-ai.bin and bin/cobol-ai-cli to be executable"
fi

# The wrapper once exec'd itself after a rename, which hung the CLI forever.
begin_test "wrapper-execs-the-binary"
if grep -q 'exec .*cobol-ai\.bin' "$PROJECT_ROOT/cobol-ai"; then
    pass_test
else
    fail_test "wrapper must exec cobol-ai.bin, not itself"
fi

# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}Configuration validation${NC}"
# ---------------------------------------------------------------------------

# A fake secret-tool on PATH keeps these deterministic regardless of what
# is actually in the developer's keyring.
KEYRING_DIR="$TEST_OUTPUT/keyring"

# setup_fake_keyring <value returned by lookup, empty for no entry>
setup_fake_keyring() {
    rm -rf "$KEYRING_DIR"
    mkdir -p "$KEYRING_DIR"
    cat > "$KEYRING_DIR/secret-tool" <<EOF
#!/bin/bash
[ "\$1" = "lookup" ] && printf '%s' '$1'
exit 0
EOF
    chmod +x "$KEYRING_DIR/secret-tool"
    cat > "$KEYRING_DIR/cobol-ai-helper.sh" <<'HSTUB'
#!/bin/bash
echo '200' > "${COBOL_AI_STATUS_FILE:-/tmp/cobol-ai-status.txt}"
echo '{"response":"KEYRING-STUB","done":true}' \
    > "${COBOL_AI_RESPONSE_FILE:-/tmp/cobol-ai-response.json}"
HSTUB
    chmod +x "$KEYRING_DIR/cobol-ai-helper.sh"
}

# run_with_keyring <log> <extra env assignments...> -- runs from KEYRING_DIR
run_with_keyring() {
    local log="$1"; shift
    ( cd "$KEYRING_DIR" && PATH="$KEYRING_DIR:$PATH" \
        env "$@" timeout 60 "$CLI" "a question" ) > "$log" 2>&1
}

begin_test "missing-api-key-is-rejected"
reset_cache
setup_fake_keyring ""
run_with_keyring "$CURRENT_LOG" -u AI_OLLAMA_API_KEY
assert_output_has "$CURRENT_LOG" "AI_OLLAMA_API_KEY not set" && pass_test

begin_test "short-api-key-is-rejected"
reset_cache
AI_OLLAMA_API_KEY="abc" timeout 30 "$CLI" "hello" > "$CURRENT_LOG" 2>&1
assert_output_has "$CURRENT_LOG" "too short" && pass_test

begin_test "non-http-base-url-is-rejected"
reset_cache
AI_OLLAMA_BASE_URL="ftp://example.com" timeout 30 "$CLI" "hello" \
    > "$CURRENT_LOG" 2>&1
assert_output_has "$CURRENT_LOG" "must start with http" && pass_test

# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}Interactive commands${NC}"
# ---------------------------------------------------------------------------

begin_test "help-lists-documented-commands"
reset_cache
run_cli_input "$CURRENT_LOG" 'help\nexit\n'
assert_output_has "$CURRENT_LOG" \
    "help" "history" "theme" "models" "stats" "cache clear" && pass_test

begin_test "stats-reports-empty-cache"
reset_cache
run_cli_input "$CURRENT_LOG" 'stats\nexit\n'
assert_output_has "$CURRENT_LOG" "Cached Items: 0000" && pass_test

# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}Response cache${NC}"
# ---------------------------------------------------------------------------

begin_test "cache-hit-survives-process-exit"
reset_cache
cache_record "PROMPT ALPHA" "ALPHA-RESPONSE" > "$CACHE_FILE"
run_cli "$CURRENT_LOG" "PROMPT ALPHA"
assert_output_has "$CURRENT_LOG" "CACHE HIT" "ALPHA-RESPONSE" && pass_test

# Regression: the lookup key used to be written into cache slot 1, which is
# also a real entry, so the search compared slot 1 against itself and every
# prompt was answered with entry 1's response.
begin_test "different-prompt-does-not-false-hit"
reset_cache
cache_record "PROMPT ALPHA" "ALPHA-RESPONSE" > "$CACHE_FILE"
run_cli "$CURRENT_LOG" "PROMPT BETA is entirely unrelated"
assert_output_lacks "$CURRENT_LOG" "CACHE HIT" "ALPHA-RESPONSE" && pass_test

# Regression: the key was truncated to 64 chars, of which the model name ate
# 13, so prompts sharing an opening phrase collided.
begin_test "long-shared-prefix-does-not-collide"
reset_cache
PREFIX="Explain in detail and with careful reasoning the following topic"
cache_record "$PREFIX one" "PREFIX-ONE-RESPONSE" > "$CACHE_FILE"
run_cli "$CURRENT_LOG" "$PREFIX two"
assert_output_lacks "$CURRENT_LOG" "PREFIX-ONE-RESPONSE" && pass_test

begin_test "hit-and-miss-counters-are-accurate"
reset_cache
cache_record "PROMPT ALPHA" "ALPHA-RESPONSE" > "$CACHE_FILE"
run_cli "$CURRENT_LOG" "PROMPT ALPHA"
assert_output_has "$CURRENT_LOG" "Cache Hits:   00001" "Cache Misses: 00000" \
    && pass_test

begin_test "cache-is-rewritten-on-exit"
reset_cache
cache_record "PROMPT ALPHA" "ALPHA-RESPONSE" > "$CACHE_FILE"
run_cli "$CURRENT_LOG" "PROMPT ALPHA"
if [[ -f "$CACHE_FILE" ]] && grep -qF "ALPHA-RESPONSE" "$CACHE_FILE"; then
    pass_test
else
    fail_test "cache file lost its entry after a clean exit"
fi

begin_test "expired-entries-are-dropped"
reset_cache
{
    cache_record "PROMPT STALE" "STALE-RESPONSE" "20200101000000"
    cache_record "PROMPT ALPHA" "ALPHA-RESPONSE"
} > "$CACHE_FILE"
run_cli "$CURRENT_LOG" "PROMPT ALPHA"
if grep -qF "STALE-RESPONSE" "$CACHE_FILE"; then
    fail_test "entry older than the TTL survived a load/save cycle"
else
    assert_output_has "$CURRENT_LOG" "CACHE HIT" "ALPHA-RESPONSE" && pass_test
fi

begin_test "load-stops-at-the-table-limit"
reset_cache
for i in $(seq -w 1 25); do
    cache_record "BULK PROMPT $i" "BULK-RESPONSE-$i"
done > "$CACHE_FILE"
run_cli_input "$CURRENT_LOG" 'stats\nexit\n'
assert_output_has "$CURRENT_LOG" "Cached Items: 0020" && pass_test

begin_test "corrupt-cache-file-is-ignored"
reset_cache
printf 'not a cache record\n\x00\x01garbage\nshort\n' > "$CACHE_FILE"
run_cli_input "$CURRENT_LOG" 'stats\nexit\n'
assert_output_has "$CURRENT_LOG" "Cached Items: 0000" && pass_test

begin_test "cache-clear-empties-memory-and-disk"
reset_cache
{
    cache_record "PROMPT ALPHA" "ALPHA-RESPONSE"
    cache_record "PROMPT GAMMA" "GAMMA-RESPONSE"
} > "$CACHE_FILE"
run_cli_input "$CURRENT_LOG" 'cache clear\nstats\nexit\n'
if [[ -f "$CACHE_FILE" ]]; then
    fail_test "cache file still exists after 'cache clear'"
else
    assert_output_has "$CURRENT_LOG" "Cached Items: 0000" && pass_test
fi

# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}Helper script${NC}"
# ---------------------------------------------------------------------------

# Regression: the helper used to re-source .env unconditionally, so it
# overrode the caller and the `model` command could never take effect.
begin_test "helper-honours-caller-environment"
COBOL_AI_HELPER_DRY_RUN=1 \
AI_OLLAMA_DEFAULT_MODEL="probe-model" \
    ./cobol-ai-helper.sh "hi" > "$CURRENT_LOG" 2>&1
assert_output_has "$CURRENT_LOG" "MODEL=probe-model" && pass_test

begin_test "helper-uses-model-argument-over-env"
COBOL_AI_HELPER_DRY_RUN=1 \
AI_OLLAMA_DEFAULT_MODEL="probe-model" \
    ./cobol-ai-helper.sh "hi" "argument-model" > "$CURRENT_LOG" 2>&1
assert_output_has "$CURRENT_LOG" \
    "MODEL=argument-model" '"model":"argument-model"' && pass_test

# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}Cache miss path (stubbed helper)${NC}"
# ---------------------------------------------------------------------------
#
# The program invokes ./cobol-ai-helper.sh relative to its working directory,
# so running it from a directory holding a stub intercepts the API call
# without touching the real helper. This exercises the miss path offline.

STUB_DIR="$TEST_OUTPUT/stub"
STUB_ARGS="$STUB_DIR/helper-args.txt"

setup_stub_helper() {
    rm -rf "$STUB_DIR"
    mkdir -p "$STUB_DIR"
    cat > "$STUB_DIR/cobol-ai-helper.sh" <<STUB
#!/bin/bash
printf '%s\n' "\$*" >> "$STUB_ARGS"
if [ "\$1" = "--prompt-file" ] && [ -f "\$2" ]; then
    cp "\$2" "$STUB_DIR/last-prompt.txt"
fi
echo '{"model":"stub","response":"STUB-RESPONSE","done":true}' \
    > "\${COBOL_AI_RESPONSE_FILE:-/tmp/cobol-ai-response.json}"
STUB
    chmod +x "$STUB_DIR/cobol-ai-helper.sh"
}

# run_stubbed <log> <stdin text>
run_stubbed() {
    ( cd "$STUB_DIR" && printf '%b' "$2" | timeout 60 "$CLI" ) > "$1" 2>&1
}

begin_test "miss-calls-helper-and-shows-response"
reset_cache
setup_stub_helper
run_stubbed "$CURRENT_LOG" 'MISS PROMPT ONE\n\nexit\n'
assert_output_has "$CURRENT_LOG" "STUB-RESPONSE" "Cache Misses: 00001" \
    && pass_test

begin_test "miss-response-is-written-to-cache"
# (asserts on $CACHE_FILE, not the previous log, so it is unaffected by
#  begin_test reassigning CURRENT_LOG)
if grep -qF "STUB-RESPONSE" "$CACHE_FILE" 2>/dev/null; then
    pass_test
else
    fail_test "a fresh response was not persisted to $CACHE_FILE"
fi

# Regression: the selected model must reach the helper, or `model <name>`
# only relabels the banner while the request keeps the old model.
begin_test "model-command-reaches-the-request"
reset_cache
setup_stub_helper
run_stubbed "$CURRENT_LOG" 'model llama2:7b\nMISS PROMPT TWO\n\nexit\n'
if grep -qF "llama2:7b" "$STUB_ARGS" 2>/dev/null; then
    pass_test
else
    fail_test "helper was called without the selected model: $(cat "$STUB_ARGS" 2>/dev/null)"
fi

# The eviction branch in CACHE-RESPONSE only runs once the table is full.
begin_test "eviction-holds-the-table-at-the-limit"
reset_cache
setup_stub_helper
for i in $(seq -w 1 20); do
    cache_record "BULK PROMPT $i" "BULK-RESPONSE-$i"
done > "$CACHE_FILE"
run_stubbed "$CURRENT_LOG" 'EVICTION TRIGGER PROMPT\n\nexit\n'
if grep -qF "BULK-RESPONSE-01" "$CACHE_FILE" 2>/dev/null; then
    fail_test "oldest entry survived eviction"
elif ! grep -qF "STUB-RESPONSE" "$CACHE_FILE" 2>/dev/null; then
    fail_test "new entry was not stored after eviction"
else
    run_cli_input "$CURRENT_LOG" 'stats\nexit\n'
    assert_output_has "$CURRENT_LOG" "Cached Items: 0020" && pass_test
fi

# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}File input${NC}"
# ---------------------------------------------------------------------------

LAST_PROMPT="$STUB_DIR/last-prompt.txt"

begin_test "file-contents-reach-the-prompt"
reset_cache
setup_stub_helper
printf 'alpha line\nbeta line\ngamma line\n' > "$STUB_DIR/sample.txt"
run_stubbed "$CURRENT_LOG" 'file sample.txt summarise this\n\nexit\n'
assert_output_has "$CURRENT_LOG" "[FILE]" "sample.txt" "Lines: 00003" \
    && assert_output_has "$LAST_PROMPT" \
        "summarise this" "BEGIN FILE" "alpha line" "gamma line" "END FILE" \
    && pass_test

# Quotes in file contents used to break the shell command, because the
# prompt was interpolated into a single-quoted helper argument.
begin_test "file-with-quotes-survives-intact"
reset_cache
setup_stub_helper
cat > "$STUB_DIR/quoted.py" <<'PYFILE'
def greet(name):
    """A docstring with 'single' and "double" quotes."""
    return f"Hello, {name}!"
PYFILE
run_stubbed "$CURRENT_LOG" 'file quoted.py explain\n\nexit\n'
assert_output_has "$LAST_PROMPT" \
    "A docstring with 'single' and \"double\" quotes." \
    'return f"Hello, {name}!"' && pass_test

begin_test "missing-file-is-reported-not-sent"
reset_cache
setup_stub_helper
run_stubbed "$CURRENT_LOG" 'file /nonexistent/nope.txt explain\n\nexit\n'
if [[ -s "$STUB_ARGS" ]]; then
    fail_test "helper was called despite the file being unreadable"
else
    assert_output_has "$CURRENT_LOG" "Cannot read file" && pass_test
fi

begin_test "oversized-file-is-truncated"
reset_cache
setup_stub_helper
for i in $(seq 1 500); do
    echo "0123456789012345678901234567890123456789"
done > "$STUB_DIR/big.txt"
run_stubbed "$CURRENT_LOG" 'file big.txt summarise\n\nexit\n'
assert_output_has "$CURRENT_LOG" "truncated" && pass_test

# The attached file must be part of the cache key, or the same question
# asked about a different file would be answered from the first file.
begin_test "attached-file-is-part-of-the-cache-key"
reset_cache
setup_stub_helper
printf 'contents of file one\n' > "$STUB_DIR/one.txt"
printf 'contents of file two\n' > "$STUB_DIR/two.txt"
run_stubbed "$TEST_OUTPUT/key-a.log" 'file one.txt describe it\n\nexit\n'
run_stubbed "$TEST_OUTPUT/key-b.log" 'file two.txt describe it\n\nexit\n'
if grep -qF "CACHE HIT" "$TEST_OUTPUT/key-b.log"; then
    fail_test "a different file reused the first file's cached answer"
elif [[ "$(wc -l < "$CACHE_FILE")" -ne 2 ]]; then
    fail_test "expected 2 distinct cache entries, got $(wc -l < "$CACHE_FILE")"
else
    pass_test
fi

begin_test "same-file-and-question-hits-cache"
run_stubbed "$CURRENT_LOG" 'file one.txt describe it\n\nexit\n'
assert_output_has "$CURRENT_LOG" "CACHE HIT" && pass_test

begin_test "helper-escapes-json-special-characters"
printf 'has "double" quotes\nand a second line\twith a tab\n' \
    > "$TEST_OUTPUT/escape-input.txt"
COBOL_AI_HELPER_DRY_RUN=1 \
    ./cobol-ai-helper.sh --prompt-file "$TEST_OUTPUT/escape-input.txt" \
    esc-model > "$CURRENT_LOG" 2>&1
PAYLOAD_LINE=$(grep -c '^PAYLOAD=' "$CURRENT_LOG")
if [[ "$PAYLOAD_LINE" -ne 1 ]]; then
    fail_test "payload spans multiple lines - a raw newline leaked through"
else
    assert_output_has "$CURRENT_LOG" '\"double\"' '\n' '\t' && pass_test
fi

# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}Output file${NC}"
# ---------------------------------------------------------------------------

begin_test "responses-are-appended-to-output-file"
reset_cache
setup_stub_helper
rm -f "$STUB_DIR/session.md"
run_stubbed "$CURRENT_LOG" \
    'output session.md\nfirst question\n\nsecond question\n\nexit\n'
if [[ ! -f "$STUB_DIR/session.md" ]]; then
    fail_test "output file was never created"
elif [[ "$(grep -c '^=== ' "$STUB_DIR/session.md")" -ne 2 ]]; then
    fail_test "expected 2 appended exchanges, got $(grep -c '^=== ' "$STUB_DIR/session.md")"
else
    assert_output_has "$STUB_DIR/session.md" \
        "> first question" "> second question" "STUB-RESPONSE" && pass_test
fi

begin_test "output-off-stops-writing"
reset_cache
setup_stub_helper
rm -f "$STUB_DIR/session.md"
run_stubbed "$CURRENT_LOG" \
    'output session.md\nkept question\n\noutput off\ndropped question\n\nexit\n'
if grep -qF "dropped question" "$STUB_DIR/session.md"; then
    fail_test "kept writing after 'output off'"
else
    assert_output_has "$STUB_DIR/session.md" "> kept question" && pass_test
fi

# A bare "output" used to overwrite the setting with the empty argument
# it had just parsed, silently disabling logging.
begin_test "bare-output-reports-without-clearing"
reset_cache
setup_stub_helper
rm -f "$STUB_DIR/session.md"
run_stubbed "$CURRENT_LOG" \
    'output session.md\noutput\nstill logging\n\nexit\n'
assert_output_has "$CURRENT_LOG" "Current output file: session.md" \
    && assert_output_has "$STUB_DIR/session.md" "> still logging" \
    && pass_test

begin_test "unwritable-output-path-is-reported"
reset_cache
setup_stub_helper
run_stubbed "$CURRENT_LOG" \
    'output /nonexistent-dir-xyz/out.txt\na question\n\nexit\n'
assert_output_has "$CURRENT_LOG" "Cannot write output file" \
    "STUB-RESPONSE" && pass_test

# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}HTTP status handling${NC}"
# ---------------------------------------------------------------------------
#
# A stub that reports a chosen HTTP status lets us drive the retry
# classifier without a server: a 401 must stop immediately, a 429 or 5xx
# must use the full backoff schedule.

# setup_failing_stub <http status> <response body>
setup_failing_stub() {
    rm -rf "$STUB_DIR"
    mkdir -p "$STUB_DIR"
    cat > "$STUB_DIR/cobol-ai-helper.sh" <<STUB
#!/bin/bash
printf 'call\n' >> "$STUB_ARGS"
echo '$1' > "\${COBOL_AI_STATUS_FILE:-/tmp/cobol-ai-status.txt}"
echo '$2' > "\${COBOL_AI_RESPONSE_FILE:-/tmp/cobol-ai-response.json}"
exit 1
STUB
    chmod +x "$STUB_DIR/cobol-ai-helper.sh"
}

stub_call_count() {
    [[ -f "$STUB_ARGS" ]] && wc -l < "$STUB_ARGS" || echo 0
}

begin_test "unauthorized-is-not-retried"
reset_cache
setup_failing_stub 401 '{"error":"invalid api key"}'
run_stubbed "$CURRENT_LOG" 'a question\n\nexit\n'
CALLS=$(stub_call_count)
if [[ "$CALLS" -ne 1 ]]; then
    fail_test "401 was attempted $CALLS times, expected 1"
else
    assert_output_has "$CURRENT_LOG" "not retrying" "401" && pass_test
fi

begin_test "rate-limit-is-retried"
reset_cache
setup_failing_stub 429 '{"error":"rate limited"}'
run_stubbed "$CURRENT_LOG" 'a question\n\nexit\n'
CALLS=$(stub_call_count)
if [[ "$CALLS" -ne 4 ]]; then
    fail_test "429 was attempted $CALLS times, expected 4 (1 + 3 retries)"
else
    assert_output_has "$CURRENT_LOG" "429" "retry attempts exhausted" \
        && pass_test
fi

begin_test "server-error-is-retried"
reset_cache
setup_failing_stub 503 '{"error":"unavailable"}'
run_stubbed "$CURRENT_LOG" 'a question\n\nexit\n'
CALLS=$(stub_call_count)
if [[ "$CALLS" -ne 4 ]]; then
    fail_test "503 was attempted $CALLS times, expected 4"
else
    assert_output_has "$CURRENT_LOG" "5xx" && pass_test
fi

begin_test "not-found-is-not-retried"
reset_cache
setup_failing_stub 404 '{"error":"model not found"}'
run_stubbed "$CURRENT_LOG" 'a question\n\nexit\n'
CALLS=$(stub_call_count)
if [[ "$CALLS" -ne 1 ]]; then
    fail_test "404 was attempted $CALLS times, expected 1"
else
    assert_output_has "$CURRENT_LOG" "404" "BASE_URL" && pass_test
fi

begin_test "unreachable-host-is-retried-as-network"
reset_cache
setup_failing_stub 000 '{}'
run_stubbed "$CURRENT_LOG" 'a question\n\nexit\n'
CALLS=$(stub_call_count)
if [[ "$CALLS" -ne 4 ]]; then
    fail_test "network failure was attempted $CALLS times, expected 4"
else
    assert_output_has "$CURRENT_LOG" "Could not reach the API" && pass_test
fi

begin_test "failed-request-is-not-cached"
if grep -qF "error" "$CACHE_FILE" 2>/dev/null; then
    fail_test "a failed request was written to the cache"
else
    pass_test
fi

# The real helper must record a status for the COBOL side to read.
begin_test "helper-records-http-status"
HELPER_STATUS="$TEST_OUTPUT/helper-status.txt"
rm -f "$HELPER_STATUS"
AI_OLLAMA_API_KEY="test-key-0123456789" \
AI_OLLAMA_BASE_URL="http://127.0.0.1:1" \
COBOL_AI_STATUS_FILE="$HELPER_STATUS" \
COBOL_AI_RESPONSE_FILE="$TEST_OUTPUT/helper-response.json" \
    ./cobol-ai-helper.sh "hi" test-model > "$CURRENT_LOG" 2>&1
if [[ "$(cat "$HELPER_STATUS" 2>/dev/null)" == "000" ]]; then
    pass_test
else
    fail_test "expected status 000 for a refused connection, got '$(cat "$HELPER_STATUS" 2>/dev/null)'"
fi

# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}Credential sources${NC}"
# ---------------------------------------------------------------------------

begin_test "keyring-supplies-key-when-env-is-empty"
reset_cache
setup_fake_keyring "keyring-supplied-key-9999"
run_with_keyring "$CURRENT_LOG" -u AI_OLLAMA_API_KEY
assert_output_has "$CURRENT_LOG" "encrypted credentials" "KEYRING-STUB" \
    && pass_test

begin_test "keyring-temp-file-is-cleaned-up"
if [[ -e "${SCRATCH_PREFIX}key.txt" ]]; then
    fail_test "the key was left behind in ${SCRATCH_PREFIX}key.txt"
else
    pass_test
fi

begin_test "environment-key-wins-over-keyring"
reset_cache
setup_fake_keyring "keyring-supplied-key-9999"
run_with_keyring "$CURRENT_LOG" AI_OLLAMA_API_KEY=env-key-0123456789
assert_output_has "$CURRENT_LOG" "Configuration loaded successfully" \
    && assert_output_lacks "$CURRENT_LOG" "encrypted credentials" \
    && pass_test

begin_test "helper-falls-back-to-keyring"
setup_fake_keyring "keyring-supplied-key-9999"
cp "$PROJECT_ROOT/cobol-ai-helper.sh" "$KEYRING_DIR/real-helper.sh"
( cd "$KEYRING_DIR" && PATH="$KEYRING_DIR:$PATH" \
    env -u AI_OLLAMA_API_KEY COBOL_AI_HELPER_DRY_RUN=1 \
    ./real-helper.sh "hi" a-model ) > "$CURRENT_LOG" 2>&1
assert_output_has "$CURRENT_LOG" "KEY_SOURCE=keyring" && pass_test

begin_test "helper-prefers-environment-over-keyring"
( cd "$KEYRING_DIR" && PATH="$KEYRING_DIR:$PATH" \
    env AI_OLLAMA_API_KEY=env-key-0123456789 COBOL_AI_HELPER_DRY_RUN=1 \
    ./real-helper.sh "hi" a-model ) > "$CURRENT_LOG" 2>&1
assert_output_has "$CURRENT_LOG" "KEY_SOURCE=environment" && pass_test

begin_test "no-key-anywhere-names-the-keyring-option"
reset_cache
setup_fake_keyring ""
run_with_keyring "$CURRENT_LOG" -u AI_OLLAMA_API_KEY
assert_output_has "$CURRENT_LOG" "secret-tool store" && pass_test

# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}Concurrent sessions${NC}"
# ---------------------------------------------------------------------------
#
# Scratch files used to have fixed names, so two overlapping runs shared
# one prompt file and one response file and could answer each other's
# question. The helper below sleeps to guarantee the runs overlap.

begin_test "concurrent-runs-do-not-cross-talk"
CONC_DIR="$TEST_OUTPUT/concurrent"
rm -rf "$CONC_DIR"; mkdir -p "$CONC_DIR"
cat > "$CONC_DIR/cobol-ai-helper.sh" <<'CSTUB'
#!/bin/bash
PROMPT="$(cat "$2")"
sleep 2
echo '200' > "$COBOL_AI_STATUS_FILE"
echo "{\"response\":\"ECHO[$PROMPT]\",\"done\":true}" \
    > "$COBOL_AI_RESPONSE_FILE"
CSTUB
chmod +x "$CONC_DIR/cobol-ai-helper.sh"
reset_cache
( cd "$CONC_DIR" && env COBOL_AI_RUN_ID=conc-a timeout 60 "$CLI" \
    "ALPHA-QUESTION" > "$CONC_DIR/a.log" 2>&1 ) &
( cd "$CONC_DIR" && env COBOL_AI_RUN_ID=conc-b timeout 60 "$CLI" \
    "BETA-QUESTION" > "$CONC_DIR/b.log" 2>&1 ) &
wait
A_GOT=$(grep -o 'ECHO\[[A-Z-]*\]' "$CONC_DIR/a.log" | head -1)
B_GOT=$(grep -o 'ECHO\[[A-Z-]*\]' "$CONC_DIR/b.log" | head -1)
if [[ "$A_GOT" == "ECHO[ALPHA-QUESTION]" && "$B_GOT" == "ECHO[BETA-QUESTION]" ]]; then
    pass_test
else
    fail_test "answers crossed over: A got '$A_GOT', B got '$B_GOT'"
fi

begin_test "state-lives-outside-tmp"
reset_cache
setup_stub_helper
run_stubbed "$CURRENT_LOG" 'a question\n\nexit\n'
if [[ -f "$CACHE_FILE" ]]; then
    pass_test
else
    fail_test "cache was not written to $CACHE_FILE"
fi

begin_test "scratch-files-are-removed-after-a-request"
LEFTOVER=$(ls "${SCRATCH_PREFIX}"* 2>/dev/null | tr '\n' ' ')
if [[ -n "$LEFTOVER" ]]; then
    fail_test "scratch files left behind: $LEFTOVER"
else
    pass_test
fi

# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}Session commands${NC}"
# ---------------------------------------------------------------------------

begin_test "models-lists-the-catalogue"
reset_cache
run_cli_input "$CURRENT_LOG" 'models\nexit\n'
assert_output_has "$CURRENT_LOG" "Available Models" "llama2:7b" \
    "deepseek-r1:1.5b" && pass_test

begin_test "theme-without-argument-shows-help"
reset_cache
run_cli_input "$CURRENT_LOG" 'theme\nexit\n'
assert_output_has "$CURRENT_LOG" "Available Themes" "dark" "light" \
    && pass_test

begin_test "theme-change-persists-to-state"
reset_cache
run_cli_input "$CURRENT_LOG" 'theme light\nexit\n'
if [[ "$(cat "$STATE_DIR/theme.txt" 2>/dev/null | tr -d ' ')" == "light" ]]; then
    assert_output_has "$CURRENT_LOG" "Theme changed to: light" && pass_test
else
    fail_test "theme was not saved to $STATE_DIR/theme.txt"
fi

begin_test "clear-runs-without-error"
reset_cache
run_cli_input "$CURRENT_LOG" 'clear\nexit\n'
assert_output_lacks "$CURRENT_LOG" "ERR" && pass_test

begin_test "history-records-prompts-not-commands"
reset_cache
setup_stub_helper
run_stubbed "$CURRENT_LOG" 'a real question\n\nmodels\nhistory\nexit\n'
assert_output_has "$CURRENT_LOG" "Command History" "a real question" \
    && pass_test

PREV_LOG="$CURRENT_LOG"
begin_test "history-output-is-not-space-padded"
if [[ ! -f "$PREV_LOG" ]]; then
    fail_test "previous log $PREV_LOG is missing"
elif grep -qE 'a real question {10,}' "$PREV_LOG"; then
    fail_test "history printed the whole padded field"
else
    pass_test
fi

# Regression: the dispatch compared WS-COMMAND-TYPE(1:11) against the
# 12-character literal "conversation", which can never match, so the
# documented command was sent to the API as a question instead.
begin_test "conversation-command-is-dispatched"
reset_cache
setup_stub_helper
run_stubbed "$CURRENT_LOG" 'a real question\n\nconversation\nexit\n'
assert_output_has "$CURRENT_LOG" "Conversation History" \
    "Q: a real question" "A: STUB-RESPONSE" && pass_test

begin_test "conv-abbreviation-still-works"
reset_cache
setup_stub_helper
run_stubbed "$CURRENT_LOG" 'a real question\n\nconv\nexit\n'
assert_output_has "$CURRENT_LOG" "Conversation History" && pass_test

PREV_LOG="$CURRENT_LOG"
begin_test "conversation-timestamp-is-readable"
if [[ ! -f "$PREV_LOG" ]]; then
    fail_test "previous log $PREV_LOG is missing"
elif grep -qE '\[0001\] [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' \
    "$PREV_LOG"; then
    pass_test
else
    fail_test "expected a formatted timestamp, got: $(grep -o '\[0001\].*' "$PREV_LOG" | head -1)"
fi

begin_test "export-writes-the-conversation"
reset_cache
setup_stub_helper
run_stubbed "$CURRENT_LOG" 'a real question\n\nexport\nexit\n'
if [[ -f "$STATE_DIR/export.txt" ]]; then
    assert_output_has "$STATE_DIR/export.txt" "a real question" \
        && pass_test
else
    fail_test "export.txt was not created in $STATE_DIR"
fi

begin_test "export-with-no-conversation-is-refused"
reset_cache
run_cli_input "$CURRENT_LOG" 'export\nexit\n'
assert_output_has "$CURRENT_LOG" "No conversation to export" && pass_test

# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}Retry backoff and installation${NC}"
# ---------------------------------------------------------------------------

# Regression: WAIT-RETRY-DELAY built "sleep N" with STRING INTO
# WS-HELPER-CMD without clearing it first. STRING overwrites from position
# 1 and leaves the rest, so the command carried the tail of the previous
# API call including an unbalanced quote. The shell rejected it and the
# backoff never waited. Counting attempts cannot catch this - only timing.
begin_test "backoff-actually-sleeps"
reset_cache
BACKOFF_DIR="$TEST_OUTPUT/backoff"
rm -rf "$BACKOFF_DIR"; mkdir -p "$BACKOFF_DIR"
cat > "$BACKOFF_DIR/cobol-ai-helper.sh" <<'BSTUB'
#!/bin/bash
echo '429' > "$COBOL_AI_STATUS_FILE"
echo '{"error":"rate limited"}' > "$COBOL_AI_RESPONSE_FILE"
exit 1
BSTUB
chmod +x "$BACKOFF_DIR/cobol-ai-helper.sh"
BACKOFF_START=$(date +%s)
( cd "$BACKOFF_DIR" && timeout 90 "$CLI" "q" ) > "$CURRENT_LOG" 2>&1
BACKOFF_ELAPSED=$(( $(date +%s) - BACKOFF_START ))
if [[ "$BACKOFF_ELAPSED" -lt 6 ]]; then
    fail_test "3 retries took ${BACKOFF_ELAPSED}s; the 1+2+4 backoff did not run"
elif [[ "$BACKOFF_ELAPSED" -gt 20 ]]; then
    fail_test "3 retries took ${BACKOFF_ELAPSED}s, far longer than the 7s schedule"
else
    pass_test
fi

begin_test "retry-emits-no-shell-errors"
PREV_LOG="$TEST_OUTPUT/backoff-actually-sleeps.log"
if grep -qE 'Unterminated|Syntax error' "$PREV_LOG" 2>/dev/null; then
    fail_test "the retry path produced a malformed shell command"
else
    pass_test
fi

# Regression: LOG-ERROR did OPEN OUTPUT on the command-history file, which
# truncates. One API error replaced the user's whole history with error text.
begin_test "errors-do-not-destroy-command-history"
reset_cache
setup_stub_helper
run_stubbed "$TEST_OUTPUT/hist-seed.log" 'remembered question\n\nexit\n'
ERR_DIR="$TEST_OUTPUT/errstub"
rm -rf "$ERR_DIR"; mkdir -p "$ERR_DIR"
cat > "$ERR_DIR/cobol-ai-helper.sh" <<'ESTUB'
#!/bin/bash
echo '401' > "$COBOL_AI_STATUS_FILE"
echo '{"error":"bad key"}' > "$COBOL_AI_RESPONSE_FILE"
exit 1
ESTUB
chmod +x "$ERR_DIR/cobol-ai-helper.sh"
( cd "$ERR_DIR" && printf 'doomed question\n\nexit\n' | timeout 60 "$CLI" ) \
    > "$CURRENT_LOG" 2>&1
if grep -qF "remembered question" "$STATE_DIR/history.txt" 2>/dev/null; then
    pass_test
else
    fail_test "history was destroyed by an error: $(cat "$STATE_DIR/history.txt" 2>/dev/null | head -2)"
fi

begin_test "errors-go-to-their-own-log"
if [[ -f "$STATE_DIR/errors.log" ]] \
   && grep -qF "401" "$STATE_DIR/errors.log"; then
    pass_test
else
    fail_test "expected the 401 in $STATE_DIR/errors.log"
fi

# Regression: the helper was invoked as "./cobol-ai-helper.sh", relative to
# the working directory, so an installed binary failed every request.
begin_test "install-produces-a-working-entry-point"
INST="$TEST_OUTPUT/prefix"
rm -rf "$INST"
if ! make install PREFIX="$INST" > "$CURRENT_LOG" 2>&1; then
    fail_test "make install failed"
elif [[ ! -x "$INST/bin/cobol-ai" || ! -x "$INST/bin/cobol-ai.bin" \
        || ! -x "$INST/bin/cobol-ai-helper.sh" ]]; then
    fail_test "install did not place all three files in $INST/bin"
else
    pass_test
fi

begin_test "installed-cli-finds-helper-from-any-directory"
ELSEWHERE="$TEST_OUTPUT/elsewhere"
rm -rf "$ELSEWHERE"; mkdir -p "$ELSEWHERE"
reset_cache
( cd "$ELSEWHERE" && env -u COBOL_AI_HELPER timeout 60 \
    "$INST/bin/cobol-ai" "hello" ) > "$CURRENT_LOG" 2>&1
assert_output_lacks "$CURRENT_LOG" "cobol-ai-helper.sh: not found" && pass_test

begin_test "raw-binary-falls-back-to-PATH"
reset_cache
( cd "$ELSEWHERE" && env -u COBOL_AI_HELPER PATH="$INST/bin:$PATH" timeout 60 \
    "$INST/bin/cobol-ai.bin" "hello" ) > "$CURRENT_LOG" 2>&1
assert_output_lacks "$CURRENT_LOG" "cobol-ai-helper.sh: not found" && pass_test

# Regression: the validation loop stopped at 5 while the model table held
# 6, so `llama3:2b` was advertised by `models` but rejected by `model`.
# Deriving the cases from the advertised list is the point - a hand-picked
# example passed while the last entry was broken.
begin_test "every-advertised-model-can-be-selected"
reset_cache
run_cli_input "$TEST_OUTPUT/model-list.log" 'models\nexit\n'
ADVERTISED=$(sed -n 's/.*[[:space:]]\([a-z0-9][a-z0-9.:_-]*:[a-z0-9.]*\)[[:space:]].*/\1/p' \
    "$TEST_OUTPUT/model-list.log" | sort -u)
if [[ -z "$ADVERTISED" ]]; then
    fail_test "could not parse any model names out of the models listing"
else
    REJECTED=""
    for m in $ADVERTISED; do
        reset_cache
        run_cli_input "$TEST_OUTPUT/model-try.log" "model $m\nexit\n"
        grep -qF "Model changed to: $m" "$TEST_OUTPUT/model-try.log" \
            || REJECTED="$REJECTED $m"
    done
    if [[ -n "$REJECTED" ]]; then
        fail_test "advertised but not selectable:$REJECTED"
    else
        pass_test
    fi
fi

begin_test "unknown-model-is-rejected"
reset_cache
run_cli_input "$CURRENT_LOG" 'model definitely-not-a-model:9b\nexit\n'
assert_output_has "$CURRENT_LOG" "Unknown model" && pass_test

# The model name is the only user-controlled value that reaches a shell
# command string, so it must not be able to break out of its quoting.
begin_test "model-name-cannot-inject-a-shell-command"
reset_cache
# Deliberately short: WS-MODEL is PIC X(50), and a longer payload would be
# truncated into harmlessness, making this pass without proving anything.
INJECT_MARKER="/tmp/cobol-ai-ijm"
rm -f "$INJECT_MARKER"
run_cli_input "$CURRENT_LOG" \
    "model x'; touch $INJECT_MARKER; echo '\na question\n\nexit\n"
if [[ -e "$INJECT_MARKER" ]]; then
    rm -f "$INJECT_MARKER"
    fail_test "a crafted model name executed a shell command"
elif grep -qE 'Invalid characters in model name|Unknown model' \
        "$CURRENT_LOG"; then
    pass_test
else
    fail_test "the crafted name was neither rejected nor reported"
fi

# Regression: CMD-VERSION was declared but dispatched nowhere, so typing
# `version` was sent to the API as a question.
begin_test "version-command-is-dispatched"
reset_cache
setup_stub_helper
run_stubbed "$CURRENT_LOG" 'version\nexit\n'
if grep -qF "STUB-RESPONSE" "$CURRENT_LOG"; then
    fail_test "'version' was sent to the API instead of being handled"
else
    assert_output_has "$CURRENT_LOG" "Version:" "Endpoint:" && pass_test
fi

begin_test "banner-and-version-agree"
reset_cache
run_cli_input "$CURRENT_LOG" 'version\nexit\n'
BANNER_V=$(grep -oE 'COBOL AI CLI v[0-9.]+' "$CURRENT_LOG" | head -1 | sed 's/.*v//')
REPORT_V=$(grep -oE 'Version: [0-9.]+' "$CURRENT_LOG" | head -1 | awk '{print $2}')
if [[ -n "$BANNER_V" && "$BANNER_V" == "$REPORT_V" ]]; then
    pass_test
else
    fail_test "banner says '$BANNER_V', version command says '$REPORT_V'"
fi

# Every declared command constant must actually be dispatched somewhere.
begin_test "all-command-constants-are-dispatched"
UNDISPATCHED=""
for c in $(grep -oE '88 (CMD-[A-Z-]+)' src/copybooks/ws-io.cpy | awk '{print $2}'); do
    word=$(grep -E "88 $c " src/copybooks/ws-io.cpy | sed 's/.*VALUE "//; s/".*//')
    grep -rqE "\\b$c\\b" src/copybooks/pd-*.cpy \
        || grep -rqE "\"$word ?\"" src/copybooks/pd-runmode.cpy \
        || UNDISPATCHED="$UNDISPATCHED $c"
done
if [[ -n "$UNDISPATCHED" ]]; then
    fail_test "declared but never dispatched:$UNDISPATCHED"
else
    pass_test
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
reset_cache
echo ""
echo "========================================"
echo "          Test Summary"
echo "========================================"
echo ""
echo "Tests Run:    $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Failed:${NC} ${FAILED_NAMES[*]}"
    echo -e "${YELLOW}Logs in: $TEST_OUTPUT${NC}"
    exit 1
fi
