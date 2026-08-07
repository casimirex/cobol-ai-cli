      *>================================================================*
      *> PROCEDURE: Error handling
      *>
      *> LOG-ERROR and DISPLAY-ERROR-MESSAGE.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

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
