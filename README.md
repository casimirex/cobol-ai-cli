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

### Phase 1 Features (v1.2.0) ✨ COMPLETE
| Feature | Description |
|---------|-------------|
| **Loading Spinner** | Animated spinner during API requests (`\|/-` animation) |
| **Syntax Highlighting** | Code blocks highlighted in cyan for better readability |
| **Custom Themes** | Switch between dark and light themes with `theme` command |
| **Input Validation** | Real-time prompt length indicator (max 500 chars) |
| **Command History** | View previous prompts with `history` command |
| **Clear Screen** | Clean the terminal with `clear` command |
| **History Persistence** | Commands saved across sessions to `/tmp/cobol-ai-history.txt` |
| **Enhanced Colored UI** | Beautiful terminal colors for all output |
| **Status Indicators** | Visual feedback with `[SEND]`, `[RECV]`, `[OK]`, `[ERR]` icons |

### Phase 2 Features (v1.3.0) ✨ NEW
| Feature | Description |
|---------|-------------|
| **Conversation History** | View full conversation with timestamps using `conversation` command |
| **Export Conversations** | Export chats to text file with `export` command |
| **Model Switching** | Switch between AI models mid-session with `model <name>` command |
| **Model Listing** | See available models with `models` command |

### Phase 3 Features (v1.4.0) ✨ NEW
| Feature | Description |
|---------|-------------|
| **Pipe Support** | Accept input from stdin: `echo "prompt" | ./cobol-ai` |

### File Input (v1.6.0) ✨ NEW

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

### Phase 4 Features (v1.5.0) ✨ COMPLETE
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
========================================
       COBOL AI CLI v1.0.0
       Ollama Cloud Integration
========================================

Model: gpt-oss:120b

Sending request to Ollama API...
Response received (00292 bytes)
--------------------------------------------------
AI: 2 + 2 = 4.
--------------------------------------------------

Thank you for using COBOL AI CLI!
```

---

## Screenshots

### One-Shot Mode - Simple Query
![One-Shot Mode](screenshots/Screenshot%20from%202026-07-09%2012-30-35.png)

### Interactive Mode - Conversation
![Interactive Mode](screenshots/Screenshot%20from%202026-07-09%2012-31-12.png)

### Phase 4 Features - Retry & Cache Statistics
![Phase 4 Features](screenshots/Pasted%20image.png)

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
# Outputs: /tmp/cobol-ai-response.json
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
│   └── main.cob             # Main COBOL program (single-file architecture)
├── tests/                    # Test files
│   └── test-runner.sh       # Test script
├── .env                      # Environment config
├── .env.example             # Environment template
├── .gitignore               # Git ignore patterns
├── Makefile                 # Build automation
├── cobol-ai                 # Wrapper script (recommended entry point)
├── cobol-ai.bin             # Compiled COBOL binary (called by wrapper)
├── cobol-ai-helper.sh       # API helper script
├── run-test.sh              # Test runner
└── roadmap.md               # Project requirements
```

**Note on Architecture:** This project uses a single-file modular architecture. While copybooks (`.cpy` files) are a common COBOL pattern for code reuse, GnuCOBOL's free-format mode has limited copybook support. Instead, the code is organized into clearly marked **sections** within `main.cob`:

- **CONFIGURATION** - Environment variable loading and validation
- **HTTP CLIENT** - API request handling
- **JSON PARSING** - Request building and response parsing
- **INPUT/OUTPUT** - User interaction handling
- **PROGRAM STATE** - Execution flow control

This approach provides clean separation of concerns while maintaining compatibility.

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
| Main Program | `main.cob` | Entry point, orchestration |
| Configuration | `main.cob` | Load settings from `.env` |
| HTTP Client | `cobol-ai-helper.sh` | Make API requests via curl |
| JSON Parser | `main.cob` | Build/parse JSON payloads |
| Response Formatter | `main.cob` | Clean and display AI responses |
| Input Handler | `main.cob` | Manage user prompts |

**Single-File Design:** All COBOL modules are organized into clearly documented sections within `main.cob`, making it easy to navigate while maintaining separation of concerns.

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

## Testing

### Run All Tests

```bash
make test
```

The suite runs **offline and costs nothing**. Because the response cache is
file-backed, seeding `/tmp/cobol-ai-cache.dat` lets the program answer from
cache without calling the API, and cache-miss paths are covered by running the
CLI from a directory containing a stub `cobol-ai-helper.sh`. No API key is
needed — the tests export a fake one and point the base URL at a dead port.

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

### v1.8.0 (Keyring Credentials) - Latest
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