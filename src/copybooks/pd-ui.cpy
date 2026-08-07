      *>================================================================*
      *> PROCEDURE: Banner, themes, help and response rendering
      *>
      *> Visual output: banner, themes, spinner, help, syntax highlighting.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

       DISPLAY-BANNER.
      *> Display colorful banner with theme colors
           CALL "SYSTEM" USING
               "printf '\033[1;36m+======================================================================+\033[0m\n'".
           MOVE SPACES TO WS-PATH-CMD
           STRING "printf '\033[1;36m|\033[0m              COBOL AI CLI v"
                  DELIMITED BY SIZE
                  FUNCTION TRIM(WS-VERSION) DELIMITED BY SIZE
                  "                        \033[1;36m|\033[0m\n'"
                  DELIMITED BY SIZE
               INTO WS-PATH-CMD
           END-STRING
           CALL "SYSTEM" USING WS-PATH-CMD.
           CALL "SYSTEM" USING
               "printf '\033[1;36m|\033[0m                  Powered by Ollama Cloud API                        \033[1;36m|\033[0m\n'".
           CALL "SYSTEM" USING
               "printf '\033[1;36m+======================================================================+\033[0m\n'".
           DISPLAY SPACES.

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
           DISPLAY "  output off     - Stop appending to the output file".
           DISPLAY "  stats          - Show cache and error statistics".
           DISPLAY "  cache clear    - Empty the persistent response cache".
           DISPLAY "  file <path> [question] - Ask about a file's contents".
           DISPLAY "  version        - Show the version and build info".
           DISPLAY "  exit           - Exit the program".
           DISPLAY "  quit           - Exit the program".
           DISPLAY SPACES.
           DISPLAY "Pipe support: echo 'prompt' | ./cobol-ai".
           DISPLAY SPACES.

      *>================================================================*
      *> PROMPT PROCESSING
      *>================================================================*

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

       SHOW-VERSION.
      *> CMD-VERSION was declared but dispatched nowhere, so typing
      *> `version` was sent to the API as a question.
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[1;33m=== COBOL AI CLI ===\033[0m\n'".
           DISPLAY "  Version: " FUNCTION TRIM(WS-VERSION).
           DISPLAY "  Model:   " FUNCTION TRIM(WS-MODEL).
           DISPLAY "  Endpoint: " FUNCTION TRIM(WS-BASE-URL).
           DISPLAY "  State:   " FUNCTION TRIM(WS-STATE-DIR).
           DISPLAY "  Helper:  " FUNCTION TRIM(WS-HELPER-SCRIPT).
           DISPLAY SPACES.
