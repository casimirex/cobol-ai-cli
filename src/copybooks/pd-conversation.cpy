      *>================================================================*
      *> PROCEDURE: Conversation history and export
      *>
      *> Recording, showing and exporting the conversation.
      *> Included by src/main.cob - not compiled on its own.
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
           MOVE SPACES TO WS-EXPORT-FILE-NAME
           STRING FUNCTION TRIM(WS-STATE-DIR) "/export.txt"
               DELIMITED BY SIZE INTO WS-EXPORT-FILE-NAME.
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
