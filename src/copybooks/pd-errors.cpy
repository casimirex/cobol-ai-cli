      *>================================================================*
      *> PROCEDURE: Error handling
      *>
      *> LOG-ERROR and DISPLAY-ERROR-MESSAGE.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

       LOG-ERROR.
      *> Append to a dedicated error log. This used to OPEN OUTPUT the
      *> command-history file, which truncates: a single API error wiped
      *> the user's saved history and replaced it with error text.
           ADD 1 TO WS-ERROR-COUNT.
           IF FUNCTION TRIM(WS-ERROR-FILE-NAME) = SPACES
               EXIT PARAGRAPH
           END-IF.

           OPEN EXTEND ERROR-FILE.
           IF WS-ERROR-FILE-STATUS NOT = "00"
              AND WS-ERROR-FILE-STATUS NOT = "05"
               EXIT PARAGRAPH
           END-IF.

           MOVE WS-LAST-ERROR-CODE TO WS-ERROR-CODE-DISP.
           MOVE SPACES TO ERROR-LINE.
           STRING "[" FUNCTION CURRENT-DATE(1:4) "-"
                  FUNCTION CURRENT-DATE(5:2) "-"
                  FUNCTION CURRENT-DATE(7:2) " "
                  FUNCTION CURRENT-DATE(9:2) ":"
                  FUNCTION CURRENT-DATE(11:2) ":"
                  FUNCTION CURRENT-DATE(13:2) "] code="
                  WS-ERROR-CODE-DISP " "
                  FUNCTION TRIM(WS-LAST-ERROR-MSG)
                  DELIMITED BY SIZE INTO ERROR-LINE
           END-STRING.
           WRITE ERROR-LINE.
           CLOSE ERROR-FILE.

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
