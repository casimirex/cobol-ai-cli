# COBOL AI CLI - Architecture Documentation

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                          │
│                      (prompt-handler.cob)                        │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Main Program                               │
│                        (main.cob)                                │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Orchestration Layer                    │   │
│  │  - Initialize modules                                     │   │
│  │  - Parse command line                                     │   │
│  │  - Control flow                                           │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐     ┌─────────────────┐     ┌───────────────┐
│    Config     │     │   JSON Parser   │     │ Error Handler │
│  (config.cob) │     │(json-parser.cob)│     │(error-handler)│
│               │     │                 │     │               │
│ - Load env    │     │ - Build payload │     │ - Error codes │
│ - Validate    │     │ - Parse JSON    │     │ - Messages    │
│ - Cache       │     │ - Extract fields│     │ - Logging     │
└───────────────┘     └─────────────────┘     └───────────────┘
        │                       │
        │                       │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────┐
        │   HTTP Client     │
        │ (http-client.cob) │
        │                   │
        │ - Build curl cmd  │
        │ - Execute request │
        │ - Handle response │
        └───────────────────┘
                    │
                    ▼
        ┌───────────────────┐
        │  Response Formatter│
        │(response-formatter)│
        │                   │
        │ - Format output   │
        │ - Wrap text       │
        │ - Display         │
        └───────────────────┘
```

## Data Flow

```
User Input
    │
    ▼
┌─────────────────┐
│ Prompt Handler  │  Validate, sanitize
└─────────────────┘
    │
    ▼
┌─────────────────┐
│    Config       │  Load API key, model, timeout
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  JSON Parser    │  Build {"model": "...", "prompt": "..."}
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  HTTP Client    │  curl POST to API
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  JSON Parser    │  Extract "response" field
└─────────────────┘
    │
    ▼
┌─────────────────┐
│Response Formatter│  Format, display to user
└─────────────────┘
```

## Module Details

### 1. main.cob - Entry Point

**Purpose**: Orchestrate all modules and control program flow.

**Responsibilities**:
- Program initialization
- Command-line argument parsing
- Mode selection (interactive vs one-shot)
- Module coordination
- Resource cleanup

**Entry Points**:
- `MAIN-PROCEDURE`: Program entry point

**Dependencies**:
- config.cob
- prompt-handler.cob
- json-parser.cob
- http-client.cob
- response-formatter.cob
- error-handler.cob

### 2. config.cob - Configuration Management

**Purpose**: Load and validate configuration from environment.

**Entry Points**:
- `INIT-CONFIG`: Load configuration
- `GET-API-KEY`: Retrieve API key
- `GET-BASE-URL`: Retrieve base URL
- `GET-MODEL`: Retrieve model name
- `GET-TIMEOUT`: Retrieve timeout value
- `IS-CONFIG-VALID`: Check configuration validity
- `DISPLAY-CONFIG`: Debug display (masked)

**Environment Variables**:
- `AI_PROVIDERS`: Provider selection (default: ollama)
- `AI_OLLAMA_API_KEY`: API authentication key (required)
- `AI_OLLAMA_BASE_URL`: API endpoint (default: https://ollama.com)
- `AI_OLLAMA_DEFAULT_MODEL`: Model name (default: gpt-oss:120b)
- `AI_OLLAMA_TIMEOUT`: Timeout in ms (default: 60000)

### 3. http-client.cob - HTTP Communication

**Purpose**: Handle HTTP requests via curl.

**Entry Points**:
- `INIT-HTTP-CLIENT`: Initialize with config
- `SEND-POST-REQUEST`: Send JSON payload
- `SET-TIMEOUT`: Set request timeout
- `GET-LAST-STATUS`: Get last HTTP status

**Implementation**:
- Uses SYSTEM call to execute curl
- Writes response to temporary file
- Cleans up after processing

**Curl Command Structure**:
```bash
curl -s -X POST {URL}/api/generate \
     -H 'Authorization: Bearer {API_KEY}' \
     -H 'Content-Type: application/json' \
     -d '{JSON_PAYLOAD}' \
     -o {RESPONSE_FILE} \
     --max-time {TIMEOUT}
