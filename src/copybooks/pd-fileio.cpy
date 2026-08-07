      *>================================================================*
      *> PROCEDURE: File input and output
      *>
      *> Attaching a file to a prompt, composing it, and the output file.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

       LOAD-PROMPT-FILE.
      *> Handle "file <path> [question]" - read the file into the prompt
           MOVE "N" TO WS-FILE-LOADED.
           MOVE "N" TO WS-FILE-TRUNCATED.
           MOVE SPACES TO WS-FILE-CONTENT.
           MOVE SPACES TO WS-USER-FILE-NAME.
           MOVE SPACES TO WS-FILE-QUESTION.
           MOVE 1 TO WS-FILE-POS.
           MOVE 0 TO WS-FILE-LINES.

      *> Split "<path> <question>" on the first space
           MOVE FUNCTION TRIM(WS-PROMPT(6:995)) TO WS-FILE-ARG.
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-FILE-ARG))
               TO WS-FILE-ARG-LEN.
           IF WS-FILE-ARG = SPACES
               DISPLAY "Usage: file <path> [question]"
               DISPLAY SPACES
               EXIT PARAGRAPH
           END-IF.

           MOVE 0 TO WS-FILE-SPLIT.
           PERFORM VARYING WS-FILE-POS FROM 1 BY 1
               UNTIL WS-FILE-POS > WS-FILE-ARG-LEN
               OR WS-FILE-SPLIT > 0
               IF WS-FILE-ARG(WS-FILE-POS:1) = SPACE
                   MOVE WS-FILE-POS TO WS-FILE-SPLIT
               END-IF
           END-PERFORM.

           IF WS-FILE-SPLIT > 0
               MOVE WS-FILE-ARG(1:WS-FILE-SPLIT - 1)
                   TO WS-USER-FILE-NAME
               MOVE FUNCTION TRIM(WS-FILE-ARG(WS-FILE-SPLIT:))
                   TO WS-FILE-QUESTION
           ELSE
               MOVE FUNCTION TRIM(WS-FILE-ARG) TO WS-USER-FILE-NAME
               MOVE "Explain what this file does."
                   TO WS-FILE-QUESTION
           END-IF.

      *> Read the file
           MOVE 1 TO WS-FILE-POS.
           OPEN INPUT USER-FILE.
           IF WS-USER-FILE-STATUS NOT = "00"
               CALL "SYSTEM" USING
                   "printf '\033[31m[ERR]\033[0m Cannot read file'"
               DISPLAY SPACES
               DISPLAY "      " FUNCTION TRIM(WS-USER-FILE-NAME)
               DISPLAY "      (status " WS-USER-FILE-STATUS ")"
               DISPLAY SPACES
               EXIT PARAGRAPH
           END-IF.

           PERFORM UNTIL WS-USER-FILE-STATUS NOT = "00"
               READ USER-FILE
                   AT END
                       MOVE "99" TO WS-USER-FILE-STATUS
                   NOT AT END
                       PERFORM APPEND-FILE-LINE
               END-READ
           END-PERFORM.
           CLOSE USER-FILE.

           COMPUTE WS-FILE-CHARS = WS-FILE-POS - 1.
           IF WS-FILE-LINES = 0
               DISPLAY "  File is empty: "
                   FUNCTION TRIM(WS-USER-FILE-NAME)
               DISPLAY SPACES
               EXIT PARAGRAPH
           END-IF.

           MOVE "Y" TO WS-FILE-LOADED.
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[32m[FILE]\033[0m Attached'".
           DISPLAY SPACES.
           DISPLAY "    Path:  " FUNCTION TRIM(WS-USER-FILE-NAME).
           DISPLAY "    Lines: " WS-FILE-LINES.
           DISPLAY "    Chars: " WS-FILE-CHARS.
           IF FILE-TRUNCATED
               CALL "SYSTEM" USING
                   "printf '\033[33m[WARN]\033[0m File truncated to fit the context limit'"
               DISPLAY SPACES
           END-IF.
           DISPLAY SPACES.

       APPEND-FILE-LINE.
      *> Append one line, stopping cleanly once the buffer is full
           IF FILE-TRUNCATED
               EXIT PARAGRAPH
           END-IF.

           IF USER-FILE-LINE = SPACES
               MOVE 0 TO WS-FILE-LINE-LEN
           ELSE
               MOVE FUNCTION LENGTH(FUNCTION TRIM(USER-FILE-LINE
                   TRAILING)) TO WS-FILE-LINE-LEN
           END-IF.

           IF WS-FILE-POS + WS-FILE-LINE-LEN + 1 > WS-FILE-MAX
               MOVE "Y" TO WS-FILE-TRUNCATED
               EXIT PARAGRAPH
           END-IF.

           IF WS-FILE-LINE-LEN > 0
               MOVE USER-FILE-LINE(1:WS-FILE-LINE-LEN)
                   TO WS-FILE-CONTENT(WS-FILE-POS:WS-FILE-LINE-LEN)
               ADD WS-FILE-LINE-LEN TO WS-FILE-POS
           END-IF.
           MOVE WS-NL TO WS-FILE-CONTENT(WS-FILE-POS:1).
           ADD 1 TO WS-FILE-POS.
           ADD 1 TO WS-FILE-LINES.

       COMPOSE-PROMPT.
      *> Build the text actually sent to the model. This is what the
      *> cache keys on, so an attached file must be part of it.
           MOVE SPACES TO WS-FULL-PROMPT.
           IF FILE-LOADED
               STRING FUNCTION TRIM(WS-FILE-QUESTION) DELIMITED BY SIZE
                      WS-NL WS-NL DELIMITED BY SIZE
                      "--- BEGIN FILE: " DELIMITED BY SIZE
                      FUNCTION TRIM(WS-USER-FILE-NAME)
                          DELIMITED BY SIZE
                      " ---" DELIMITED BY SIZE
                      WS-NL DELIMITED BY SIZE
                      WS-FILE-CONTENT(1:WS-FILE-CHARS)
                          DELIMITED BY SIZE
                      WS-NL DELIMITED BY SIZE
                      "--- END FILE ---" DELIMITED BY SIZE
                   INTO WS-FULL-PROMPT
               END-STRING
           ELSE
               MOVE FUNCTION TRIM(WS-PROMPT) TO WS-FULL-PROMPT
           END-IF.

       WRITE-PROMPT-FILE.
      *> Hand the prompt to the helper through a file so that quotes and
      *> newlines in file contents cannot break the shell command.
           OPEN OUTPUT PROMPT-FILE.
           IF WS-PROMPT-FILE-STATUS NOT = "00"
               MOVE ERR-FILE-IO TO WS-LAST-ERROR-CODE
               MOVE "Cannot write prompt file" TO WS-LAST-ERROR-MSG
               PERFORM LOG-ERROR
               EXIT PARAGRAPH
           END-IF.
           MOVE WS-FULL-PROMPT TO PROMPT-FILE-LINE.
           WRITE PROMPT-FILE-LINE.
           CLOSE PROMPT-FILE.

       SET-OUTPUT-FILE.
      *> Set output file for responses (Phase 3)
      *> Parse into a scratch field first - a bare "output" must report
      *> the current setting, not silently clear it.
           IF FUNCTION TRIM(WS-PROMPT(1:7)) = "output "
               MOVE FUNCTION TRIM(WS-PROMPT(8:200)) TO WS-OUTPUT-ARG
           ELSE
               MOVE FUNCTION TRIM(WS-PROMPT(5:200)) TO WS-OUTPUT-ARG
           END-IF.

           EVALUATE TRUE
               WHEN FUNCTION LOWER-CASE(FUNCTION TRIM(WS-OUTPUT-ARG))
                    = "off"
                   MOVE SPACES TO WS-OUTPUT-FILE-NAME
                   DISPLAY "Output file logging disabled"
               WHEN FUNCTION TRIM(WS-OUTPUT-ARG) = SPACES
                   IF FUNCTION TRIM(WS-OUTPUT-FILE-NAME) = SPACES
                       DISPLAY "No output file set"
                   ELSE
                       DISPLAY "Current output file: "
                           FUNCTION TRIM(WS-OUTPUT-FILE-NAME)
                   END-IF
                   DISPLAY "Usage: output <filename> | output off"
               WHEN OTHER
                   MOVE FUNCTION TRIM(WS-OUTPUT-ARG)
                       TO WS-OUTPUT-FILE-NAME
                   DISPLAY "Output file set to: "
                       FUNCTION TRIM(WS-OUTPUT-FILE-NAME)
                   DISPLAY "Responses will be appended to this file"
           END-EVALUATE.
           DISPLAY SPACES.

       WRITE-TO-OUTPUT-FILE.
      *> Append the exchange to the output file if one is set (Phase 3).
      *> Runs after DISPLAY-RESPONSE-WITH-HIGHLIGHTING, which is what
      *> populates WS-CLEAN-RESPONSE.
           IF FUNCTION TRIM(WS-OUTPUT-FILE-NAME) = SPACES
               EXIT PARAGRAPH
           END-IF.
           IF WS-JSON-FOUND NOT = "Y" OR WS-CLEAN-RESPONSE = SPACES
               EXIT PARAGRAPH
           END-IF.

      *> Status 05 means the OPTIONAL file was absent and has just been
      *> created - a success, not a reason to reopen it.
           OPEN EXTEND OUTPUT-FILE.
           IF WS-OUTPUT-FILE-STATUS NOT = "00"
              AND WS-OUTPUT-FILE-STATUS NOT = "05"
      *> Fall back to creating the file
               OPEN OUTPUT OUTPUT-FILE
           END-IF.
           IF WS-OUTPUT-FILE-STATUS NOT = "00"
              AND WS-OUTPUT-FILE-STATUS NOT = "05"
               MOVE ERR-FILE-IO TO WS-LAST-ERROR-CODE
               MOVE "Cannot write to output file"
                   TO WS-LAST-ERROR-MSG
               PERFORM LOG-ERROR
               CALL "SYSTEM" USING
                   "printf '\033[31m[ERR]\033[0m Cannot write output file'"
               DISPLAY SPACES
               DISPLAY "      " FUNCTION TRIM(WS-OUTPUT-FILE-NAME)
               DISPLAY "      (status " WS-OUTPUT-FILE-STATUS ")"
               DISPLAY SPACES
               EXIT PARAGRAPH
           END-IF.

           MOVE FUNCTION CURRENT-DATE(1:14) TO WS-TIME-VALUE.
           MOVE SPACES TO OUTPUT-RECORD.
           STRING "=== " DELIMITED BY SIZE
                  WS-TIME-VALUE(1:4) "-" WS-TIME-VALUE(5:2) "-"
                  WS-TIME-VALUE(7:2) DELIMITED BY SIZE
                  " " WS-TIME-VALUE(9:2) ":" WS-TIME-VALUE(11:2) ":"
                  WS-TIME-VALUE(13:2) DELIMITED BY SIZE
                  " | model: " DELIMITED BY SIZE
                  FUNCTION TRIM(WS-MODEL) DELIMITED BY SIZE
                  " ===" DELIMITED BY SIZE
               INTO OUTPUT-RECORD
           END-STRING.
           WRITE OUTPUT-RECORD.

           MOVE SPACES TO OUTPUT-RECORD.
           STRING "> " DELIMITED BY SIZE
                  FUNCTION TRIM(WS-PROMPT) DELIMITED BY SIZE
               INTO OUTPUT-RECORD
           END-STRING.
           WRITE OUTPUT-RECORD.

           MOVE SPACES TO OUTPUT-RECORD.
           WRITE OUTPUT-RECORD.

           MOVE WS-CLEAN-RESPONSE TO OUTPUT-RECORD.
           WRITE OUTPUT-RECORD.

           MOVE SPACES TO OUTPUT-RECORD.
           WRITE OUTPUT-RECORD.
           CLOSE OUTPUT-FILE.

           DISPLAY "  [SAVED] Appended to "
               FUNCTION TRIM(WS-OUTPUT-FILE-NAME).
