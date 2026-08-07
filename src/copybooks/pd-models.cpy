      *>================================================================*
      *> PROCEDURE: Model management and statistics
      *>
      *> INIT-MODEL-LIST, SHOW-MODELS, SHOW-STATS, CHANGE-MODEL.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

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