```

### 4. json-parser.cob - JSON Handling

**Purpose**: Build and parse JSON for API communication.

**Entry Points**:
- `BUILD-REQUEST-PAYLOAD`: Create JSON request
- `PARSE-RESPONSE`: Extract response field
- `GET-ERROR-FIELD`: Check for API errors
- `UNESCAPE-JSON-STRING`: Handle escape sequences

**JSON Structures**:

Request:
```json
{
  "model": "gpt-oss:120b",
  "prompt": "User's prompt text",
  "stream": false
}
```

Response:
```json
{
  "model": "gpt-oss:120b",
  "response": "AI generated text",
  "done": true
}
```

**Parsing Approach**:
- Simple string search for fields
- Handles escaped quotes and characters
- No external dependencies

### 5. prompt-handler.cob - Input Handling

**Purpose**: Accept and validate user input.

**Entry Points**:
- `INIT-PROMPT-HANDLER`: Initialize
- `GET-PROMPT-INTERACTIVE`: Get prompt interactively
- `GET-PROMPT-ARGUMENT`: Get prompt from args
- `IS-EXIT-COMMAND`: Check for exit command
- `DISPLAY-HELP`: Show help
- `DISPLAY-VERSION`: Show version

**Validation**:
- Minimum length: 1 character
- Maximum length: 500 characters
- Empty input rejected

**Special Commands**:
- `help` - Display help
- `version` - Display version
- `exit` / `quit` - Exit program
- `clear` - Clear screen

### 6. response-formatter.cob - Output Formatting

**Purpose**: Format and display AI responses.

**Entry Points**:
- `INIT-RESPONSE-FORMATTER`: Initialize
- `FORMAT-RESPONSE`: Format text
- `DISPLAY-RESPONSE`: Display with formatting
- `DISPLAY-ERROR`: Display error message
- `DISPLAY-WITH-METADATA`: Display with metadata
- `ENABLE-METADATA` / `DISABLE-METADATA`: Toggle metadata
- `ENABLE-COLOR` / `DISABLE-COLOR`: Toggle colors

**Features**:
- Word wrapping to 80 characters
- Escape sequence handling (`\n`, `\t`, `\"`)
- Metadata display (tokens, model)
- Error formatting

### 7. error-handler.cob - Error Management

**Purpose**: Centralized error handling.

**Entry Points**:
- `INIT-ERROR-HANDLER`: Initialize
- `GET-ERROR`: Get message by code
- `SET-ERROR`: Set current error
- `DISPLAY-ERROR`: Print error to console
- `IS-ERROR`: Check if error code
- `GET-CURRENT-ERROR`: Get last error

**Error Code Ranges**:
- `0000`: Success
- `1000-1999`: Configuration errors
- `2000-2999`: HTTP/Network errors
- `3000-3999`: JSON errors
- `4000-4999`: Input errors
- `5000-5999`: System errors

## Security Considerations

### API Key Protection
- Never hardcoded in source
- Loaded from environment variables
- Masked in debug output
- Excluded from git via .gitignore

### Input Sanitization
- Prompt length limits
- JSON escaping for special characters
- Command injection prevention

### Temporary Files
- Unique filenames with timestamps
- Automatic cleanup on exit
- Stored in `/tmp` directory

## Performance Considerations

### Memory Management
- Fixed buffer sizes for COBOL
- Efficient string handling
- Minimal temporary file usage

### Network Efficiency
- Configurable timeouts
- Single request per prompt
- No streaming (simpler implementation)

### Build Optimization
- Modular compilation
- Separate object files
- Incremental builds supported

## Testing Strategy

### Unit Tests
- Module isolation
- Mock API responses
- Configuration validation

### Integration Tests
- Module interactions
- End-to-end API calls
- Error handling flows

### Performance Tests
- Response time measurement
- Large prompt handling
- Concurrent request handling

## Future Enhancements

1. **Streaming Support**
   - Implement `stream: true`
   - Progressive response display

2. **Conversation History**
   - Maintain context across prompts
   - Session management

3. **Multiple Models**
   - Model selection at runtime
   - Model switching

4. **Plugin System**
   - Custom processors
   - Extension hooks

5. **Caching**
   - Response caching
   - Configuration caching

6. **Batch Mode**
   - Multiple prompts from file
   - Result aggregation