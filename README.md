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

### Core Features
| Feature | Description |
|---------|-------------|
| **One-shot Mode** | Send a single prompt and receive a response |
| **Interactive Mode** | Interactive session for multiple prompts |
| **Environment Configuration** | Configure via `.env` file |
| **Error Handling** | Comprehensive error codes and messages |
| **Timeout Management** | Configurable request timeouts |
| **Clean Output** | Formatted AI responses with unicode conversion |

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
# One-shot mode (recommended)
./cobol-ai "What is 2+2?"

# Interactive mode (recommended)
./cobol-ai

# Alternative: Using run-test.sh
./run-test.sh "What is 2+2?"

# Alternative: Manual environment loading
source .env
./bin/cobol-ai-cli "What is 2+2?"
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
│   └── cobol-ai-cli         # Main executable
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

### Run Specific Test

```bash
./run-test.sh "Test prompt"
```

### Test Categories

| Test | Description |
|------|-------------|
| Build Verification | Check binary compilation |
| Environment Loading | Verify `.env` parsing |
| API Connectivity | Test API connection |
| CLI Execution | End-to-end testing |

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