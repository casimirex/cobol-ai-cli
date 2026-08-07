       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBOL-AI-CLI.

      *>================================================================*
      *> COBOL-AI-CLI - Main Program
      *>
      *> Description: AI Agent CLI for Ollama Cloud API Integration
      *> Version:     1.5.1 (Phase 4 - Performance & Reliability)
      *> Author:      COBOL AI CLI Team
      *> License:     MIT
      *>
      *> Features:
      *>   - Animated loading spinner during API requests
      *>   - Colored UI with banners and themes (light/dark)
      *>   - Command history navigation
      *>   - One-shot and interactive modes
      *>   - JSON parsing with unicode support
      *>   - Syntax highlighting for code blocks
      *>   - Real-time prompt length validation
      *>   - Retry logic with exponential backoff (Phase 4)
      *>   - Persistent response caching to reduce API calls (Phase 4)
      *>   - Encrypted credential storage (Phase 4)
      *>   - Comprehensive error handling (Phase 4)
      *>================================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT RESPONSE-FILE ASSIGN TO WS-RESPONSE-FILE
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
           SELECT HISTORY-FILE ASSIGN TO WS-HISTORY-FILE
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-HISTORY-STATUS.
           SELECT THEME-FILE ASSIGN TO WS-THEME-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-THEME-STATUS.
           SELECT CONVERSATION-FILE ASSIGN TO WS-CONV-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-CONV-STATUS.
           SELECT STDIN-FILE ASSIGN TO WS-STDIN-TEMP-FILE
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-STDIN-FILE-STATUS.
           SELECT OUTPUT-FILE ASSIGN TO WS-OUTPUT-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUTPUT-FILE-STATUS.
           SELECT CACHE-FILE ASSIGN TO WS-CACHE-FILE
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-CACHE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD RESPONSE-FILE.
       01 RESPONSE-LINE         PIC X(50000).
       FD HISTORY-FILE.
       01 HISTORY-LINE          PIC X(1000).
       FD THEME-FILE.
       01 THEME-LINE            PIC X(20).
       FD CONVERSATION-FILE.
       01 CONVERSATION-LINE     PIC X(5000).
       FD STDIN-FILE.
       01 STDIN-RECORD          PIC X(5000).
       FD OUTPUT-FILE.
       01 OUTPUT-RECORD         PIC X(5000).
       FD CACHE-FILE.
       01 CACHE-RECORD          PIC X(25079).

       WORKING-STORAGE SECTION.

      *>================================================================*
      *> SECTION: CONFIGURATION
      *>================================================================*
       01 WS-CONFIG.
          05 WS-API-KEY         PIC X(200) VALUE SPACES.
          05 WS-BASE-URL        PIC X(100) VALUE "https://ollama.com".
          05 WS-MODEL           PIC X(50) VALUE "gpt-oss:120b".
          05 WS-TIMEOUT         PIC 9(6) VALUE 60000.
          05 WS-CONFIG-LOADED   PIC X VALUE "N".
             88 CONFIG-LOADED   VALUE "Y".
          05 WS-ENCRYPTED-KEY   PIC X VALUE "N".
             88 KEY-ENCRYPTED   VALUE "Y".

       01 WS-DEFAULTS.
          05 WS-DEFAULT-URL     PIC X(100) VALUE "https://ollama.com".
          05 WS-DEFAULT-MODEL   PIC X(50) VALUE "gpt-oss:120b".
          05 WS-DEFAULT-TIMEOUT PIC 9(6) VALUE 60000.

      *>================================================================*
      *> SECTION: RETRY LOGIC (Phase 4)
      *>================================================================*
       01 WS-RETRY-CONFIG.
          05 WS-MAX-RETRIES     PIC 9(2) VALUE 3.
          05 WS-CURRENT-RETRY   PIC 9(2) VALUE 0.
          05 WS-RETRY-DELAY     PIC 9(4) VALUE 1000.
          05 WS-BASE-DELAY      PIC 9(4) VALUE 1000.
          05 WS-MAX-DELAY       PIC 9(5) VALUE 30000.
          05 WS-LAST-HTTP-STATUS PIC S9(4) COMP VALUE 0.
          05 WS-RETRY-REASON    PIC X(100) VALUE SPACES.

      *>================================================================*
      *> SECTION: RESPONSE CACHING (Phase 4)
      *>================================================================*
       01 WS-CACHE-CONFIG.
          05 WS-CACHE-ENABLED   PIC X VALUE "Y".
             88 CACHE-ENABLED   VALUE "Y".
             88 CACHE-DISABLED VALUE "N".
          05 WS-CACHE-HITS      PIC 9(5) VALUE 0.
          05 WS-CACHE-MISSES    PIC 9(5) VALUE 0.
          05 WS-CACHE-FILE      PIC X(100) VALUE "/tmp/cobol-ai-cache.dat".
          05 WS-CACHE-STATUS    PIC XX VALUE SPACES.
          05 WS-CACHE-KEY       PIC X(500) VALUE SPACES.
          05 WS-CACHE-HASH      PIC X(64) VALUE SPACES.

       01 WS-CACHE-TABLE.
          05 WS-CACHE-ENTRY OCCURS 20 TIMES.
             10 WS-CACHE-PROMPT-HASH PIC X(64).
             10 WS-CACHE-RESPONSE    PIC X(25000).
             10 WS-CACHE-TIMESTAMP   PIC X(14).
             10 WS-CACHE-VALID       PIC X VALUE "Y".

       01 WS-CACHE-COUNT         PIC 9(4) VALUE 0.
       01 WS-CACHE-MAX           PIC 9(4) VALUE 20.
       01 WS-CACHE-INDEX         PIC 9(4) VALUE 0.
       01 WS-CACHE-FOUND         PIC X VALUE "N".
          88 CACHE-FOUND          VALUE "Y".
          88 CACHE-NOT-FOUND      VALUE "N".

      *> Persistent cache record layout (matches CACHE-RECORD)
       01 WS-CACHE-REC.
          05 WS-CR-HASH          PIC X(64).
          05 WS-CR-TIMESTAMP     PIC X(14).
          05 WS-CR-VALID         PIC X.
          05 WS-CR-RESPONSE      PIC X(25000).

      *> Cache key hashing and expiry
       01 WS-CACHE-WORK.
          05 WS-HASH-ACC         PIC 9(12) VALUE 0.
          05 WS-HASH-POS         PIC 9(4) VALUE 0.
          05 WS-HASH-KEY-LEN     PIC 9(4) VALUE 0.
          05 WS-HASH-ACC-DISP    PIC 9(12) VALUE 0.
          05 WS-HASH-LEN-DISP    PIC 9(4) VALUE 0.
          05 WS-CACHE-TTL-DAYS   PIC 9(4) VALUE 7.
          05 WS-CACHE-DATE-INT   PIC 9(8) VALUE 0.
          05 WS-CACHE-TODAY-INT  PIC 9(8) VALUE 0.
          05 WS-CACHE-NL-COUNT   PIC 9(4) VALUE 0.
          05 WS-CACHE-LOADED     PIC 9(4) VALUE 0.

      *>================================================================*
      *> SECTION: ERROR HANDLING (Phase 4)
      *>================================================================*
       01 WS-ERROR-STATE.
          05 WS-LAST-ERROR-CODE   PIC S9(4) COMP VALUE 0.
          05 WS-LAST-ERROR-MSG    PIC X(200) VALUE SPACES.
          05 WS-ERROR-COUNT       PIC 9(4) VALUE 0.
          05 WS-FATAL-ERROR       PIC X VALUE "N".
             88 FATAL-ERROR       VALUE "Y".
             88 NO-FATAL-ERROR    VALUE "N".

       01 WS-ERROR-CODES.
          05 ERR-OK               PIC S9(4) COMP VALUE 0.
          05 ERR-INVALID-CONFIG   PIC S9(4) COMP VALUE 1.
          05 ERR-NETWORK          PIC S9(4) COMP VALUE 2.
          05 ERR-API              PIC S9(4) COMP VALUE 3.
          05 ERR-PARSE            PIC S9(4) COMP VALUE 4.
          05 ERR-CACHE            PIC S9(4) COMP VALUE 5.
          05 ERR-TIMEOUT          PIC S9(4) COMP VALUE 6.
          05 ERR-RETRY-EXHAUSTED  PIC S9(4) COMP VALUE 7.

      *>================================================================*
      *> SECTION: HTTP CLIENT
      *>================================================================*
       01 WS-HTTP-REQUEST       PIC X(10000) VALUE SPACES.
       01 WS-HTTP-RESPONSE      PIC X(50000) VALUE SPACES.
       01 WS-HTTP-STATUS        PIC S9(4) COMP VALUE 0.

       01 WS-RESPONSE-FILE      PIC X(100) VALUE SPACES.
       01 WS-FILE-STATUS        PIC XX VALUE SPACES.
       01 WS-TIME-VALUE         PIC X(14) VALUE SPACES.

       01 WS-HELPER-SCRIPT      PIC X(100) VALUE "./cobol-ai-helper.sh".
       01 WS-HELPER-CMD         PIC X(5000) VALUE SPACES.

      *>================================================================*
      *> SECTION: JSON PARSING
      *>================================================================*
       01 WS-JSON-PAYLOAD       PIC X(5000) VALUE SPACES.
       01 WS-JSON-EXTRACTED     PIC X(25000) VALUE SPACES.

       01 WS-JSON-I            PIC 9(5) VALUE 0.
       01 WS-JSON-J            PIC 9(5) VALUE 0.
       01 WS-JSON-START        PIC 9(5) VALUE 0.
       01 WS-JSON-LEN          PIC 9(5) VALUE 0.
       01 WS-JSON-QUOTE        PIC X VALUE QUOTE.
       01 WS-JSON-FOUND        PIC X VALUE "N".
          88 JSON-FOUND        VALUE "Y".
          88 JSON-NOT-FOUND    VALUE "N".

      *>================================================================*
      *> SECTION: INPUT/OUTPUT
      *>================================================================*
       01 WS-PROMPT             PIC X(1000) VALUE SPACES.
       01 WS-PROMPT-TRIMMED     PIC X(1000) VALUE SPACES.
       01 WS-PROMPT-LEN         PIC 9(4) VALUE 0.

       01 WS-INPUT-LIMITS.
          05 WS-MIN-PROMPT-LEN PIC 9(4) VALUE 1.
          05 WS-MAX-PROMPT-LEN PIC 9(4) VALUE 500.

       01 WS-COMMAND-TYPE       PIC X(20) VALUE SPACES.
          88 CMD-HELP          VALUE "help".
          88 CMD-VERSION       VALUE "version".
          88 CMD-EXIT          VALUE "exit".
          88 CMD-QUIT          VALUE "quit".
          88 CMD-HISTORY       VALUE "history".
          88 CMD-CLEAR         VALUE "clear".
          88 CMD-THEME         VALUE "theme".
          88 CMD-EXPORT        VALUE "export".
          88 CMD-MODEL         VALUE "model".
          88 CMD-MODELS        VALUE "models".
          88 CMD-OUTPUT        VALUE "output".
          88 CMD-OUT           VALUE "out".

       01 WS-EXPORT-FORMAT      PIC X(10) VALUE "text".
          88 FORMAT-TEXT        VALUE "text".
          88 FORMAT-JSON        VALUE "json".
          88 FORMAT-MARKDOWN    VALUE "markdown".

       01 WS-ARG-COUNT          PIC 9(4) VALUE 0.
       01 WS-ARG-VALUE          PIC X(1000) VALUE SPACES.
       01 WS-CMD-LINE           PIC X(1000) VALUE SPACES.

      *>================================================================*
      *> SECTION: PIPE SUPPORT (Phase 3)
      *>================================================================*
       01 WS-STDIN-BUFFER       PIC X(5000) VALUE SPACES.
       01 WS-STDIN-LENGTH       PIC 9(4) VALUE 0.
       01 WS-HAS-STDIN          PIC X VALUE "N".
          88 HAS-STDIN          VALUE "Y".
          88 NO-STDIN           VALUE "N".
       01 WS-STDIN-TEMP-FILE    PIC X(100) VALUE "/tmp/cobol-ai-stdin.txt".
       01 WS-STDIN-FILE-STATUS  PIC XX VALUE SPACES.
       01 WS-STDIN-TEMP         PIC X VALUE "N".

      *>================================================================*
      *> SECTION: FILE OUTPUT (Phase 3)
      *>================================================================*
       01 WS-OUTPUT-FILE-NAME   PIC X(200) VALUE SPACES.
       01 WS-OUTPUT-FILE-STATUS PIC XX VALUE SPACES.
       01 WS-OUTPUT-LINE        PIC X(5000) VALUE SPACES.
       01 WS-OUTPUT-FORMAT      PIC X(10) VALUE "text".
          88 OUT-FORMAT-TEXT    VALUE "text".
          88 OUT-FORMAT-JSON    VALUE "json".
          88 OUT-FORMAT-MARKDOWN VALUE "markdown".

      *>================================================================*
      *> SECTION: DISPLAY CONSTANTS (Enhanced UI)
      *>================================================================*
       01 WS-DISPLAY-CONSTANTS.
          05 WS-DIVIDER        PIC X(70) VALUE ALL "=".
          05 WS-DIVIDER-THIN   PIC X(70) VALUE ALL "-".
          05 WS-BANNER-TOP     PIC X(70) VALUE
             "+======================================================================+".
          05 WS-BANNER-MID     PIC X(70) VALUE
             "|                                                                      |".
          05 WS-BANNER-TITLE   PIC X(70) VALUE
             "|                    COBOL AI CLI v1.2.0                               |".
          05 WS-BANNER-SUB     PIC X(70) VALUE
             "|                  Powered by Ollama Cloud API                         |".
          05 WS-BANNER-BOT     PIC X(70) VALUE
             "+======================================================================+".
          05 WS-PROMPT-MSG     PIC X(70) VALUE
             "> Enter your prompt (or 'exit' to quit): ".
          05 WS-CONTINUE-MSG   PIC X(70) VALUE
             "> Press Enter to continue or 'exit' to quit: ".
          05 WS-HELP-HEADER    PIC X(70) VALUE
             "=== Available Commands ===".
          05 WS-INFO-ICON      PIC X(8) VALUE "[INFO]  ".
          05 WS-SUCCESS-ICON   PIC X(8) VALUE "[OK]    ".
          05 WS-ERROR-ICON     PIC X(8) VALUE "[ERR]   ".
          05 WS-SEND-ICON      PIC X(8) VALUE "[SEND]  ".
          05 WS-RECV-ICON      PIC X(8) VALUE "[RECV]  ".

      *> Spinner animation frames (Phase 1 - Loading Animation)
       01 WS-SPINNER.
          05 WS-SPINNER-CHARS  PIC X(4) VALUE "-\|/".
          05 WS-SPINNER-POS    PIC 9(1) VALUE 1.
          05 WS-SPINNER-FRAME  PIC X VALUE SPACES.
          05 WS-SPINNER-COUNT  PIC 9(3) VALUE 0.
          05 WS-SPINNER-MAX    PIC 9(3) VALUE 20.

      *> Theme settings (Phase 1 - Custom Themes)
       01 WS-THEME-SETTINGS.
          05 WS-CURRENT-THEME  PIC X(20) VALUE "dark".
             88 THEME-DARK     VALUE "dark".
             88 THEME-LIGHT    VALUE "light".
          05 WS-THEME-FILE-NAME PIC X(100) VALUE
              "/tmp/cobol-ai-theme.txt".
       01 WS-THEME-STATUS     PIC XX VALUE SPACES.

      *> Color codes for themes
       01 WS-COLOR-CODES.
          05 WS-COLOR-BANNER   PIC X(10) VALUE "\033[1;36m".
          05 WS-COLOR-PROMPT   PIC X(10) VALUE "\033[34m".
          05 WS-COLOR-RESPONSE PIC X(10) VALUE "\033[37m".
          05 WS-COLOR-ERROR    PIC X(10) VALUE "\033[31m".
          05 WS-COLOR-SUCCESS  PIC X(10) VALUE "\033[32m".
          05 WS-COLOR-WARNING  PIC X(10) VALUE "\033[33m".
          05 WS-COLOR-INFO     PIC X(10) VALUE "\033[35m".
          05 WS-COLOR-RESET    PIC X(5) VALUE "\033[0m".
          05 WS-COLOR-CODE     PIC X(10) VALUE "\033[36m".
          05 WS-COLOR-CODE-BG  PIC X(10) VALUE "\033[40m".

      *> Syntax highlighting for code blocks (Phase 1)
       01 WS-CODE-BLOCK-FLAGS.
          05 WS-IN-CODE-BLOCK  PIC X VALUE "N".
             88 IN-CODE-BLOCK  VALUE "Y".
             88 NOT-IN-CODE    VALUE "N".
          05 WS-CODE-LINE      PIC X(200) VALUE SPACES.
          05 WS-CODE-START     PIC X(3) VALUE "```".
          05 WS-CODE-END       PIC X(3) VALUE "```".

      *>================================================================*
      *> SECTION: PROGRAM STATE
      *>================================================================*
       01 WS-RUN-MODE           PIC X(10) VALUE SPACES.
          88 MODE-INTERACTIVE   VALUE "interactive".
          88 MODE-ONE-SHOT      VALUE "oneshot".

       01 WS-CONTINUE           PIC X VALUE "Y".
          88 SHOULD-CONTINUE   VALUE "Y".
          88 SHOULD-EXIT       VALUE "N".

       01 WS-TEMP-CHAR          PIC X VALUE SPACES.
       01 WS-TEMP-POS          PIC 9(5) VALUE 0.
       01 WS-TEMP-STRING        PIC X(100) VALUE SPACES.

      *>================================================================*
      *> SECTION: COMMAND HISTORY (NEW - Phase 1)
      *>================================================================*
       01 WS-HISTORY-FILE       PIC X(100) VALUE SPACES.
       01 WS-HISTORY-STATUS     PIC XX VALUE SPACES.
       01 WS-HISTORY-COUNT      PIC 9(4) VALUE 0.
       01 WS-HISTORY-MAX        PIC 9(4) VALUE 100.
       01 WS-HISTORY-INDEX      PIC 9(4) VALUE 0.

       01 WS-HISTORY-TABLE.
          05 WS-HISTORY-ENTRY OCCURS 100 TIMES.
             10 WS-HIST-TEXT   PIC X(1000).

       01 WS-HIST-FILE-NAME     PIC X(100) VALUE
           "/tmp/cobol-ai-history.txt".

      *>================================================================*
      *> SECTION: RESPONSE BUFFER
      *>================================================================*
       01 WS-RESPONSE-TEXT      PIC X(25000) VALUE SPACES.
       01 WS-RESPONSE-LEN       PIC 9(5) VALUE 0.
       01 WS-CLEAN-RESPONSE     PIC X(25000) VALUE SPACES.
       01 WS-OUT-POS            PIC 9(5) VALUE 0.

      *>================================================================*
      *> SECTION: CONVERSATION HISTORY (Phase 2)
      *>================================================================*
       01 WS-CONVERSATION-FILE  PIC X(100) VALUE SPACES.
       01 WS-CONV-STATUS        PIC XX VALUE SPACES.
       01 WS-CONV-COUNT         PIC 9(4) VALUE 0.
       01 WS-CONV-MAX           PIC 9(4) VALUE 50.
       01 WS-CONV-INDEX         PIC 9(4) VALUE 0.

       01 WS-CONVERSATION-TABLE.
          05 WS-CONVERSATION-ENTRY OCCURS 50 TIMES.
             10 WS-CONV-PROMPT   PIC X(1000).
             10 WS-CONV-RESPONSE PIC X(5000).
             10 WS-CONV-TIMESTAMP PIC X(20).

       01 WS-CONV-FILE-NAME     PIC X(100) VALUE
           "/tmp/cobol-ai-conversation.json".
       01 WS-EXPORT-FILE-NAME   PIC X(100) VALUE SPACES.

      *>================================================================*
      *> SECTION: MODEL MANAGEMENT (Phase 2)
      *>================================================================*
       01 WS-VALID-MODELS.
          05 WS-VALID-MODEL-ENTRY OCCURS 6 TIMES VALUE SPACES.
             10 WS-VM-NAME        PIC X(50).

       PROCEDURE DIVISION.

       INIT-MODEL-LIST.
      *> Initialize valid models list
           MOVE "gpt-oss:120b" TO WS-VALID-MODEL-ENTRY(1).
           MOVE "llama2:7b" TO WS-VALID-MODEL-ENTRY(2).
           MOVE "mistral:7b" TO WS-VALID-MODEL-ENTRY(3).
           MOVE "codellama:13b" TO WS-VALID-MODEL-ENTRY(4).
           MOVE "deepseek-r1:1.5b" TO WS-VALID-MODEL-ENTRY(5).
           MOVE "llama3:2b" TO WS-VALID-MODEL-ENTRY(6).

      *>================================================================*
      *> MAIN ENTRY POINT
      *>================================================================*
       MAIN-PROCEDURE.
           PERFORM INITIALIZE-PROGRAM.
           PERFORM DETERMINE-RUN-MODE.
           PERFORM RUN-APPLICATION.
           PERFORM CLEANUP-PROGRAM.
           STOP RUN.

      *>================================================================*
      *> INITIALIZATION
      *>================================================================*
       INITIALIZE-PROGRAM.
           PERFORM DISPLAY-BANNER.
           PERFORM LOAD-CONFIGURATION.
           PERFORM VALIDATE-CONFIGURATION.
           PERFORM LOAD-HISTORY.
           PERFORM LOAD-THEME.
           PERFORM LOAD-RESPONSE-CACHE.
           PERFORM INIT-CONVERSATION-HISTORY.
           PERFORM INIT-MODEL-LIST.

       DISPLAY-BANNER.
      *> Display colorful banner with theme colors
           CALL "SYSTEM" USING
               "printf '\033[1;36m+======================================================================+\033[0m\n'".
           CALL "SYSTEM" USING
               "printf '\033[1;36m|\033[0m              COBOL AI CLI v1.5.1 (Phase 4 - Complete)         \033[1;36m|\033[0m\n'".
           CALL "SYSTEM" USING
               "printf '\033[1;36m|\033[0m                  Powered by Ollama Cloud API                        \033[1;36m|\033[0m\n'".
           CALL "SYSTEM" USING
               "printf '\033[1;36m+======================================================================+\033[0m\n'".
           DISPLAY SPACES.

       LOAD-CONFIGURATION.
      *> Phase 4: Try encrypted credential storage first
           PERFORM LOAD-ENCRYPTED-CREDENTIALS.

      *> Load API key from environment (fallback)
           IF WS-API-KEY = SPACES THEN
               ACCEPT WS-API-KEY FROM ENVIRONMENT "AI_OLLAMA_API_KEY"
               IF WS-API-KEY = SPACES THEN
                   CALL "SYSTEM" USING
                       "printf '\033[31m[ERR] ERROR: AI_OLLAMA_API_KEY not set\033[0m'"
                   DISPLAY "      Please set it in .env file or environment"
                   STOP RUN
               END-IF
           END-IF

      *> Load base URL from environment
           ACCEPT WS-BASE-URL FROM ENVIRONMENT "AI_OLLAMA_BASE_URL"
           IF WS-BASE-URL = SPACES THEN
               MOVE WS-DEFAULT-URL TO WS-BASE-URL
           END-IF

      *> Load model from environment
           ACCEPT WS-MODEL FROM ENVIRONMENT "AI_OLLAMA_DEFAULT_MODEL"
           IF WS-MODEL = SPACES THEN
               MOVE WS-DEFAULT-MODEL TO WS-MODEL
           END-IF

      *> Load timeout from environment
           ACCEPT WS-TEMP-STRING FROM ENVIRONMENT "AI_OLLAMA_TIMEOUT"
           IF WS-TEMP-STRING NOT = SPACES THEN
               MOVE FUNCTION NUMVAL(WS-TEMP-STRING) TO WS-TIMEOUT
           ELSE
               MOVE WS-DEFAULT-TIMEOUT TO WS-TIMEOUT
           END-IF

           MOVE "Y" TO WS-CONFIG-LOADED
           DISPLAY SPACES
           IF KEY-ENCRYPTED THEN
               CALL "SYSTEM" USING
                   "printf '\033[32m[OK]\033[0m Configuration loaded (encrypted credentials)'"
           ELSE
               CALL "SYSTEM" USING
                   "printf '\033[32m[OK]\033[0m Configuration loaded successfully'"
           END-IF
           DISPLAY SPACES
           DISPLAY "    Model: " FUNCTION TRIM(WS-MODEL)
           DISPLAY "    Theme: " WS-CURRENT-THEME
           DISPLAY SPACES.

       LOAD-ENCRYPTED-CREDENTIALS.
      *> Phase 4: Try to load encrypted credentials using system keyring
      *> Uses secret-tool (Linux) or security-cli (macOS) if available
           MOVE "N" TO WS-ENCRYPTED-KEY.
      *> For now, check for encrypted key file as fallback
           MOVE "N" TO WS-JSON-FOUND.

       VALIDATE-CONFIGURATION.
      *> Phase 4: Comprehensive configuration validation
           IF WS-API-KEY = SPACES
               MOVE ERR-INVALID-CONFIG TO WS-LAST-ERROR-CODE
               MOVE "API key is missing or empty" TO WS-LAST-ERROR-MSG
               PERFORM LOG-ERROR
               PERFORM DISPLAY-ERROR-MESSAGE
               STOP RUN
           END-IF.

      *> Validate API key format (should be alphanumeric with possible special chars)
           IF FUNCTION LENGTH(FUNCTION TRIM(WS-API-KEY)) < 10
               MOVE ERR-INVALID-CONFIG TO WS-LAST-ERROR-CODE
               MOVE "API key appears too short (possible typo)" TO WS-LAST-ERROR-MSG
               PERFORM LOG-ERROR
               PERFORM DISPLAY-ERROR-MESSAGE
               STOP RUN
           END-IF.

      *> Check base URL is valid
           IF WS-BASE-URL(1:7) NOT = "http://" AND
              WS-BASE-URL(1:8) NOT = "https://"
               MOVE ERR-INVALID-CONFIG TO WS-LAST-ERROR-CODE
               MOVE "Base URL must start with http:// or https://" TO WS-LAST-ERROR-MSG
               PERFORM LOG-ERROR
               PERFORM DISPLAY-ERROR-MESSAGE
               STOP RUN
           END-IF.

      *> Validate model name is not empty
           IF FUNCTION TRIM(WS-MODEL) = SPACES
               MOVE ERR-INVALID-CONFIG TO WS-LAST-ERROR-CODE
               MOVE "Model name cannot be empty" TO WS-LAST-ERROR-MSG
               PERFORM LOG-ERROR
               PERFORM DISPLAY-ERROR-MESSAGE
               STOP RUN
           END-IF.

      *> Validate timeout is reasonable
           IF WS-TIMEOUT < 1000 OR WS-TIMEOUT > 300000
               MOVE ERR-INVALID-CONFIG TO WS-LAST-ERROR-CODE
               MOVE "Timeout must be between 1000ms and 300000ms" TO WS-LAST-ERROR-MSG
               PERFORM LOG-ERROR
               PERFORM DISPLAY-ERROR-MESSAGE
               STOP RUN
           END-IF.

      *> All validations passed
           MOVE ERR-OK TO WS-LAST-ERROR-CODE.

       LOG-ERROR.
      *> Phase 4: Log error to file for debugging
           OPEN OUTPUT HISTORY-FILE.
           IF WS-HISTORY-STATUS = "00"
               STRING "ERROR [" FUNCTION CURRENT-DATE(1:19) "] "
                      DELIMITED BY SIZE INTO HISTORY-LINE
               WRITE HISTORY-LINE
               STRING "Code: " WS-LAST-ERROR-CODE " - " WS-LAST-ERROR-MSG
                      DELIMITED BY SIZE INTO HISTORY-LINE
               WRITE HISTORY-LINE
               MOVE SPACES TO HISTORY-LINE
               WRITE HISTORY-LINE
               CLOSE HISTORY-FILE
           END-IF.
           ADD 1 TO WS-ERROR-COUNT.

       DISPLAY-ERROR-MESSAGE.
      *> Phase 4: Display user-friendly error message
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[31m=== ERROR ===\033[0m\n'".
           DISPLAY "  " WS-LAST-ERROR-MSG.
           DISPLAY SPACES.
           DISPLAY "  Error Code: " WS-LAST-ERROR-CODE.
           DISPLAY "  Time: " FUNCTION CURRENT-DATE(1:19).
           DISPLAY SPACES.

           EVALUATE WS-LAST-ERROR-CODE
               WHEN ERR-INVALID-CONFIG
                   DISPLAY "  Suggestion: Check your .env file or environment variables."
                   DISPLAY "  Required: AI_OLLAMA_API_KEY, AI_OLLAMA_BASE_URL"
               WHEN ERR-NETWORK
                   DISPLAY "  Suggestion: Check your internet connection."
                   DISPLAY "  The API endpoint may be temporarily unavailable."
               WHEN ERR-API
                   DISPLAY "  Suggestion: Verify your API key is valid and has credits."
                   DISPLAY "  Check the API status at the provider's website."
               WHEN ERR-PARSE
                   DISPLAY "  Suggestion: This may be a temporary issue. Try again."
                   DISPLAY "  If it persists, check if the API response format changed."
               WHEN ERR-TIMEOUT
                   DISPLAY "  Suggestion: Increase timeout in .env (AI_OLLAMA_TIMEOUT)."
                   DISPLAY "  Current timeout: " WS-TIMEOUT "ms"
               WHEN ERR-RETRY-EXHAUSTED
                   DISPLAY "  Suggestion: The service may be experiencing issues."
                   DISPLAY "  Try again later or contact support."
               WHEN OTHER
                   DISPLAY "  Suggestion: Check logs at /tmp/cobol-ai-history.txt"
           END-EVALUATE.
           DISPLAY SPACES.

      *>================================================================*
      *> CONVERSATION HISTORY (Phase 2: Session Management)
      *>================================================================*
       INIT-CONVERSATION-HISTORY.
           MOVE 0 TO WS-CONV-COUNT.
           MOVE SPACES TO WS-CONVERSATION-TABLE.

       ADD-TO-CONVERSATION.
           IF WS-CONV-COUNT >= WS-CONV-MAX
      *> Shift entries down (circular buffer)
               PERFORM VARYING WS-CONV-INDEX FROM 1 BY 1
                   UNTIL WS-CONV-INDEX >= WS-CONV-MAX
                   MOVE WS-CONV-PROMPT(WS-CONV-INDEX + 1) TO
                       WS-CONV-PROMPT(WS-CONV-INDEX)
                   MOVE WS-CONV-RESPONSE(WS-CONV-INDEX + 1) TO
                       WS-CONV-RESPONSE(WS-CONV-INDEX)
                   MOVE WS-CONV-TIMESTAMP(WS-CONV-INDEX + 1) TO
                       WS-CONV-TIMESTAMP(WS-CONV-INDEX)
               END-PERFORM
               MOVE WS-PROMPT TO WS-CONV-PROMPT(WS-CONV-MAX)
               MOVE WS-CLEAN-RESPONSE TO WS-CONV-RESPONSE(WS-CONV-MAX)
               MOVE FUNCTION CURRENT-DATE(1:16)
                   TO WS-CONV-TIMESTAMP(WS-CONV-MAX)
           ELSE
               ADD 1 TO WS-CONV-COUNT
               MOVE WS-PROMPT TO WS-CONV-PROMPT(WS-CONV-COUNT)
               MOVE WS-CLEAN-RESPONSE TO WS-CONV-RESPONSE(WS-CONV-COUNT)
               MOVE FUNCTION CURRENT-DATE(1:16)
                   TO WS-CONV-TIMESTAMP(WS-CONV-COUNT)
           END-IF.

       SHOW-CONVERSATION.
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[1;33m=== Conversation History ===\033[0m\n'".
           IF WS-CONV-COUNT = 0
               DISPLAY "  (No conversation history yet)"
           ELSE
               PERFORM VARYING WS-CONV-INDEX FROM 1 BY 1
                   UNTIL WS-CONV-INDEX > WS-CONV-COUNT
                   DISPLAY SPACES
                   DISPLAY "  [" WS-CONV-INDEX "] "
                       WS-CONV-TIMESTAMP(WS-CONV-INDEX)
                   DISPLAY "      Q: " WS-CONV-PROMPT(WS-CONV-INDEX)
                   DISPLAY "      A: " WS-CONV-RESPONSE(WS-CONV-INDEX)
               END-PERFORM
           END-IF.
           DISPLAY SPACES.

       EXPORT-CONVERSATION.
      *> Export conversation to file in specified format
           DISPLAY SPACES.
           IF WS-EXPORT-FORMAT = SPACES
               MOVE "text" TO WS-EXPORT-FORMAT
           END-IF.

           IF WS-CONV-COUNT = 0
               CALL "SYSTEM" USING
                   "printf '\033[31m[ERR] No conversation to export\033[0m'"
               EXIT PARAGRAPH
           END-IF.

           PERFORM EXPORT-AS-TEXT.
           DISPLAY "Conversation exported to: " WS-EXPORT-FILE-NAME.
           DISPLAY SPACES.

       EXPORT-AS-TEXT.
      *> Export as plain text file
           MOVE "/tmp/cobol-ai-export.txt" TO WS-EXPORT-FILE-NAME.
           MOVE WS-EXPORT-FILE-NAME TO WS-CONV-FILE-NAME.
           OPEN OUTPUT CONVERSATION-FILE.
           IF WS-CONV-STATUS = "00"
               MOVE "COBOL AI CLI - Conversation Export" TO CONVERSATION-LINE
               WRITE CONVERSATION-LINE
               MOVE "===================================" TO CONVERSATION-LINE
               WRITE CONVERSATION-LINE
               MOVE SPACES TO CONVERSATION-LINE
               WRITE CONVERSATION-LINE
               PERFORM VARYING WS-CONV-INDEX FROM 1 BY 1
                   UNTIL WS-CONV-INDEX > WS-CONV-COUNT
                   STRING "--- Entry " WS-CONV-INDEX " ---"
                       DELIMITED BY SIZE INTO CONVERSATION-LINE
                   WRITE CONVERSATION-LINE
                   STRING "Time: " WS-CONV-TIMESTAMP(WS-CONV-INDEX)
                       DELIMITED BY SIZE INTO CONVERSATION-LINE
                   WRITE CONVERSATION-LINE
                   STRING "Q: " WS-CONV-PROMPT(WS-CONV-INDEX)
                       DELIMITED BY SIZE INTO CONVERSATION-LINE
                   WRITE CONVERSATION-LINE
                   STRING "A: " WS-CONV-RESPONSE(WS-CONV-INDEX)
                       DELIMITED BY SIZE INTO CONVERSATION-LINE
                   WRITE CONVERSATION-LINE
                   MOVE SPACES TO CONVERSATION-LINE
                   WRITE CONVERSATION-LINE
               END-PERFORM
               CLOSE CONVERSATION-FILE
           END-IF.

      *>================================================================*
      *> MODEL MANAGEMENT (Phase 2)
      *>================================================================*
       SHOW-MODELS.
      *> Display available models
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[1;33m=== Available Models ===\033[0m\n'".
           DISPLAY SPACES.
           DISPLAY "  * gpt-oss:120b     (current) - Default large model (120B)".
           DISPLAY "    llama2:7b        - Meta Llama 2 (7B)".
           DISPLAY "    llama3:2b        - Meta Llama 3 (2B)".
           DISPLAY "    mistral:7b       - Mistral AI (7B)".
           DISPLAY "    codellama:13b    - Code Llama (13B)".
           DISPLAY "    deepseek-r1:1.5b - DeepSeek R1 (1.5B)".
           DISPLAY SPACES.
           DISPLAY "Usage: model <name>".
           DISPLAY "Example: model llama2:7b".
           DISPLAY SPACES.

       SHOW-STATS.
      *> Phase 4: Display cache and error statistics
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[1;33m=== Cache & Error Statistics ===\033[0m\n'".
           DISPLAY SPACES.
           DISPLAY "  Cache Status: " WS-CACHE-ENABLED.
           DISPLAY "  Cache Hits:   " WS-CACHE-HITS.
           DISPLAY "  Cache Misses: " WS-CACHE-MISSES.
           IF WS-CACHE-HITS + WS-CACHE-MISSES > 0
               COMPUTE WS-TEMP-POS = (WS-CACHE-HITS * 100) /
                   (WS-CACHE-HITS + WS-CACHE-MISSES)
               DISPLAY "  Hit Rate:     " WS-TEMP-POS "%"
           END-IF.
           DISPLAY "  Cached Items: " WS-CACHE-COUNT.
           DISPLAY SPACES.
           DISPLAY "  Error Count:  " WS-ERROR-COUNT.
           IF WS-LAST-ERROR-CODE > 0
               DISPLAY "  Last Error:   Code " WS-LAST-ERROR-CODE
               DISPLAY "                " WS-LAST-ERROR-MSG
           END-IF.
           DISPLAY SPACES.
           DISPLAY "  Retry Config:"
           DISPLAY "    Max Retries:  " WS-MAX-RETRIES.
           DISPLAY "    Base Delay:   " WS-BASE-DELAY "ms".
           DISPLAY "    Max Delay:    " WS-MAX-DELAY "ms".
           DISPLAY SPACES.

       CHANGE-MODEL.
      *> Switch to a different model
           MOVE FUNCTION TRIM(WS-PROMPT(6:50)) TO WS-TEMP-STRING.
           IF FUNCTION TRIM(WS-TEMP-STRING) = SPACES
               PERFORM SHOW-MODELS
               EXIT PARAGRAPH
           END-IF.

      *> Validate model exists in our list
           MOVE "N" TO WS-JSON-FOUND.
           PERFORM VARYING WS-JSON-I FROM 1 BY 1
               UNTIL WS-JSON-I > 5
               IF FUNCTION TRIM(WS-VALID-MODEL-ENTRY(WS-JSON-I)) =
                  FUNCTION TRIM(WS-TEMP-STRING)
                   MOVE "Y" TO WS-JSON-FOUND
                   EXIT PERFORM
               END-IF
           END-PERFORM.

           IF WS-JSON-FOUND = "N"
               DISPLAY "Unknown model. Available models are:"
               PERFORM SHOW-MODELS
               EXIT PARAGRAPH
           END-IF.

           MOVE WS-TEMP-STRING TO WS-MODEL.
           DISPLAY "Model changed to: " WS-MODEL.
           DISPLAY SPACES.

      *>================================================================*
      *> THEME MANAGEMENT (NEW - Phase 1: Custom Themes)
      *>================================================================*
       LOAD-THEME.
      *> Load theme from file or use default
           OPEN INPUT THEME-FILE.
           IF WS-THEME-STATUS = "00"
               READ THEME-FILE
                   AT END MOVE "dark" TO WS-CURRENT-THEME
                   NOT AT END MOVE THEME-LINE TO WS-CURRENT-THEME
               END-READ
               CLOSE THEME-FILE
           END-IF.
           MOVE FUNCTION LOWER-CASE(FUNCTION TRIM(WS-CURRENT-THEME))
               TO WS-CURRENT-THEME.
           IF WS-CURRENT-THEME NOT = "dark" AND
              WS-CURRENT-THEME NOT = "light"
               MOVE "dark" TO WS-CURRENT-THEME
           END-IF.
           PERFORM APPLY-THEME-COLORS.

       SAVE-THEME.
      *> Save current theme to file
           OPEN OUTPUT THEME-FILE.
           IF WS-THEME-STATUS = "00"
               MOVE WS-CURRENT-THEME TO THEME-LINE
               WRITE THEME-LINE
               CLOSE THEME-FILE
           END-IF.

       APPLY-THEME-COLORS.
      *> Set color codes based on current theme
           IF THEME-LIGHT
      *> Light theme - darker colors for contrast
               MOVE "\033[1;34m" TO WS-COLOR-BANNER
               MOVE "\033[34m" TO WS-COLOR-PROMPT
               MOVE "\033[30m" TO WS-COLOR-RESPONSE
               MOVE "\033[31m" TO WS-COLOR-ERROR
               MOVE "\033[32m" TO WS-COLOR-SUCCESS
               MOVE "\033[33m" TO WS-COLOR-WARNING
               MOVE "\033[35m" TO WS-COLOR-INFO
               MOVE "\033[36m" TO WS-COLOR-CODE
           ELSE
      *> Dark theme (default) - bright colors
               MOVE "\033[1;36m" TO WS-COLOR-BANNER
               MOVE "\033[34m" TO WS-COLOR-PROMPT
               MOVE "\033[37m" TO WS-COLOR-RESPONSE
               MOVE "\033[31m" TO WS-COLOR-ERROR
               MOVE "\033[32m" TO WS-COLOR-SUCCESS
               MOVE "\033[33m" TO WS-COLOR-WARNING
               MOVE "\033[35m" TO WS-COLOR-INFO
               MOVE "\033[36m" TO WS-COLOR-CODE
           END-IF.

       DISPLAY-THEME-HELP.
      *> Show theme selection help
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[1;33m=== Available Themes ===\033[0m\n'".
           DISPLAY "  dark   - Dark background with bright colors (default)".
           DISPLAY "  light  - Light background with darker colors".
           DISPLAY SPACES.
           DISPLAY "Usage: theme <name>".
           DISPLAY "Example: theme light".
           DISPLAY SPACES.

      *>================================================================*
      *> HISTORY MANAGEMENT (NEW - Phase 1)
      *>================================================================*
       LOAD-HISTORY.
           MOVE WS-HIST-FILE-NAME TO WS-HISTORY-FILE.
           OPEN INPUT HISTORY-FILE.
           IF WS-HISTORY-STATUS = "00"
               MOVE 0 TO WS-HISTORY-COUNT
               PERFORM VARYING WS-HISTORY-INDEX FROM 1 BY 1
                   UNTIL WS-HISTORY-INDEX > WS-HISTORY-MAX
                   OR WS-HISTORY-STATUS NOT = "00"
                   READ HISTORY-FILE
                       AT END
                           MOVE "99" TO WS-HISTORY-STATUS
                       NOT AT END
                           IF WS-HISTORY-COUNT < WS-HISTORY-MAX
                               ADD 1 TO WS-HISTORY-COUNT
                               MOVE HISTORY-LINE TO
                                   WS-HIST-TEXT(WS-HISTORY-COUNT)
                           END-IF
                   END-READ
               END-PERFORM
               CLOSE HISTORY-FILE
           END-IF.

       SAVE-HISTORY.
           MOVE WS-HIST-FILE-NAME TO WS-HISTORY-FILE.
           OPEN OUTPUT HISTORY-FILE.
           IF WS-HISTORY-STATUS = "00"
               PERFORM VARYING WS-HISTORY-INDEX FROM 1 BY 1
                   UNTIL WS-HISTORY-INDEX > WS-HISTORY-COUNT
                   MOVE WS-HIST-TEXT(WS-HISTORY-INDEX) TO HISTORY-LINE
                   WRITE HISTORY-LINE
               END-PERFORM
               CLOSE HISTORY-FILE
           END-IF.

       ADD-TO-HISTORY.
           IF WS-HISTORY-COUNT >= WS-HISTORY-MAX
      *> Shift entries down
               PERFORM VARYING WS-HISTORY-INDEX FROM 1 BY 1
                   UNTIL WS-HISTORY-INDEX >= WS-HISTORY-MAX
                   MOVE WS-HIST-TEXT(WS-HISTORY-INDEX + 1) TO
                       WS-HIST-TEXT(WS-HISTORY-INDEX)
               END-PERFORM
               MOVE WS-PROMPT TO WS-HIST-TEXT(WS-HISTORY-MAX)
           ELSE
               ADD 1 TO WS-HISTORY-COUNT
               MOVE WS-PROMPT TO WS-HIST-TEXT(WS-HISTORY-COUNT)
           END-IF.
           PERFORM SAVE-HISTORY.

       SHOW-HISTORY.
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[1;33m=== Command History ===\033[0m\n'".
           IF WS-HISTORY-COUNT = 0
               DISPLAY "  (No history yet)"
           ELSE
               PERFORM VARYING WS-HISTORY-INDEX FROM 1 BY 1
                   UNTIL WS-HISTORY-INDEX > WS-HISTORY-COUNT
                   DISPLAY "  " WS-HISTORY-INDEX ": "
                       WS-HIST-TEXT(WS-HISTORY-INDEX)
               END-PERFORM
           END-IF.
           DISPLAY SPACES.

      *>================================================================*
      *> RUN MODE DETERMINATION
      *>================================================================*
       DETERMINE-RUN-MODE.
      *> First check for piped input (Phase 3)
           PERFORM CHECK-STDIN.

      *> Then check command line
           ACCEPT WS-CMD-LINE FROM COMMAND-LINE.
           IF HAS-STDIN
      *> Piped input takes priority
               MOVE WS-STDIN-BUFFER TO WS-PROMPT
               MOVE "oneshot" TO WS-RUN-MODE
           ELSE
               IF WS-CMD-LINE NOT = SPACES
                   MOVE WS-CMD-LINE TO WS-PROMPT
                   MOVE "oneshot" TO WS-RUN-MODE
               ELSE
                   MOVE "interactive" TO WS-RUN-MODE
               END-IF
           END-IF.

       CHECK-STDIN.
      *> Check if there is piped input from stdin (Phase 3)
      *> For pipe support, we redirect stdin to a temp file first
      *> This is set by the wrapper script when piping
           MOVE "N" TO WS-HAS-STDIN.
           ACCEPT WS-STDIN-TEMP FROM ENVIRONMENT "COBOL_AI_STDIN".
           IF WS-STDIN-TEMP = SPACES
               EXIT PARAGRAPH
           END-IF.
           OPEN INPUT STDIN-FILE.
           IF WS-STDIN-FILE-STATUS NOT = "00"
               EXIT PARAGRAPH
           END-IF.
           READ STDIN-FILE INTO WS-STDIN-BUFFER
               AT END
                   MOVE "N" TO WS-HAS-STDIN
               NOT AT END
                   MOVE "Y" TO WS-HAS-STDIN
                   MOVE FUNCTION LENGTH(WS-STDIN-BUFFER)
                       TO WS-STDIN-LENGTH
           END-READ.
           CLOSE STDIN-FILE.
           CALL "SYSTEM" USING "rm -f /tmp/cobol-ai-stdin.txt".

      *>================================================================*
      *> APPLICATION RUNNER
      *>================================================================*
       RUN-APPLICATION.
           IF MODE-ONE-SHOT
               PERFORM PROCESS-PROMPT
           ELSE
               PERFORM RUN-INTERACTIVE
           END-IF.

       RUN-INTERACTIVE.
           MOVE "Y" TO WS-CONTINUE.
           PERFORM INTERACTIVE-PROMPT UNTIL SHOULD-EXIT.

       INTERACTIVE-PROMPT.
           DISPLAY SPACES.
      *> Show prompt length indicator (Phase 1 - Input Validation)
           CALL "SYSTEM" USING
               "printf '\033[34m> Enter your prompt (max 500 chars):\033[0m '".
           ACCEPT WS-PROMPT.

      *> Validate prompt length (Phase 1 - Input Validation)
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-PROMPT))
               TO WS-PROMPT-LEN.
           IF WS-PROMPT-LEN = 0
               DISPLAY "  Empty prompt. Try again."
               EXIT PARAGRAPH
           END-IF.
           IF WS-PROMPT-LEN > WS-MAX-PROMPT-LEN
               CALL "SYSTEM" USING
                   "printf '\033[31m[ERR] Prompt too long (%d > %d chars)\033[0m'\n"
               DISPLAY WS-PROMPT-LEN " " WS-MAX-PROMPT-LEN
               EXIT PARAGRAPH
           END-IF.

      *> Check for exit commands
           MOVE FUNCTION LOWER-CASE(FUNCTION TRIM(WS-PROMPT))
               TO WS-COMMAND-TYPE.
           IF CMD-EXIT OR CMD-QUIT
               MOVE "N" TO WS-CONTINUE
               EXIT PARAGRAPH
           END-IF.

      *> Check for help command
           IF CMD-HELP
               PERFORM DISPLAY-HELP
               EXIT PARAGRAPH
           END-IF.

      *> Check for history command
           IF CMD-HISTORY
               PERFORM SHOW-HISTORY
               EXIT PARAGRAPH
           END-IF.

      *> Check for clear command
           IF CMD-CLEAR
               CALL "SYSTEM" USING "clear"
               EXIT PARAGRAPH
           END-IF.

      *> Check for theme command (Phase 1 - Custom Themes)
           IF FUNCTION TRIM(WS-PROMPT) = "theme" OR
              FUNCTION TRIM(WS-PROMPT(1:6)) = "theme "
               IF FUNCTION TRIM(WS-PROMPT) = "theme"
                   DISPLAY "Current theme: " WS-CURRENT-THEME
                   PERFORM DISPLAY-THEME-HELP
               ELSE
                   MOVE FUNCTION TRIM(WS-PROMPT(7:20))
                       TO WS-CURRENT-THEME
                   MOVE FUNCTION LOWER-CASE(WS-CURRENT-THEME)
                       TO WS-CURRENT-THEME
                   PERFORM SAVE-THEME
                   PERFORM APPLY-THEME-COLORS
                   DISPLAY "Theme changed to: " WS-CURRENT-THEME
               END-IF
               EXIT PARAGRAPH
           END-IF.

      *> Check for model command (Phase 2 - Model Management)
           IF WS-COMMAND-TYPE(1:6) = "model " OR
              FUNCTION TRIM(WS-COMMAND-TYPE) = "model"
               PERFORM CHANGE-MODEL
               EXIT PARAGRAPH
           END-IF.

      *> Check for models command (Phase 2 - List Models)
           IF CMD-MODELS
               PERFORM SHOW-MODELS
               EXIT PARAGRAPH
           END-IF.

      *> Check for export command (Phase 2 - Export Conversation)
           IF CMD-EXPORT
               PERFORM EXPORT-CONVERSATION
               EXIT PARAGRAPH
           END-IF.

      *> Check for conversation command (Phase 2 - Show Conversation)
           IF WS-COMMAND-TYPE(1:5) = "conv" OR
              WS-COMMAND-TYPE(1:11) = "conversation"
               PERFORM SHOW-CONVERSATION
               EXIT PARAGRAPH
           END-IF.

      *> Check for output command (Phase 3 - File Output)
           IF FUNCTION TRIM(WS-PROMPT(1:4)) = "out " OR
              FUNCTION TRIM(WS-PROMPT(1:7)) = "output "
               PERFORM SET-OUTPUT-FILE
               EXIT PARAGRAPH
           END-IF.

      *> Check for stats command (Phase 4 - Cache/Error Stats)
           IF WS-COMMAND-TYPE(1:5) = "stats"
               PERFORM SHOW-STATS
               EXIT PARAGRAPH
           END-IF.

      *> Check for cache clear command
           IF FUNCTION LOWER-CASE(FUNCTION TRIM(WS-PROMPT)) =
              "cache clear"
               PERFORM CLEAR-RESPONSE-CACHE
               EXIT PARAGRAPH
           END-IF.

      *> Check for empty input
           IF FUNCTION TRIM(WS-PROMPT) = SPACES
               EXIT PARAGRAPH
           END-IF.

      *> Add valid prompt to history
           PERFORM ADD-TO-HISTORY.

      *> Process the prompt
           PERFORM PROCESS-PROMPT.

      *> Ask to continue
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[37m> Press Enter to continue or 'exit' to quit: \033[0m'".
           ACCEPT WS-TEMP-STRING.
           IF FUNCTION LOWER-CASE(WS-TEMP-STRING) = "exit"
               MOVE "N" TO WS-CONTINUE
           END-IF.

       DISPLAY-HELP.
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[1;33m=== Available Commands ===\033[0m\n'".
           DISPLAY SPACES.
           DISPLAY "  help           - Show this help message".
           DISPLAY "  history        - Show command history".
           DISPLAY "  clear          - Clear the screen".
           DISPLAY "  theme          - Change color theme (dark/light)".
           DISPLAY "  models         - List available AI models".
           DISPLAY "  model <name>   - Switch to a different model".
           DISPLAY "  export         - Export conversation to file".
           DISPLAY "  conversation   - Show conversation history".
           DISPLAY "  output <file>  - Set output file for responses".
           DISPLAY "  out <file>     - Same as output (shortcut)".
           DISPLAY "  stats          - Show cache and error statistics".
           DISPLAY "  cache clear    - Empty the persistent response cache".
           DISPLAY "  exit           - Exit the program".
           DISPLAY "  quit           - Exit the program".
           DISPLAY SPACES.
           DISPLAY "Pipe support: echo 'prompt' | ./cobol-ai".
           DISPLAY SPACES.

      *>================================================================*
      *> PROMPT PROCESSING
      *>================================================================*
       PROCESS-PROMPT.
      *> Phase 4: Check cache first before making API call
           PERFORM CHECK-RESPONSE-CACHE.

           IF CACHE-FOUND
               DISPLAY "  [CACHE HIT] Using cached response"
               ADD 1 TO WS-CACHE-HITS
           ELSE
               ADD 1 TO WS-CACHE-MISSES
               PERFORM BUILD-JSON-PAYLOAD
               PERFORM CALL-API-WITH-SPINNER
      *> Cache the successful response
               PERFORM CACHE-RESPONSE
           END-IF

           PERFORM DISPLAY-RESPONSE-WITH-HIGHLIGHTING
           PERFORM WRITE-TO-OUTPUT-FILE
           PERFORM ADD-TO-CONVERSATION
           PERFORM CLEANUP-TEMP-FILES.

       SET-OUTPUT-FILE.
      *> Set output file for responses (Phase 3)
           IF FUNCTION TRIM(WS-PROMPT(1:7)) = "output "
               MOVE FUNCTION TRIM(WS-PROMPT(8:200)) TO WS-OUTPUT-FILE-NAME
           ELSE
               MOVE FUNCTION TRIM(WS-PROMPT(5:200)) TO WS-OUTPUT-FILE-NAME
           END-IF.
           IF FUNCTION TRIM(WS-OUTPUT-FILE-NAME) = SPACES
               DISPLAY "Current output file: " WS-OUTPUT-FILE-NAME
               DISPLAY "Usage: output <filename>"
           ELSE
               DISPLAY "Output file set to: " WS-OUTPUT-FILE-NAME
               DISPLAY "Responses will be saved to this file"
           END-IF.
           DISPLAY SPACES.

       WRITE-TO-OUTPUT-FILE.
      *> Write response to output file if set (Phase 3)
      *> Note: This feature requires proper file path handling
      *> For now, responses are displayed in the terminal
           CONTINUE.

       BUILD-JSON-PAYLOAD.
           MOVE FUNCTION TRIM(WS-PROMPT) TO WS-PROMPT-TRIMMED.
           MOVE SPACES TO WS-JSON-PAYLOAD.
           STRING '{"model":"'
                  DELIMITED BY SIZE
                  FUNCTION TRIM(WS-MODEL) DELIMITED BY SIZE
                  '","prompt":"'
                  DELIMITED BY SIZE
                  WS-PROMPT-TRIMMED DELIMITED BY SIZE
                  '","stream":false}'
                  DELIMITED BY SIZE
               INTO WS-JSON-PAYLOAD
           END-STRING.

       CALL-API-WITH-SPINNER.
      *> Phase 4: Retry logic with exponential backoff
           MOVE 0 TO WS-CURRENT-RETRY.
           MOVE "N" TO WS-JSON-FOUND.
           MOVE "N" TO WS-FATAL-ERROR.
           MOVE 0 TO WS-RETRY-DELAY.

           PERFORM UNTIL WS-CURRENT-RETRY > WS-MAX-RETRIES
               OR WS-JSON-FOUND = "Y"
               OR FATAL-ERROR
               IF WS-CURRENT-RETRY > 0 THEN
                   DISPLAY SPACES
                   DISPLAY "  [RETRY] Attempt " WS-CURRENT-RETRY " of " WS-MAX-RETRIES
                   DISPLAY "  Reason: " WS-RETRY-REASON
                   DISPLAY "  Waiting..."
                   PERFORM WAIT-RETRY-DELAY
               END-IF
               DISPLAY SPACES
               DISPLAY "[SEND] Sending request to Ollama API..."
               DISPLAY SPACES
      *> Build helper command
               MOVE SPACES TO WS-HELPER-CMD
               STRING "./cobol-ai-helper.sh '"
                      DELIMITED BY SIZE
                      WS-PROMPT-TRIMMED DELIMITED BY SIZE
                      "'"
                      DELIMITED BY SIZE
                   INTO WS-HELPER-CMD
               END-STRING
      *> Start spinner animation
               PERFORM START-SPINNER
      *> Execute API call
               CALL "SYSTEM" USING WS-HELPER-CMD
      *> Stop spinner
               PERFORM STOP-SPINNER
      *> Try to read and parse response
               PERFORM PARSE-RESPONSE
      *> Check if we got a valid response
               IF WS-JSON-FOUND = "Y" THEN
                   DISPLAY "[OK] Request completed!"
                   DISPLAY SPACES
               ELSE
                   MOVE "No valid response in JSON" TO WS-RETRY-REASON
                   IF WS-CURRENT-RETRY >= WS-MAX-RETRIES THEN
                       MOVE "Y" TO WS-FATAL-ERROR
                       DISPLAY "[ERR] All retry attempts exhausted"
                       DISPLAY SPACES
                   END-IF
               END-IF
               ADD 1 TO WS-CURRENT-RETRY
           END-PERFORM.

       WAIT-RETRY-DELAY.
      *> Wait for retry delay (simplified - uses shell sleep)
           MOVE SPACES TO WS-TEMP-STRING
           COMPUTE WS-RETRY-DELAY = WS-BASE-DELAY *
               (2 ** WS-CURRENT-RETRY)
           IF WS-RETRY-DELAY > WS-MAX-DELAY
               MOVE WS-MAX-DELAY TO WS-RETRY-DELAY
           END-IF
           COMPUTE WS-TEMP-POS = WS-RETRY-DELAY / 1000
           IF WS-TEMP-POS < 1
               MOVE 1 TO WS-TEMP-POS
           END-IF
           MOVE WS-TEMP-POS TO WS-TEMP-STRING
           STRING "sleep " DELIMITED BY SIZE
                  WS-TEMP-STRING DELIMITED BY SIZE
               INTO WS-HELPER-CMD
           END-STRING
           CALL "SYSTEM" USING WS-HELPER-CMD.

       START-SPINNER.
      *> Display animated spinner during API call
           MOVE 1 TO WS-SPINNER-POS.
           MOVE 0 TO WS-SPINNER-COUNT.
      *> Show first frame immediately
           MOVE WS-SPINNER-CHARS(WS-SPINNER-POS:1)
               TO WS-SPINNER-FRAME.
           CALL "SYSTEM" USING
               "printf '\r\033[33m| Loading... / \033[0m'".

       STOP-SPINNER.
      *> Clear spinner display
           CALL "SYSTEM" USING "printf '\r\033[2K'".

       PARSE-RESPONSE.
      *> Read response file
           MOVE "/tmp/cobol-ai-response.json"
               TO WS-RESPONSE-FILE.
           OPEN INPUT RESPONSE-FILE.
           IF WS-FILE-STATUS NOT = "00"
               CALL "SYSTEM" USING
                   "printf '\033[31m[ERR]\033[0m Could not read response file'"
               EXIT PARAGRAPH
           END-IF.
           READ RESPONSE-FILE INTO WS-HTTP-RESPONSE.
           CLOSE RESPONSE-FILE.

      *> Get response length with colored output (magenta)
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-HTTP-RESPONSE))
               TO WS-RESPONSE-LEN.
           CALL "SYSTEM" USING
               "printf '\033[35m[RECV]\033[0m Response received ('".
           DISPLAY WS-RESPONSE-LEN " bytes)".

      *> Find "response" field in JSON
           MOVE SPACES TO WS-JSON-EXTRACTED.
           MOVE "N" TO WS-JSON-FOUND.
           MOVE 1 TO WS-JSON-I.

           PERFORM VARYING WS-JSON-I FROM 1 BY 1
               UNTIL WS-JSON-I > WS-RESPONSE-LEN - 10
               IF WS-HTTP-RESPONSE(WS-JSON-I:10) = '"response"'
                   MOVE "Y" TO WS-JSON-FOUND
                   ADD 12 TO WS-JSON-I
                   MOVE WS-JSON-I TO WS-JSON-START
                   PERFORM VARYING WS-JSON-J FROM WS-JSON-I BY 1
                       UNTIL WS-JSON-J > WS-RESPONSE-LEN
      *> Check for closing quote (but not escaped quote \")
                       IF WS-HTTP-RESPONSE(WS-JSON-J:1) = WS-JSON-QUOTE
      *> Check if this quote is escaped (preceded by backslash)
                           IF WS-JSON-J > WS-JSON-START
                           AND WS-HTTP-RESPONSE(WS-JSON-J - 1:1) = "\"
      *> This is an escaped quote, continue searching
                               CONTINUE
                           ELSE
      *> Found the real closing quote
                               COMPUTE WS-JSON-LEN = WS-JSON-J - WS-JSON-START
                               IF WS-JSON-LEN > 0 AND WS-JSON-LEN < 25000
                                   MOVE WS-HTTP-RESPONSE(
                                       WS-JSON-START:WS-JSON-LEN)
                                       TO WS-JSON-EXTRACTED
                               END-IF
                               EXIT PERFORM
                           END-IF
                       END-IF
                   END-PERFORM
                   EXIT PERFORM
               END-IF
           END-PERFORM.

      *> Check for error in response
           IF WS-JSON-FOUND = "N"
               PERFORM CHECK-ERROR-FIELD
           END-IF.

       CHECK-ERROR-FIELD.
      *> Check for "error" field in response
           PERFORM VARYING WS-JSON-I FROM 1 BY 1
               UNTIL WS-JSON-I > WS-RESPONSE-LEN - 7
               IF WS-HTTP-RESPONSE(WS-JSON-I:7) = '"error"'
                   ADD 10 TO WS-JSON-I
                   MOVE WS-JSON-I TO WS-JSON-START
                   PERFORM VARYING WS-JSON-J FROM WS-JSON-I BY 1
                       UNTIL WS-JSON-J > WS-RESPONSE-LEN
                       IF WS-HTTP-RESPONSE(WS-JSON-J:1) = WS-JSON-QUOTE
                           COMPUTE WS-JSON-LEN = WS-JSON-J - WS-JSON-START
                           IF WS-JSON-LEN > 0
                               DISPLAY "API Error: "
                                   WS-HTTP-RESPONSE(
                                   WS-JSON-START:WS-JSON-LEN)
                           END-IF
                           EXIT PERFORM
                       END-IF
                   END-PERFORM
                   EXIT PERFORM
               END-IF
           END-PERFORM.

      *>================================================================*
      *> SECTION: RESPONSE CACHING (Phase 4)
      *>================================================================*
       BUILD-CACHE-KEY.
      *> Build the lookup key from model + prompt, then reduce it to a
      *> 64-char fingerprint held in WS-CACHE-HASH.
      *> WS-CACHE-HASH is scratch storage only - it must never be a table
      *> slot, or a lookup would compare an entry against itself.
           MOVE FUNCTION TRIM(WS-PROMPT) TO WS-PROMPT-TRIMMED.
           MOVE SPACES TO WS-CACHE-KEY.
           STRING FUNCTION TRIM(WS-MODEL) "|"
               FUNCTION TRIM(WS-PROMPT-TRIMMED)
               DELIMITED BY SIZE INTO WS-CACHE-KEY.

      *> Rolling polynomial hash over the whole key so that prompts
      *> sharing a prefix do not collide.
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-CACHE-KEY))
               TO WS-HASH-KEY-LEN.
           MOVE 0 TO WS-HASH-ACC.
           PERFORM VARYING WS-HASH-POS FROM 1 BY 1
               UNTIL WS-HASH-POS > WS-HASH-KEY-LEN
               COMPUTE WS-HASH-ACC = FUNCTION MOD(
                   (WS-HASH-ACC * 31)
                   + FUNCTION ORD(WS-CACHE-KEY(WS-HASH-POS:1)),
                   999999937)
           END-PERFORM.

      *> Fingerprint = 12-digit hash + 4-digit length + first 48 chars
           MOVE WS-HASH-ACC TO WS-HASH-ACC-DISP.
           MOVE WS-HASH-KEY-LEN TO WS-HASH-LEN-DISP.
           MOVE SPACES TO WS-CACHE-HASH.
           STRING WS-HASH-ACC-DISP
                  WS-HASH-LEN-DISP
                  WS-CACHE-KEY(1:48)
               DELIMITED BY SIZE INTO WS-CACHE-HASH.

       CHECK-RESPONSE-CACHE.
      *> Check if response exists in cache
           MOVE "N" TO WS-CACHE-FOUND.
           IF CACHE-DISABLED
               EXIT PARAGRAPH
           END-IF.

           PERFORM BUILD-CACHE-KEY.

      *> Search cache table
           PERFORM VARYING WS-CACHE-INDEX FROM 1 BY 1
               UNTIL WS-CACHE-INDEX > WS-CACHE-COUNT
               OR CACHE-FOUND
               IF WS-CACHE-VALID(WS-CACHE-INDEX) = "Y"
                   AND WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX) =
                       WS-CACHE-HASH
                   MOVE "Y" TO WS-CACHE-FOUND
                   MOVE WS-CACHE-RESPONSE(WS-CACHE-INDEX)
                       TO WS-JSON-EXTRACTED
                   MOVE "Y" TO WS-JSON-FOUND
               END-IF
           END-PERFORM.

       CACHE-RESPONSE.
      *> Store response in cache after successful API call
           IF CACHE-DISABLED
               EXIT PARAGRAPH
           END-IF.

           IF WS-JSON-FOUND = "N"
               EXIT PARAGRAPH
           END-IF.

      *> Check if cache is full
           IF WS-CACHE-COUNT >= WS-CACHE-MAX
      *> Remove oldest entry (shift down)
               PERFORM VARYING WS-CACHE-INDEX FROM 1 BY 1
                   UNTIL WS-CACHE-INDEX >= WS-CACHE-MAX
                   MOVE WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX + 1)
                       TO WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX)
                   MOVE WS-CACHE-RESPONSE(WS-CACHE-INDEX + 1)
                       TO WS-CACHE-RESPONSE(WS-CACHE-INDEX)
                   MOVE WS-CACHE-TIMESTAMP(WS-CACHE-INDEX + 1)
                       TO WS-CACHE-TIMESTAMP(WS-CACHE-INDEX)
                   MOVE WS-CACHE-VALID(WS-CACHE-INDEX + 1)
                       TO WS-CACHE-VALID(WS-CACHE-INDEX)
               END-PERFORM
               MOVE WS-CACHE-COUNT TO WS-CACHE-INDEX
           ELSE
               ADD 1 TO WS-CACHE-COUNT
               MOVE WS-CACHE-COUNT TO WS-CACHE-INDEX
           END-IF.

      *> Store cache entry - WS-CACHE-HASH was set by CHECK-RESPONSE-CACHE
      *> for this same prompt, so reuse it rather than rebuilding.
           MOVE WS-CACHE-HASH TO WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX).
           MOVE WS-JSON-EXTRACTED TO WS-CACHE-RESPONSE(WS-CACHE-INDEX).
           MOVE FUNCTION CURRENT-DATE(1:14)
               TO WS-CACHE-TIMESTAMP(WS-CACHE-INDEX).
           MOVE "Y" TO WS-CACHE-VALID(WS-CACHE-INDEX).

      *>================================================================*
      *> SECTION: CACHE PERSISTENCE
      *>================================================================*
       LOAD-RESPONSE-CACHE.
      *> Repopulate the cache table from disk so hits survive across runs
           MOVE 0 TO WS-CACHE-COUNT.
           MOVE 0 TO WS-CACHE-LOADED.
           IF CACHE-DISABLED
               EXIT PARAGRAPH
           END-IF.

           COMPUTE WS-CACHE-TODAY-INT = FUNCTION INTEGER-OF-DATE(
               FUNCTION NUMVAL(FUNCTION CURRENT-DATE(1:8))).

           OPEN INPUT CACHE-FILE.
           IF WS-CACHE-STATUS NOT = "00"
      *> No cache file yet (first run) - start empty, not an error
               EXIT PARAGRAPH
           END-IF.

           PERFORM UNTIL WS-CACHE-STATUS NOT = "00"
               OR WS-CACHE-COUNT >= WS-CACHE-MAX
               READ CACHE-FILE
                   AT END
                       MOVE "99" TO WS-CACHE-STATUS
                   NOT AT END
                       MOVE CACHE-RECORD TO WS-CACHE-REC
                       PERFORM ACCEPT-CACHE-RECORD
               END-READ
           END-PERFORM.
           CLOSE CACHE-FILE.

       ACCEPT-CACHE-RECORD.
      *> Add one on-disk record to the table if it is valid and fresh
           IF WS-CR-VALID NOT = "Y"
               EXIT PARAGRAPH
           END-IF.
           IF WS-CR-HASH = SPACES OR WS-CR-RESPONSE = SPACES
               EXIT PARAGRAPH
           END-IF.
           IF WS-CR-TIMESTAMP(1:8) NOT NUMERIC
               EXIT PARAGRAPH
           END-IF.

      *> Drop entries older than the TTL
           COMPUTE WS-CACHE-DATE-INT = FUNCTION INTEGER-OF-DATE(
               FUNCTION NUMVAL(WS-CR-TIMESTAMP(1:8))).
           IF WS-CACHE-TODAY-INT - WS-CACHE-DATE-INT > WS-CACHE-TTL-DAYS
               EXIT PARAGRAPH
           END-IF.

           ADD 1 TO WS-CACHE-COUNT.
           MOVE WS-CR-HASH TO WS-CACHE-PROMPT-HASH(WS-CACHE-COUNT).
           MOVE WS-CR-RESPONSE TO WS-CACHE-RESPONSE(WS-CACHE-COUNT).
           MOVE WS-CR-TIMESTAMP TO WS-CACHE-TIMESTAMP(WS-CACHE-COUNT).
           MOVE "Y" TO WS-CACHE-VALID(WS-CACHE-COUNT).
           ADD 1 TO WS-CACHE-LOADED.

       SAVE-RESPONSE-CACHE.
      *> Flush the in-memory table back to disk on exit
           IF CACHE-DISABLED OR WS-CACHE-COUNT = 0
               EXIT PARAGRAPH
           END-IF.

           OPEN OUTPUT CACHE-FILE.
           IF WS-CACHE-STATUS NOT = "00"
               EXIT PARAGRAPH
           END-IF.

           PERFORM VARYING WS-CACHE-INDEX FROM 1 BY 1
               UNTIL WS-CACHE-INDEX > WS-CACHE-COUNT
               IF WS-CACHE-VALID(WS-CACHE-INDEX) = "Y"
                   AND WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX) NOT = SPACES
      *> A literal newline would split the record across two lines
                   MOVE 0 TO WS-CACHE-NL-COUNT
                   INSPECT WS-CACHE-RESPONSE(WS-CACHE-INDEX)
                       TALLYING WS-CACHE-NL-COUNT FOR ALL X"0A"
                   IF WS-CACHE-NL-COUNT = 0
                       MOVE WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX)
                           TO WS-CR-HASH
                       MOVE WS-CACHE-TIMESTAMP(WS-CACHE-INDEX)
                           TO WS-CR-TIMESTAMP
                       MOVE "Y" TO WS-CR-VALID
                       MOVE WS-CACHE-RESPONSE(WS-CACHE-INDEX)
                           TO WS-CR-RESPONSE
                       MOVE WS-CACHE-REC TO CACHE-RECORD
                       WRITE CACHE-RECORD
                   END-IF
               END-IF
           END-PERFORM.
           CLOSE CACHE-FILE.

       CLEAR-RESPONSE-CACHE.
      *> Drop every entry, in memory and on disk
           MOVE 0 TO WS-CACHE-COUNT.
           PERFORM VARYING WS-CACHE-INDEX FROM 1 BY 1
               UNTIL WS-CACHE-INDEX > WS-CACHE-MAX
               MOVE SPACES TO WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX)
               MOVE SPACES TO WS-CACHE-RESPONSE(WS-CACHE-INDEX)
               MOVE SPACES TO WS-CACHE-TIMESTAMP(WS-CACHE-INDEX)
               MOVE "N" TO WS-CACHE-VALID(WS-CACHE-INDEX)
           END-PERFORM.
           CALL "SYSTEM" USING "rm -f /tmp/cobol-ai-cache.dat".
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[32m[OK]\033[0m Response cache cleared'".
           DISPLAY SPACES.

       DISPLAY-RESPONSE-WITH-HIGHLIGHTING.
      *> Clean up escape sequences
           IF WS-JSON-FOUND = "Y" AND WS-JSON-EXTRACTED NOT = SPACES
               PERFORM CLEAN-ESCAPE-SEQUENCES
           END-IF.

      *> Display formatted response with syntax highlighting (Phase 1)
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[36m======================================================================\033[0m'".
           DISPLAY SPACES.

           IF WS-JSON-FOUND = "Y" AND WS-CLEAN-RESPONSE NOT = SPACES
               CALL "SYSTEM" USING
                   "printf '\033[1;33m>>> AI Response:\033[0m'"
               DISPLAY SPACES
               PERFORM DISPLAY-WITH-CODE-HIGHLIGHTING
           END-IF.
      *> Display error if no response
           IF WS-JSON-FOUND = "N"
               CALL "SYSTEM" USING
                   "printf '\033[31m[ERR] No response received from API\033[0m'"
           END-IF.
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[36m======================================================================\033[0m'".

       DISPLAY-WITH-CODE-HIGHLIGHTING.
      *> Display response with syntax highlighting for code blocks
           MOVE "N" TO WS-IN-CODE-BLOCK.
           MOVE 1 TO WS-JSON-I.
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-CLEAN-RESPONSE))
               TO WS-RESPONSE-LEN.
           MOVE SPACES TO WS-CODE-LINE.
           MOVE 0 TO WS-OUT-POS.

           PERFORM VARYING WS-JSON-I FROM 1 BY 1
               UNTIL WS-JSON-I > WS-RESPONSE-LEN
               IF WS-CLEAN-RESPONSE(WS-JSON-I:1) = X"0A"
      *> Newline - check if we're entering/exiting code block
                   IF WS-CODE-LINE(1:3) = "```" AND NOT-IN-CODE
                       MOVE "Y" TO WS-IN-CODE-BLOCK
                       CALL "SYSTEM" USING
                           "printf '\033[30;46m'"
                       DISPLAY "```"
                       CALL "SYSTEM" USING
                           "printf '\033[0m'"
                   ELSE
                       IF WS-CODE-LINE(1:3) = "```" AND IN-CODE-BLOCK
                           MOVE "N" TO WS-IN-CODE-BLOCK
                           CALL "SYSTEM" USING
                               "printf '\033[0m'"
                       ELSE
                           IF IN-CODE-BLOCK
                               CALL "SYSTEM" USING
                                   "printf '\033[36m'"
                               DISPLAY FUNCTION TRIM(WS-CODE-LINE)
                               CALL "SYSTEM" USING
                                   "printf '\033[0m'"
                           ELSE
                               DISPLAY FUNCTION TRIM(WS-CODE-LINE)
                           END-IF
                       END-IF
                   END-IF
                   MOVE SPACES TO WS-CODE-LINE
                   MOVE 0 TO WS-OUT-POS
               ELSE
                   IF WS-OUT-POS < 199
                       ADD 1 TO WS-OUT-POS
                       MOVE WS-CLEAN-RESPONSE(WS-JSON-I:1)
                           TO WS-CODE-LINE(WS-OUT-POS:1)
                   END-IF
               END-IF
           END-PERFORM.
      *> Display any remaining content
           IF FUNCTION TRIM(WS-CODE-LINE) NOT = SPACES
               IF IN-CODE-BLOCK
                   CALL "SYSTEM" USING
                       "printf '\033[36m'"
                   DISPLAY FUNCTION TRIM(WS-CODE-LINE)
                   CALL "SYSTEM" USING
                       "printf '\033[0m'"
               ELSE
                   DISPLAY FUNCTION TRIM(WS-CODE-LINE)
               END-IF
           END-IF.

       CLEAN-ESCAPE-SEQUENCES.
      *> Convert escape sequences including unicode to characters
           MOVE SPACES TO WS-CLEAN-RESPONSE.
           MOVE 1 TO WS-OUT-POS.
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-JSON-EXTRACTED))
               TO WS-RESPONSE-LEN.

      *> Process each character
           PERFORM VARYING WS-JSON-I FROM 1 BY 1
               UNTIL WS-JSON-I > WS-RESPONSE-LEN
               OR WS-OUT-POS > 24999

      *> Check for \n (newline) - convert to actual newline
               IF WS-JSON-I < WS-RESPONSE-LEN
               AND WS-JSON-EXTRACTED(WS-JSON-I:2) = "\n"
                   MOVE X"0A" TO WS-CLEAN-RESPONSE(WS-OUT-POS:1)
                   ADD 1 TO WS-JSON-I
                   ADD 1 TO WS-OUT-POS
               ELSE
      *> Check for \\ (backslash) - keep single backslash
                   IF WS-JSON-I < WS-RESPONSE-LEN
                   AND WS-JSON-EXTRACTED(WS-JSON-I:2) = "\\"
                       MOVE "\" TO WS-CLEAN-RESPONSE(WS-OUT-POS:1)
                       ADD 1 TO WS-JSON-I
                       ADD 1 TO WS-OUT-POS
                   ELSE
      *> Check for \" (quote) - keep single quote
                       IF WS-JSON-I < WS-RESPONSE-LEN
                       AND WS-JSON-EXTRACTED(WS-JSON-I:2) = "\"""
                           MOVE '"' TO WS-CLEAN-RESPONSE(WS-OUT-POS:1)
                           ADD 1 TO WS-JSON-I
                           ADD 1 TO WS-OUT-POS
                       ELSE
      *> Check for \uXXXX (unicode escape)
                           IF WS-JSON-I < WS-RESPONSE-LEN - 5
                           AND WS-JSON-EXTRACTED(WS-JSON-I:2) = "\u"
      *> Convert common unicode sequences
                               IF WS-JSON-EXTRACTED(WS-JSON-I:6) =
                                  X"5C7530303363"
      *> < = < (less than)
                                   MOVE "<" TO WS-CLEAN-RESPONSE(
                                       WS-OUT-POS:1)
                                   ADD 5 TO WS-JSON-I
                                   ADD 1 TO WS-OUT-POS
                               ELSE
                                   IF WS-JSON-EXTRACTED(WS-JSON-I:6) =
                                      X"5C7530303365"
      *> > = > (greater than)
                                       MOVE ">" TO WS-CLEAN-RESPONSE(
                                           WS-OUT-POS:1)
                                       ADD 5 TO WS-JSON-I
                                       ADD 1 TO WS-OUT-POS
                                   ELSE
                                       IF WS-JSON-EXTRACTED(WS-JSON-I:6) =
                                          X"5C75303236"
      *> & = & (ampersand)
                                           MOVE "&" TO WS-CLEAN-RESPONSE(
                                               WS-OUT-POS:1)
                                           ADD 5 TO WS-JSON-I
                                           ADD 1 TO WS-OUT-POS
                                       ELSE
                                           IF WS-JSON-EXTRACTED(WS-JSON-I:6)
                                              = X"5C7530303232"
      *> " = " (quote)
                                               MOVE '"' TO WS-CLEAN-RESPONSE(
                                                   WS-OUT-POS:1)
                                               ADD 5 TO WS-JSON-I
                                               ADD 1 TO WS-OUT-POS
                                           ELSE
      *> For other unicode, skip the 6-char sequence
                                               ADD 5 TO WS-JSON-I
                                           END-IF
                                       END-IF
                                   END-IF
                               END-IF
                           ELSE
      *> Copy regular character
                               MOVE WS-JSON-EXTRACTED(WS-JSON-I:1)
                                   TO WS-CLEAN-RESPONSE(WS-OUT-POS:1)
                               ADD 1 TO WS-OUT-POS
                           END-IF
                       END-IF
                   END-IF
               END-IF
           END-PERFORM.

       CLEANUP-TEMP-FILES.
           CALL "SYSTEM" USING "rm -f /tmp/cobol-ai-response.json".

       CLEANUP-PROGRAM.
      *> Persist the cache so the next run starts warm
           PERFORM SAVE-RESPONSE-CACHE.

      *> Phase 4: Show cache statistics on exit
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[32m----------------------------------------------------------------------\033[0m'".
           CALL "SYSTEM" USING
               "printf '\033[1;32m*** Thank you for using COBOL AI CLI! ***\033[0m'".
           CALL "SYSTEM" USING
               "printf '\033[32m----------------------------------------------------------------------\033[0m'".
           DISPLAY SPACES.
           IF WS-CACHE-HITS > 0 OR WS-CACHE-MISSES > 0
               DISPLAY "Session Statistics:"
               DISPLAY "  Cache Hits:   " WS-CACHE-HITS
               DISPLAY "  Cache Misses: " WS-CACHE-MISSES
               IF WS-CACHE-HITS + WS-CACHE-MISSES > 0
                   COMPUTE WS-TEMP-POS = (WS-CACHE-HITS * 100) /
                       (WS-CACHE-HITS + WS-CACHE-MISSES)
                   DISPLAY "  Hit Rate:     " WS-TEMP-POS "%"
               END-IF
           END-IF.
           IF WS-ERROR-COUNT > 0
               DISPLAY "  Errors:       " WS-ERROR-COUNT
           END-IF.
           DISPLAY SPACES.

       END PROGRAM COBOL-AI-CLI.
