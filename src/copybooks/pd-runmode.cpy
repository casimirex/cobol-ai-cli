      *>================================================================*
      *> PROCEDURE: Run mode and the interactive loop
      *>
      *> Pipe/argument detection, the prompt loop and command dispatch.
      *> Included by src/main.cob - not compiled on its own.
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
           MOVE SPACES TO WS-PATH-CMD
           STRING "rm -f '" FUNCTION TRIM(WS-STDIN-TEMP-FILE) "'"
               DELIMITED BY SIZE INTO WS-PATH-CMD
           CALL "SYSTEM" USING WS-PATH-CMD.

      *>================================================================*
      *> APPLICATION RUNNER
      *>================================================================*
       RUN-APPLICATION.
           IF MODE-ONE-SHOT
      *> One-shot supports the same file syntax as interactive mode
               MOVE "N" TO WS-FILE-LOADED
               IF FUNCTION LOWER-CASE(WS-PROMPT(1:5)) = "file "
                   PERFORM LOAD-PROMPT-FILE
                   IF NOT FILE-LOADED
                       EXIT PARAGRAPH
                   END-IF
               END-IF
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

      *> Check for version command
           IF CMD-VERSION
               PERFORM SHOW-VERSION
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
      *> Compare the trimmed value: a reference-modified slice must match
      *> the literal's length exactly, and (1:11) never could equal a
      *> 12-character word, so "conversation" was falling through to the
      *> prompt handler and being sent to the API as a question.
           IF FUNCTION TRIM(WS-COMMAND-TYPE) = "conv" OR
              FUNCTION TRIM(WS-COMMAND-TYPE) = "conversation"
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

      *> Check for file command (Phase 3 - File Input)
           MOVE "N" TO WS-FILE-LOADED.
           IF FUNCTION LOWER-CASE(WS-PROMPT(1:5)) = "file "
               PERFORM LOAD-PROMPT-FILE
               IF NOT FILE-LOADED
                   EXIT PARAGRAPH
               END-IF
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

       PROCESS-PROMPT.
      *> Build the text to send (may include an attached file)
           PERFORM COMPOSE-PROMPT.

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

      *>================================================================*
      *> SECTION: FILE INPUT (Phase 3)
      *>================================================================*
