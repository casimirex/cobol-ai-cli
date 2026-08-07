      *>================================================================*
      *> PROCEDURE: Command history
      *>
      *> Loading, saving, appending and showing the prompt history.
      *> Included by src/main.cob - not compiled on its own.
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
