      *>================================================================*
      *> PROCEDURE: Configuration and credentials
      *>
      *> LOAD-CONFIGURATION, LOAD-ENCRYPTED-CREDENTIALS, VALIDATE-CONFIGURATION.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

       INIT-PATHS.
      *> Resolve every runtime path before any file is touched.
      *> Persistent state: XDG_STATE_HOME, else ~/.local/state, else /tmp.
           MOVE SPACES TO WS-PATH-ENV.
           ACCEPT WS-PATH-ENV FROM ENVIRONMENT "XDG_STATE_HOME".
           IF WS-PATH-ENV NOT = SPACES
               STRING FUNCTION TRIM(WS-PATH-ENV) "/cobol-ai-cli"
                   DELIMITED BY SIZE INTO WS-STATE-DIR
           ELSE
               MOVE SPACES TO WS-PATH-ENV
               ACCEPT WS-PATH-ENV FROM ENVIRONMENT "HOME"
               IF WS-PATH-ENV NOT = SPACES
                   STRING FUNCTION TRIM(WS-PATH-ENV)
                          "/.local/state/cobol-ai-cli"
                       DELIMITED BY SIZE INTO WS-STATE-DIR
               ELSE
      *> No HOME at all - fall back to /tmp, still per-user by name
                   MOVE "/tmp/cobol-ai-state" TO WS-STATE-DIR
               END-IF
           END-IF.

           MOVE SPACES TO WS-PATH-CMD.
           STRING "mkdir -p -m 700 '" DELIMITED BY SIZE
                  FUNCTION TRIM(WS-STATE-DIR) DELIMITED BY SIZE
                  "' 2>/dev/null" DELIMITED BY SIZE
               INTO WS-PATH-CMD
           END-STRING.
           CALL "SYSTEM" USING WS-PATH-CMD.

      *> Run id: the wrapper exports the shell PID; otherwise derive one
      *> from the clock and a random suffix so direct invocations of
      *> cobol-ai.bin still get a private set of scratch files.
           MOVE SPACES TO WS-PATH-ENV.
           ACCEPT WS-PATH-ENV FROM ENVIRONMENT "COBOL_AI_RUN_ID".
           IF WS-PATH-ENV NOT = SPACES
               MOVE FUNCTION TRIM(WS-PATH-ENV) TO WS-RUN-ID
           ELSE
               MOVE FUNCTION CURRENT-DATE(9:8) TO WS-RUN-SEED
               COMPUTE WS-RUN-RAND =
                   FUNCTION RANDOM(WS-RUN-SEED) * 999999
               MOVE SPACES TO WS-RUN-ID
               STRING WS-RUN-SEED WS-RUN-RAND
                   DELIMITED BY SIZE INTO WS-RUN-ID
           END-IF.

           MOVE SPACES TO WS-TMP-PREFIX.
           STRING "/tmp/cobol-ai-" FUNCTION TRIM(WS-RUN-ID) "-"
               DELIMITED BY SIZE INTO WS-TMP-PREFIX.

           PERFORM RESOLVE-HELPER.

      *> Persistent state files
           PERFORM BUILD-STATE-PATHS.
      *> Per-request scratch files
           PERFORM BUILD-SCRATCH-PATHS.

       RESOLVE-HELPER.
      *> The helper used to be invoked as a bare "./cobol-ai-helper.sh",
      *> which only works when the process happens to be running from the
      *> project directory. An installed binary failed every request.
      *> Order: explicit override, then alongside the CWD, then $PATH.
           MOVE SPACES TO WS-PATH-ENV.
           ACCEPT WS-PATH-ENV FROM ENVIRONMENT "COBOL_AI_HELPER".
           IF WS-PATH-ENV NOT = SPACES
               MOVE FUNCTION TRIM(WS-PATH-ENV) TO WS-HELPER-SCRIPT
               EXIT PARAGRAPH
           END-IF.

           MOVE "./cobol-ai-helper.sh" TO WS-HELPER-SCRIPT.
           OPEN INPUT HELPER-PROBE.
           IF WS-HELPER-PROBE-STATUS = "00"
               CLOSE HELPER-PROBE
               EXIT PARAGRAPH
           END-IF.
      *> Status 05 means the OPTIONAL file was absent - fall back to a
      *> bare name so the shell resolves it on $PATH.
           IF WS-HELPER-PROBE-STATUS = "05"
               CLOSE HELPER-PROBE
           END-IF.
           MOVE "cobol-ai-helper.sh" TO WS-HELPER-SCRIPT.

       BUILD-STATE-PATHS.
           MOVE SPACES TO WS-CACHE-FILE.
           STRING FUNCTION TRIM(WS-STATE-DIR) "/cache.dat"
               DELIMITED BY SIZE INTO WS-CACHE-FILE.
           MOVE SPACES TO WS-HIST-FILE-NAME.
           STRING FUNCTION TRIM(WS-STATE-DIR) "/history.txt"
               DELIMITED BY SIZE INTO WS-HIST-FILE-NAME.
           MOVE SPACES TO WS-THEME-FILE-NAME.
           STRING FUNCTION TRIM(WS-STATE-DIR) "/theme.txt"
               DELIMITED BY SIZE INTO WS-THEME-FILE-NAME.
           MOVE SPACES TO WS-CONV-FILE-NAME.
           STRING FUNCTION TRIM(WS-STATE-DIR) "/conversation.json"
               DELIMITED BY SIZE INTO WS-CONV-FILE-NAME.
           MOVE SPACES TO WS-ERROR-FILE-NAME.
           STRING FUNCTION TRIM(WS-STATE-DIR) "/errors.log"
               DELIMITED BY SIZE INTO WS-ERROR-FILE-NAME.

       BUILD-SCRATCH-PATHS.
           MOVE SPACES TO WS-RESPONSE-FILE.
           STRING FUNCTION TRIM(WS-TMP-PREFIX) "response.json"
               DELIMITED BY SIZE INTO WS-RESPONSE-FILE.
           MOVE SPACES TO WS-STATUS-FILE-NAME.
           STRING FUNCTION TRIM(WS-TMP-PREFIX) "status.txt"
               DELIMITED BY SIZE INTO WS-STATUS-FILE-NAME.
           MOVE SPACES TO WS-PROMPT-FILE-NAME.
           STRING FUNCTION TRIM(WS-TMP-PREFIX) "prompt.txt"
               DELIMITED BY SIZE INTO WS-PROMPT-FILE-NAME.
           MOVE SPACES TO WS-KEYRING-FILE-NAME.
           STRING FUNCTION TRIM(WS-TMP-PREFIX) "key.txt"
               DELIMITED BY SIZE INTO WS-KEYRING-FILE-NAME.
      *> COBOL_AI_STDIN names the file the wrapper captured stdin into
           MOVE SPACES TO WS-PATH-ENV.
           ACCEPT WS-PATH-ENV FROM ENVIRONMENT "COBOL_AI_STDIN".
           IF WS-PATH-ENV NOT = SPACES
               MOVE FUNCTION TRIM(WS-PATH-ENV) TO WS-STDIN-TEMP-FILE
           ELSE
               MOVE SPACES TO WS-STDIN-TEMP-FILE
               STRING FUNCTION TRIM(WS-TMP-PREFIX) "stdin.txt"
                   DELIMITED BY SIZE INTO WS-STDIN-TEMP-FILE
           END-IF.

       LOAD-CONFIGURATION.
      *> An explicitly exported key wins; otherwise consult the keyring.
      *> Note the ./cobol-ai wrapper exports .env, so a key left in .env
      *> still takes precedence - remove it there to use the keyring.
           ACCEPT WS-API-KEY FROM ENVIRONMENT "AI_OLLAMA_API_KEY"

           IF WS-API-KEY = SPACES THEN
               PERFORM LOAD-ENCRYPTED-CREDENTIALS
           END-IF

           IF WS-API-KEY = SPACES THEN
               CALL "SYSTEM" USING
                   "printf '\033[31m[ERR] ERROR: AI_OLLAMA_API_KEY not set\033[0m'"
               DISPLAY "      Set it in .env, in the environment, or store it"
               DISPLAY "      in the keyring:"
               DISPLAY "        secret-tool store --label='COBOL AI CLI' \"
               DISPLAY "          service cobol-ai-cli key api-key"
               STOP RUN
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
      *> Read the API key from the system keyring via secret-tool.
      *> Seed it once with:
      *>   secret-tool store --label='COBOL AI CLI' \
      *>     service cobol-ai-cli key api-key
           MOVE "N" TO WS-ENCRYPTED-KEY.
           MOVE SPACES TO WS-KEYRING-VALUE.

      *> COBOL cannot capture command output, so the lookup goes through
      *> a temp file. umask 077 keeps it readable only by this user, and
      *> it is deleted immediately after reading.
           MOVE SPACES TO WS-KEYRING-CMD.
           STRING "command -v secret-tool >/dev/null 2>&1 && "
                  DELIMITED BY SIZE
                  "(umask 077; secret-tool lookup service cobol-ai-cli "
                  DELIMITED BY SIZE
                  "key api-key > " DELIMITED BY SIZE
                  FUNCTION TRIM(WS-KEYRING-FILE-NAME) DELIMITED BY SIZE
                  " 2>/dev/null)" DELIMITED BY SIZE
               INTO WS-KEYRING-CMD
           END-STRING.
           CALL "SYSTEM" USING WS-KEYRING-CMD.

           OPEN INPUT KEYRING-FILE.
           IF WS-KEYRING-FILE-STATUS = "00"
              OR WS-KEYRING-FILE-STATUS = "05"
               READ KEYRING-FILE INTO WS-KEYRING-VALUE
                   AT END
                       MOVE SPACES TO WS-KEYRING-VALUE
               END-READ
               CLOSE KEYRING-FILE
           END-IF.

           MOVE SPACES TO WS-PATH-CMD
           STRING "rm -f '" FUNCTION TRIM(WS-KEYRING-FILE-NAME) "'"
               DELIMITED BY SIZE INTO WS-PATH-CMD
           CALL "SYSTEM" USING WS-PATH-CMD.

           IF FUNCTION TRIM(WS-KEYRING-VALUE) NOT = SPACES
               MOVE FUNCTION TRIM(WS-KEYRING-VALUE) TO WS-API-KEY
               MOVE "Y" TO WS-ENCRYPTED-KEY
           END-IF.
           MOVE SPACES TO WS-KEYRING-VALUE.

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
