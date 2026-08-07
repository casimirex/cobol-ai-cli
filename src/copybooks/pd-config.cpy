      *>================================================================*
      *> PROCEDURE: Configuration and credentials
      *>
      *> LOAD-CONFIGURATION, LOAD-ENCRYPTED-CREDENTIALS, VALIDATE-CONFIGURATION.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

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

           CALL "SYSTEM" USING "rm -f /tmp/cobol-ai-key.txt".

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
