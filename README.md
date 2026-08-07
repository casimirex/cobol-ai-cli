# COBOL AI CLI

<div align="center">

**A COBOL Command-Line Interface for the Ollama Cloud API**

[![GnuCOBOL](https://img.shields.io/badge/GnuCOBOL-3.1%2B-blue.svg)](https://sourceforge.net/projects/open-cobol/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

*Bringing modern AI capabilities to legacy COBOL systems*

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [API Reference](#api-reference)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## The Book

A complete field guide — installation through internals, every command, all
sixteen defects found and fixed, and the testing discipline behind them:

**[`ebook/index.html`](ebook/index.html)** — open it in any browser. Self-contained,
no build step, light and dark themes.

---

## Overview

COBOL AI CLI is a command-line interface that enables COBOL applications to interact with the Ollama Cloud API. It bridges the gap between legacy COBOL systems and modern AI capabilities, allowing you to send prompts and receive AI-generated responses directly from your terminal or COBOL applications.

### Key Highlights

- 🚀 **Native COBOL Implementation** - Built entirely in COBOL using GnuCOBOL
- 🔒 **Secure** - API keys managed via environment variables
- 📦 **Lightweight** - Minimal dependencies (only `curl` required)
- 🔧 **Modular Architecture** - Clean separation of concerns
- 📝 **JSON Handling** - Built-in JSON parsing for API communication

---

## Features

### Phase 1 — Interface (v1.2.0)
| Feature | Description |
|---------|-------------|
| **Loading Spinner** | Animated spinner during API requests (`\|/-` animation) |
| **Syntax Highlighting** | Code blocks highlighted in cyan for better readability |
| **Custom Themes** | Switch between dark and light themes with `theme` command |
| **Input Validation** | Real-time prompt length indicator (max 500 chars) |
| **Command History** | View previous prompts with `history` command |
| **Clear Screen** | Clean the terminal with `clear` command |
| **History Persistence** | Commands saved across sessions to `$XDG_STATE_HOME/cobol-ai-cli/history.txt` |
| **Enhanced Colored UI** | Beautiful terminal colors for all output |
| **Status Indicators** | Visual feedback with `[SEND]`, `[RECV]`, `[OK]`, `[ERR]` icons |

### Phase 2 — Conversation and models (v1.3.0)
| Feature | Description |
|---------|-------------|
| **Conversation History** | View full conversation with timestamps using `conversation` command |
| **Export Conversations** | Export chats to text file with `export` command |
| **Model Switching** | Switch between AI models mid-session with `model <name>` command |
| **Model Listing** | See available models with `models` command |

### Phase 3 — Pipes (v1.4.0)
| Feature | Description |
|---------|-------------|
| **Pipe Support** | Accept input from stdin: `echo "prompt" | ./cobol-ai` |

### Phase 3 — File input and output (v1.6.0)

Attach a file's contents to a question, in either mode:

```bash
# One-shot
./cobol-ai "file src/main.cob explain the cache eviction logic"

# Interactive
> file README.md summarise the setup steps

# Question is optional - defaults to "Explain what this file does."
> file config.json
```

Contents are capped at 10,000 characters; longer files are truncated with a
warning. The attached file is part of the cache key, so asking the same
question about a different file is a separate entry.

### Phase 4 — Reliability (v1.5.0, corrected through v1.10.x)
| Feature | Description |
|---------|-------------|
| **Retry Logic** | Retries only what can succeed: 429, 5xx and network failures back off exponentially (3 retries, 1s base, 30s max); 401/403/404 fail immediately with the reason |
| **Response Caching** | Persistent cache of recent responses (20 entries, 7-day TTL) to reduce API calls |
| **Keyring Credentials** | Reads the API key from the system keyring via `secret-tool`, so it need not sit in plaintext |
| **Error Handling** | Comprehensive error codes and user-friendly error messages |
| **Session Statistics** | Cache hit/miss statistics displayed at end of session |

### Core Features
| Feature | Description |
|---------|-------------|
| **One-shot Mode** | Send a single prompt and receive a response |
| **Interactive Mode** | Interactive session for multiple prompts |
| **Environment Configuration** | Configure via `.env` file |
| **Timeout Management** | Configurable request timeouts |
| **Clean Output** | Formatted AI responses with unicode conversion |
| **Wrapper Script** | Automatic `.env` loading via `./cobol-ai` |

---

## Prerequisites

### Required

- **GnuCOBOL** (version 3.1 or higher)
  ```bash
  # Ubuntu/Debian
  sudo apt-get install gnucobol
  
  # Fedora/RHEL
  sudo dnf install gnucobol
  ```

- **curl** - For HTTP requests
  ```bash
  # Ubuntu/Debian
  sudo apt-get install curl
  
  # Fedora/RHEL
  sudo dnf install curl
  ```

### Optional

- **Ollama Account** - Get your API key from [ollama.com/settings/keys](https://ollama.com/settings/keys)

- **secret-tool** - To keep the API key out of plaintext `.env`
  ```bash
  # Ubuntu/Debian
  sudo apt-get install libsecret-tools

  # Fedora/RHEL
  sudo dnf install libsecret
  ```

- **Docker** / **dpkg-deb** - Only for `make docker` and `make deb`

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/cobol-ai-cli.git
cd cobol-ai-cli
```

### 2. Configure Environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit with your API key
nano .env
```

Add your credentials:
```env
AI_PROVIDERS=ollama
AI_OLLAMA_API_KEY=your_api_key_here
AI_OLLAMA_BASE_URL=https://ollama.com
AI_OLLAMA_DEFAULT_MODEL=gpt-oss:120b
AI_OLLAMA_TIMEOUT=60000
```

### 3. Build the Project

```bash
make all
```

This produces `cobol-ai.bin`, which the `./cobol-ai` wrapper runs. The binary is
a build artifact and is not committed, so a fresh clone must be built before the
wrapper will work.

### 4. Verify Installation

```bash
make check-deps
./run-test.sh "Hello, world!"
```

---

## Quick Start

```bash
# One-shot mode (recommended) - automatically loads .env
./cobol-ai "What is 2+2?"

# Interactive mode (recommended)
./cobol-ai

# Using run-test.sh
./run-test.sh "What is 2+2?"

# Direct binary (requires manual environment loading)
source .env
./cobol-ai.bin "What is 2+2?"
```

**Sample Output:**
```
+======================================================================+
|              COBOL AI CLI v1.11.2                                    |
|                  Powered by Ollama Cloud API                         |
+======================================================================+

[OK] Configuration loaded successfully
    Model: gpt-oss:120b
    Theme: dark

[SEND] Sending request to Ollama API...
| Loading... /
[RECV] Response received (00303 bytes)
[OK] Request completed!

======================================================================
>>> AI Response:
2 + 2 = 4.
======================================================================

Session Statistics:
  Cache Hits:   00000
  Cache Misses: 00001
  Hit Rate:     00000%
```

(Colour is stripped above; the real output is coloured, and the spinner
animates in place rather than printing a frame per line.)

---

## Screenshots

All three were captured at v1.5.0. The banner reads differently today, but every
element shown is still present.

### Interactive mode — asking it to write COBOL

![Interactive session generating a COBOL Hello World program](screenshots/Screenshot%20from%202026-07-09%2012-30-35.png)

The banner, the `[OK]` configuration summary, the `[SEND]` / `[RECV]` / `[OK]`
status icons, and a response whose fenced code block is highlighted in cyan.

### The same answer, continued

![Markdown table of COBOL divisions and highlighted shell commands](screenshots/Screenshot%20from%202026-07-09%2012-31-12.png)

The model's markdown table survives intact, shell commands are highlighted, and
the exchange ends at `> Press Enter to continue or exit to quit:`.

### The `help` command

![The help command listing available commands](screenshots/Pasted%20image.png)

A historical artifact: this listing predates `file`, `cache clear` and
`version`. It also shows `conversation`, which at the time silently did nothing
— see the v1.9.1 changelog entry.

---

## Usage

### One-Shot Mode

Pass a prompt as a command-line argument:

```bash
./cobol-ai "Explain quantum computing"
```

### Interactive Mode

Run without arguments for an interactive session:

```bash
./cobol-ai
```

**Interactive Commands:**

| Command | Description |
|---------|-------------|
| `help` | Show available commands |
| `version` | Show version, model, endpoint, state directory and helper path |
| `history` | Show command history |
| `clear` | Clear the screen |
| `theme` | Change color theme (dark/light) |
| `theme <name>` | Switch theme (e.g., `theme light`) |
| `models` | List available AI models |
| `model <name>` | Switch to a different model |
| `export` | Export conversation to a file |
| `conversation` | Show conversation history |
| `output <file>` | Append each exchange to a file |
| `output` | Show the current output file |
| `output off` | Stop appending |
| `stats` | Show cache and error statistics |
| `cache clear` | Empty the persistent response cache |
| `file <path> [question]` | Ask a question about a file's contents |
| `exit` | Exit the program |
| `quit` | Exit the program |

### Using the Helper Script (Advanced)

For direct API calls without the CLI:

```bash
./cobol-ai-helper.sh "Your prompt here"
# Writes the response to $COBOL_AI_RESPONSE_FILE, defaulting to
# /tmp/cobol-ai-response.json, and the HTTP status to $COBOL_AI_STATUS_FILE.
# The CLI passes per-run paths so concurrent sessions cannot collide.

./cobol-ai-helper.sh --prompt-file ./prompt.txt gpt-oss:120b   # long prompts
COBOL_AI_HELPER_DRY_RUN=1 ./cobol-ai-helper.sh "hi"            # resolve config only
```

---

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AI_OLLAMA_API_KEY` | Your Ollama API key | *(required)* |
| `AI_OLLAMA_BASE_URL` | API endpoint | `https://ollama.com` |
| `AI_OLLAMA_DEFAULT_MODEL` | Model to use | `gpt-oss:120b` |
| `AI_OLLAMA_TIMEOUT` | Request timeout (ms) | `60000` |

### Available Models

- `gpt-oss:120b` - Default large model
- `llama2` - Llama 2 model
- `mistral` - Mistral model
- *(See Ollama documentation for full list)*

---

## Project Structure

```
cobol-ai-cli/
├── bin/                      # Compiled executables
│   └── cobol-ai-cli         # Main executable (alternative entry point)
├── docs/                     # Documentation
│   ├── README.md            # User documentation
│   └── ARCHITECTURE.md      # Architecture details
├── examples/                 # Example files
│   └── example-prompts.txt  # Sample prompts
├── src/                      # Source code
│   ├── main.cob             # Program skeleton: FDs, file control, entry point
│   └── copybooks/           # Data and paragraphs, one file per concern
│       ├── ws-config.cpy    # Credentials, keyring, defaults, retry state
│       ├── ws-cache.cpy     # Cache table, record layout, hashing state
│       ├── ws-errors.cpy    # Error state and error code constants
│       ├── ws-http.cpy      # Request/response buffers, JSON cursors
│       ├── ws-io.cpy        # Prompt, attached file, pipe, output file
│       ├── ws-ui.cpy        # Colours, banner text, spinner, highlighting
│       ├── ws-state.cpy     # Run mode, history, conversation, models
│       ├── pd-config.cpy    # Loading and validating configuration
│       ├── pd-errors.cpy    # Logging and reporting errors
│       ├── pd-runmode.cpy   # Pipe/argument detection, the prompt loop
│       ├── pd-http.cpy      # Payload, retry loop, status, JSON parsing
│       ├── pd-cache.cpy     # Cache lookup, storage and persistence
│       ├── pd-fileio.cpy    # File input and the output file
│       ├── pd-history.cpy   # Command history
│       ├── pd-conversation.cpy  # Conversation recording and export
│       ├── pd-models.cpy    # Model selection and statistics
│       ├── pd-ui.cpy        # Banner, themes, help, response rendering
│       └── pd-cleanup.cpy   # Shutdown and session summary
├── tests/                    # Test files
│   └── test-runner.sh       # Test script
├── .env                      # Environment config
├── .env.example             # Environment template
├── .gitignore               # Git ignore patterns
├── Makefile                 # Build automation
├── cobol-ai                 # Wrapper script (recommended entry point)
├── cobol-ai.bin             # Compiled binary (built by `make`, not in git)
├── cobol-ai-helper.sh       # API helper script
├── run-test.sh              # Test runner
└── roadmap.md               # Project requirements
```

**Note on Architecture:** The program is one compilation unit assembled from
copybooks. `main.cob` holds only the skeleton — file control entries, FDs and
`MAIN-PROCEDURE` — and `COPY` pulls in the rest from `src/copybooks`, split by
concern: `ws-*.cpy` for data definitions, `pd-*.cpy` for paragraphs.

Copybooks are textual includes, so this is file-level organisation rather than
compilation-unit isolation. Separate units would mean `CALL` between programs
with shared state passed through `LINKAGE`; with working storage this widely
shared, that is a rewrite rather than a refactor, and it buys little for a
single-binary CLI.

Two ordering rules matter:

- `MAIN-PROCEDURE` must stay the first paragraph in the `PROCEDURE DIVISION`,
  because control falls into whatever comes first. Its `STOP RUN` prevents
  execution running on into the copied paragraphs.
- Everything else is reached by `PERFORM`, and there is no `PERFORM ... THRU`
  or `GO TO` anywhere in the program, so the order of the `COPY` statements
  carries no meaning.

Build with `make`, which supplies `-I src/copybooks`. A bare
`cobc -x -free src/main.cob` will fail to resolve the copybooks.

---

## Architecture

### High-Level Flow

```
┌─────────────────┐
│   User Input    │
│  (Prompt/CLI)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Configuration  │
│   (.env file)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  JSON Builder   │────▶│  HTTP Client    │
│   (Payload)     │     │    (curl)       │
└─────────────────┘     └────────┬────────┘
                                 │
                                 ▼
                    ┌─────────────────────┐
                    │   Ollama Cloud API   │
                    │  (https://ollama.com) │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │  JSON Parser    │
                    │  (Response)     │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │    Display      │
                    │   (AI Response) │
                    └─────────────────┘
```

### Module Breakdown

| Module | Location | Purpose |
|--------|----------|---------|
| Entry point | `src/main.cob` | FDs, file control, `MAIN-PROCEDURE` |
| Configuration | `pd-config.cpy` | Load and validate settings, keyring lookup |
| HTTP client | `cobol-ai-helper.sh` | Make API requests via curl |
| Retry / status | `pd-http.cpy` | Backoff, HTTP status classification, JSON parsing |
| Response cache | `pd-cache.cpy` | Key hashing, lookup, persistence |
| File I/O | `pd-fileio.cpy` | Attached file input, output file |
| Response formatter | `pd-ui.cpy` | Clean and display AI responses |
| Input handler | `pd-runmode.cpy` | Prompt loop and command dispatch |

For detailed architecture, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## API Reference

### Request Format

```json
{
  "model": "gpt-oss:120b",
  "prompt": "Your question here",
  "stream": false
}
```

### Response Format

```json
{
  "model": "gpt-oss:120b",
  "response": "AI response text",
  "done": true
}
```

---

## Distribution

### Container

```bash
make docker                      # or: docker build -t cobol-ai-cli .
docker run --rm -e AI_OLLAMA_API_KEY=... cobol-ai-cli "What is 2+2?"
```

Two-stage build: GnuCOBOL compiles in the first stage, the runtime image
carries only `libcob4`, `curl` and the three executables (~192 MB). It runs as
an unprivileged `cobol` user. Persist the cache and history across runs with:

```bash
docker run --rm -v cobol-ai-state:/home/cobol/.local/state \
    -e AI_OLLAMA_API_KEY=... cobol-ai-cli "your prompt"
```

### Debian package

```bash
make deb                         # build/cobol-ai-cli_<version>_<arch>.deb
sudo dpkg -i build/cobol-ai-cli_*.deb
```

Installs `cobol-ai`, `cobol-ai.bin` and `cobol-ai-helper.sh` into `/usr/bin`,
and declares `libcob4` and `curl` as dependencies (`libsecret-tools` is
recommended, for keyring support).

### Source tarball

```bash
make dist                        # build/cobol-ai-cli-<version>.tar.gz
```

Self-contained: unpacking it and running `make all && ./tests/test-runner.sh`
builds and passes the full test suite. It deliberately excludes `.env`.

### Install from a working copy

```bash
make install                     # honours PREFIX, default /usr/local
make install PREFIX=$HOME/.local
```

All four paths install the **wrapper** as the entry point, not the bare binary:
the wrapper points the program at the helper beside it, which is what lets an
installed copy work from any directory.

---

## Testing

### Run All Tests

```bash
make test
```

The suite runs **offline and costs nothing**. Because the response cache is
file-backed, seeding it lets the program answer from cache without calling the
API, and cache-miss paths are covered by running the CLI from a directory
containing a stub `cobol-ai-helper.sh`. No API key is needed — the tests export
a fake one and point the base URL at a dead port. State is redirected into
`test-output/` via `XDG_STATE_HOME`, so a run never touches your real cache,
history or theme.

### Manual smoke test

```bash
./run-test.sh "Test prompt"
```

### Test Categories

| Group | Covers |
|-------|--------|
| Build artifacts | Both binaries build; the wrapper execs `cobol-ai.bin` and not itself |
| Configuration validation | Missing, short, and malformed config is rejected |
| Interactive commands | `help` lists documented commands; `stats` reports cache state |
| Response cache | Cross-process hits, false-hit and prefix-collision regressions, hit/miss counters, TTL expiry, table limit, corrupt files, `cache clear` |
| Helper script | Caller environment wins over `.env`; model argument precedence |
| Cache miss path | Helper invocation, response caching, model forwarding, eviction at the table limit |

Every test asserts on real program output. The suite was validated by
mutation: each regression test was confirmed to fail when the bug it describes
is reintroduced into the source.

---

## Troubleshooting

### Common Issues

#### "AI_OLLAMA_API_KEY not set"

**Solution:** Ensure your `.env` file exists and contains the API key:
```bash
source .env
echo $AI_OLLAMA_API_KEY
```

#### "Error: Failed to send request"

**Solutions:**
1. Check internet connectivity
2. Verify API key is valid
3. Ensure `curl` is installed

#### "Configuration error"

**Solution:** Verify all required environment variables are set:
```bash
cat .env
```

#### "cobc: command not found"

**Solution:** Install GnuCOBOL:
```bash
sudo apt-get install gnucobol
```

### Debug Mode

Enable verbose output:
```bash
make debug
./bin/cobol-ai-cli "test"
```

---

## Makefile Targets

| Target | Description |
|--------|-------------|
| `all` | Build the project (default) |
| `clean` | Remove build artifacts |
| `run` | Build and run interactively |
| `test` | Run test suite |
| `check-deps` | Verify dependencies |
| `lint` | Syntax check |
| `debug` | Build with debug symbols |
| `install` | Install system-wide |
| `uninstall` | Remove system installation |
| `help` | Show help |

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow COBOL coding conventions
- Add tests for new features
- Update documentation
- Run `make lint` before committing

---

## Security

### Best Practices

- ✅ Never commit `.env` file
- ✅ Use environment variables for secrets
- ✅ Validate all inputs
- ✅ Clean up temporary files
- ✅ Use HTTPS for API calls

### API Key Management

```bash
# Set via environment
export AI_OLLAMA_API_KEY="your-key-here"

# Or use .env file
source .env
```

---

## Changelog

### v1.11.2 (Screenshot Captions) - Latest
- **All three screenshot captions were wrong.** They were written without ever
  opening the images. The first, labelled "One-Shot Mode - Simple Query", is
  actually an interactive session asking the model to write COBOL. The second,
  "Interactive Mode - Conversation", is the continuation of that same answer.
  The third, "Retry and cache statistics", is the `help` command output and
  shows neither retries nor cache statistics. Replaced with descriptions taken
  from looking at them.
- Noted that all three predate `file`, `cache clear` and `version`.

### v1.11.1 (Documentation Accuracy)
- **The "Sample Output" block was fabricated.** It showed a `v1.0.0` banner and
  an `AI:` response prefix that appears nowhere in the source — the program has
  printed a boxed banner and `>>> AI Response:` for many versions. Replaced with
  output captured from an actual run.
- **Fixed banner misalignment.** Making the version a constant in v1.10.2 left a
  fixed pad sized for the old string, so the title line was 12 characters short
  of the box. The subtitle line was one short, and had been since the beginning.
  Both are now composed into fixed-width `WS-BANNER-*` fields — which also puts
  two long-dead declarations to use — so the box stays square for any version.
- **`make dist` no longer wipes your build.** It depended on `clean`, which
  deleted `cobol-ai.bin`; since the artifact stopped being tracked in v1.11.0
  that left the working copy without a runnable binary. `dist` copies an
  explicit file list, so it never needed `clean`.
- Feature sections no longer advertise v1.3.0 and v1.4.0 work as "✨ NEW".
- Corrected the helper-script and testing sections, which still documented fixed
  `/tmp` paths after v1.9.0 made them per-run; documented `secret-tool` as an
  optional prerequisite; added `version` to the command table.

Verified rather than assumed: every `make` target the README names exists, every
command in its table is dispatched, and the prompt limit, cache size, TTL, file
cap and retry count all match the source.

### v1.11.0 (Distribution)
- **Container image**: two-stage `Dockerfile`; the runtime carries `libcob4`,
  `curl` and the executables but not the compiler. Runs unprivileged. Verified
  by a real API call from inside the container.
- **Debian package**: `make deb` produces an installable `.deb` declaring
  `libcob4` and `curl`. Verified by unpacking it and running the result from an
  unrelated directory.
- **Source tarball**: `make dist`. Verified by extracting it into a clean
  directory, building, and running the full test suite from it.
- **`make version`** reads the version from `WS-VERSION`, so packaging and the
  binary cannot disagree — there is one version string in the project.
- 6 new packaging tests, including one asserting the tarball never ships `.env`.

### v1.10.2 (Bounds Sweep)
Swept the codebase for the bug class behind three earlier defects: a hardcoded
bound that should have referenced a declared size. The scanner was validated
against planted canaries first, so an empty result means something.

Clean:
- No loop bound compares against a numeric literal.
- No reference-modified slice mismatches its literal's length.
- All four `OCCURS` tables agree with their `*-MAX` constants.
- No literal slice exceeds its field's `PIC` size.
- `CACHE-RECORD X(25079)` matches the sum of its field widths exactly.

Found and fixed:
- **`version` was declared but dispatched nowhere.** `CMD-VERSION` existed as an
  88-level with no handler, so typing `version` was sent to the API as a
  question. It now reports version, model, endpoint, state directory and the
  resolved helper path.
- **The banner had been reporting v1.8.0 for four releases.** After the copybook
  refactor the banner moved to `pd-ui.cpy`, while the version-bump edits kept
  targeting `main.cob` — so the running program advertised a version four
  releases stale. Version now lives in one constant, `WS-VERSION`, that both the
  banner and the `version` command read.
- 3 new tests, including one asserting the banner and the `version` command
  agree, and one checking every declared command constant is dispatched
  somewhere — the check that would have caught `version` and `conversation`.

### v1.10.1 (Model Selection)
- **Fixed an advertised model that could not be selected.** The validation loop
  ran `UNTIL WS-JSON-I > 5` against a 6-entry table, so `llama3:2b` was listed by
  `models` and rejected by `model` as unknown. The bound is now tied to
  `WS-MODEL-MAX`, declared beside the table.
- `CHANGE-MODEL` no longer borrows `WS-JSON-I` / `WS-JSON-FOUND` as scratch; it
  has its own index and flag.
- **Added a second barrier against shell injection.** The model name is the only
  user-controlled value that reaches a shell command string. The whitelist
  already stopped crafted names, but it was the *sole* defence — verified by
  removing it, after which `model x';touch /tmp/IJ2;echo '` executed. Names
  containing `' ; \` $ & |` are now rejected outright, so relaxing the whitelist
  later (to allow arbitrary Ollama models, say) will not silently open a hole.
- 3 new tests, including one that walks every model the `models` command
  advertises rather than a hand-picked example — the previous test used
  `llama2:7b` and passed while the last entry was broken.

**A note on the injection test.** The first version used a marker path under
`test-output/`, which made the payload longer than `WS-MODEL`'s 50 characters.
It was truncated into harmlessness and the test passed without proving anything.
The marker is now `/tmp/cobol-ai-ijm`, short enough that the payload survives
intact — confirmed by removing both barriers and watching the test fail.

### v1.10.0 (Backoff, Error Log, Installation)
- **Exponential backoff never ran.** `WAIT-RETRY-DELAY` built its command with
  `STRING "sleep " ... INTO WS-HELPER-CMD` without clearing the field first.
  `STRING` overwrites from position 1 and leaves the rest intact, so the command
  was `sleep N` followed by the tail of the previous API call — including an
  unbalanced quote. The shell rejected the whole thing with
  `Syntax error: Unterminated quoted string` and **no wait ever happened**.
  Measured: three retries took 0 seconds. Against a real 429 that means
  hammering the endpoint as fast as the loop runs, which is precisely what
  backoff exists to prevent. Now measured at 7s for the documented 1+2+4.
- **The retry schedule was also off by one.** `2 ** WS-CURRENT-RETRY` with the
  counter already at 1 gave 2s/4s/8s, not the documented 1s/2s/4s.
- **A single API error destroyed your command history.** `LOG-ERROR` did
  `OPEN OUTPUT` on the *command-history* file — `OPEN OUTPUT` truncates — so one
  401 replaced the whole history with error text. Errors now append to their own
  `errors.log` in the state directory, with a readable timestamp and the code.
- **`make install` produced a broken installation.** The helper was invoked as
  `./cobol-ai-helper.sh`, relative to the working directory, so an installed
  binary failed every request with `sh: 1: ./cobol-ai-helper.sh: not found`.
  The helper is now resolved once at startup: `$COBOL_AI_HELPER` if set, else
  `./cobol-ai-helper.sh` if present, else via `$PATH`. `make install` ships the
  wrapper, the binary and the helper together, honours `PREFIX`, and the wrapper
  points the program at the helper beside it.
- 7 new tests. The backoff one asserts on **elapsed time**, not call count —
  the existing retry tests counted attempts and so could never have caught this.

### v1.9.1 (Session Commands)
- **Fixed `conversation` never running.** The dispatch compared
  `WS-COMMAND-TYPE(1:11)` against the 12-character literal `"conversation"`.
  A reference-modified slice has to match the literal's length, so that test
  could never be true: the documented command fell through to the prompt
  handler and was sent to the API as a question, costing a call and returning
  nonsense. The undocumented `conv` abbreviation happened to work, which is
  why it went unnoticed. Both now compare the trimmed value.
- **Fixed padded output.** `history` and `conversation` displayed whole fixed
  fields, so each entry trailed hundreds of spaces and wrapped the terminal.
  Conversation timestamps rendered as `2026080714495876`; they now read
  `2026-08-07 14:50:42`.
- 11 new tests covering the six commands that had none: `history`, `clear`,
  `theme`, `models`, `export`, `conversation`. The other five were verified
  working, not assumed.

### v1.9.0 (Per-User, Per-Run State Paths)
- **Fixed cross-talk between concurrent sessions.** All 11 runtime files used
  fixed `/tmp` names. `prompt.txt`, `response.json` and `status.txt` are written
  then read back within one request, so two overlapping runs would trade
  answers — reproduced before the fix: run A asked "ALPHA-QUESTION" and was
  answered "ECHO[BETA-QUESTION]", with nothing in the output to suggest
  anything was wrong.
- **Fixed lockout on shared machines.** Files owned by whoever ran first could
  not be truncated by anyone else. The worst case was `key.txt` at mode `0600`:
  a second user's keyring lookup failed to write, silently produced an empty
  key, and reported "AI_OLLAMA_API_KEY not set" while their key sat in the
  keyring.
- Persistent state (cache, history, theme, conversation, export) now lives in
  `$XDG_STATE_HOME/cobol-ai-cli`, falling back to `~/.local/state/cobol-ai-cli`,
  created `0700`. It survives reboots, which `/tmp` does not.
- Per-request scratch files carry a run id: `/tmp/cobol-ai-<runid>-*`. The
  wrapper exports the shell PID; a direct `cobol-ai.bin` call derives one from
  the clock plus a random suffix.
- The helper is told the paths through `COBOL_AI_RESPONSE_FILE` and
  `COBOL_AI_STATUS_FILE`, defaulting to the old names for manual use.
- Widened every path field to 200 characters — the intermediate `WS-HISTORY-FILE`
  was still `X(100)` and silently truncated long state paths.
- 3 new tests, including two genuinely concurrent runs that must not swap
  answers. Mutation-checked: restoring shared scratch names fails it.

**Migration**: existing state in `/tmp/cobol-ai-*.txt` is not read any more.
Nothing breaks — a new cache and history are created on first run — but old
history and cached responses are not carried over. Delete the stale files at
your convenience.

### v1.8.0 (Keyring Credentials)
- **`LOAD-ENCRYPTED-CREDENTIALS` now does what the README always said it did.**
  It was a three-line stub that set a flag to `"N"` and returned, while the
  banner carried a "(encrypted credentials)" branch on a condition that could
  never be true.
- The key is read from the system keyring with `secret-tool` when no key is
  present in the environment or `.env`. Store it once:

  ```bash
  secret-tool store --label='COBOL AI CLI' service cobol-ai-cli key api-key
  ```

  Then remove `AI_OLLAMA_API_KEY` from `.env` — the wrapper exports `.env`, so
  a key left there still wins.
- **Both** the COBOL program and `cobol-ai-helper.sh` consult the keyring. The
  helper is what actually calls `curl`, so a COBOL-only change would have looked
  correct and changed nothing about the request.
- Falls back silently when `secret-tool` is not installed.
- 6 new tests using a fake `secret-tool` on `PATH`, so they are deterministic
  regardless of what is in the developer's real keyring.

**Precedence**: `AI_OLLAMA_API_KEY` in the environment (including anything
exported from `.env`) → system keyring → error naming the `secret-tool store`
command.

> The COBOL side cannot capture command output, so the lookup passes through
> `/tmp/cobol-ai-key.txt`, created under `umask 077` and deleted immediately
> after reading. That is a brief single-user-readable window on disk; the bash
> helper reads the keyring directly with no temp file.

### v1.7.0 (HTTP Status Handling)
- **The retry loop now knows what went wrong.** `WS-LAST-HTTP-STATUS` was
  declared and never once assigned; `curl -s` ran without `-w '%{http_code}'`
  or `--fail`, so an HTTP 401 wrote its error body to the response file and
  exited 0. Every failure looked identical — "no valid response in JSON" — and
  every failure was retried.
- **Terminal errors fail immediately**: 401, 403, 404 and other 4xx stop after
  one attempt with a specific message (`HTTP 401 unauthorized - check
  AI_OLLAMA_API_KEY`) instead of burning the full 1s/2s/4s backoff.
- **Transient errors still back off**: 429, 5xx, and connection/DNS/timeout
  failures (recorded as status `000`) use all three retries.
- Error codes are set per failure class, so `stats` and the error log
  distinguish network from config from API faults.
- 7 new tests driving each status class through a stub, plus a check that the
  real helper records the status.

| Status | Behaviour |
|--------|-----------|
| 200 with unusable body | Retried (may be transient) |
| 429, 5xx | Retried with exponential backoff |
| 000 (unreachable) | Retried |
| 401, 403, 404, other 4xx | Fails immediately with the reason |

### v1.6.1 (Output File)
- **`output <file>` now actually writes.** The command reported "Responses will
  be saved to this file" while `WRITE-TO-OUTPUT-FILE` was a `CONTINUE` stub that
  saved nothing. Each exchange is now appended with a timestamp, the model name,
  the prompt and the response.
- **`output off`** stops appending; a bare **`output`** reports the current
  setting instead of silently clearing it, which is what it used to do — it
  overwrote the filename with the empty argument it had just parsed.
- 4 new tests covering append, `off`, the bare form, and an unwritable path.

### v1.6.0 (File Input)
- **`file <path> [question]`**: reads a file and asks the model about it, in
  both one-shot and interactive mode. Contents are capped at 10,000 characters
  and truncated with a warning; the file is part of the cache key.
- **Prompts are passed to the helper through a file** (`--prompt-file`) instead
  of a shell argument. A prompt containing an apostrophe previously broke the
  generated shell command, and file contents make that a certainty.
- **Fixed JSON escaping**: the helper escaped `"` but not backslashes, and left
  raw newlines and tabs in the payload, which is invalid JSON. Any multi-line
  prompt produced a malformed request.
- **Fixed cache records split by newlines**: the cache key's readable tail is
  copied into the record, and a newline there split one record across several
  lines, so file-based entries could never be read back.
- 7 new tests covering file input, quoting, truncation, and cache keying.

### v1.5.2 (Real Test Suite)
- **Replaced the placeholder test suite**: five of the six previous "tests" were
  `echo` statements that passed unconditionally, so `make test` reported green
  while the cache was returning wrong answers. 22 behavioural tests now assert on
  real program output, run offline, and cost nothing.
- **Fixed `.env` overriding the caller**: `cobol-ai-helper.sh` re-sourced `.env`
  on every call, so no setting could be changed at runtime.
- **Fixed `model <name>` being cosmetic**: the helper built its own payload from
  `.env`, so switching models changed the banner and the cache key but never the
  actual request. The selected model is now passed through to the helper.
- **`make all` builds `cobol-ai.bin`**: previously only `bin/cobol-ai-cli` was
  built by the Makefile while the wrapper ran a separately-compiled binary, so
  the two could drift and the tests checked the wrong artifact.
- **Added `COBOL_AI_HELPER_DRY_RUN=1`**: reports resolved config and makes no
  network call.

### v1.5.1 (Cache Correctness & Persistence)
- **Fixed wrong cached answers**: the lookup key was written into cache slot 1, which is
  also a real entry, so every lookup compared slot 1 against itself and returned a hit.
  Any prompt after the first got the first prompt's answer. The key now lives in
  dedicated scratch storage.
- **Fixed stale key**: the cache key was built from `WS-PROMPT-TRIMMED`, which is only
  populated later during payload building, so lookups keyed on the *previous* prompt.
- **Persistent cache**: the cache is written to `/tmp/cobol-ai-cache.dat` on exit and
  reloaded at startup, so hits now survive across invocations (previously always 0%).
- **Entry expiry**: cached entries older than 7 days are dropped on load.
- **Stronger cache key**: rolling polynomial hash over the full model+prompt key instead
  of a 64-char prefix, so prompts sharing an opening phrase no longer collide.
- **New `cache clear` command**: empties the cache in memory and on disk.

### v1.5.0 (Phase 4 - Performance & Reliability)
- **Retry Logic**: Automatic retry with exponential backoff (3 retries, 1s base, 30s max delay)
- **Response Caching**: 20-entry cache to reduce API calls
- **Encrypted Credentials**: System keyring integration (secret-tool on Linux)
- **Error Handling**: Comprehensive error codes and user-friendly messages
- **Session Statistics**: Cache hit/miss statistics at end of session
- **Wrapper Script**: Automatic `.env` loading for seamless execution

### v1.4.0 (Phase 3)
- **Pipe Support**: Accept input from stdin (`echo "prompt" | ./cobol-ai`)

### v1.3.0 (Phase 2)
- **Conversation History**: View full conversation with timestamps
- **Export Conversations**: Save chats to text file
- **Model Switching**: Switch between AI models mid-session
- **Model Listing**: Display available models

### v1.2.0 (Phase 1)
- **Loading Spinner**: Animated spinner during API requests
- **Syntax Highlighting**: Code blocks highlighted in cyan
- **Custom Themes**: Dark/light theme support
- **Input Validation**: Real-time prompt length indicator
- **Command History**: Navigate previous prompts
- **Enhanced Colored UI**: Beautiful terminal colors

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Ollama](https://ollama.com) - AI API Provider
- [GnuCOBOL](https://sourceforge.net/projects/open-cobol/) - COBOL Compiler
- The COBOL community for continued support

---

## Support

- 📧 Email: support@example.com
- 📖 Documentation: [docs/README.md](docs/README.md)
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/cobol-ai-cli/issues)

---

<div align="center">

**Built with ❤️ using COBOL**

[⬆ Back to Top](#cobol-ai-cli)

</div>