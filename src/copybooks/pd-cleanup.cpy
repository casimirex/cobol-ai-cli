      *>================================================================*
      *> PROCEDURE: Shutdown
      *>
      *> Temp file removal and the end-of-session summary.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

       CLEANUP-TEMP-FILES.
           MOVE SPACES TO WS-PATH-CMD
           STRING "rm -f '" FUNCTION TRIM(WS-RESPONSE-FILE) "'"
               DELIMITED BY SIZE INTO WS-PATH-CMD
           CALL "SYSTEM" USING WS-PATH-CMD.
           MOVE SPACES TO WS-PATH-CMD
           STRING "rm -f '" FUNCTION TRIM(WS-PROMPT-FILE-NAME) "'"
               DELIMITED BY SIZE INTO WS-PATH-CMD
           CALL "SYSTEM" USING WS-PATH-CMD.
           MOVE SPACES TO WS-PATH-CMD
           STRING "rm -f '" FUNCTION TRIM(WS-STATUS-FILE-NAME) "'"
               DELIMITED BY SIZE INTO WS-PATH-CMD
           CALL "SYSTEM" USING WS-PATH-CMD.

       CLEANUP-PROGRAM.
      *> Persist the cache so the next run starts warm
           PERFORM SAVE-RESPONSE-CACHE.

      *> Phase 4: Show cache statistics on exit
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[32m----------------------------------------------------------------------\033[0m'".
           CALL "SYSTEM" USING
               "printf '\033[1;32m*** Thank you for using COBOL AI CLI! ***\033[0m'".
           CALL "SYSTEM" USING
               "printf '\033[32m----------------------------------------------------------------------\033[0m'".
           DISPLAY SPACES.
           IF WS-CACHE-HITS > 0 OR WS-CACHE-MISSES > 0
               DISPLAY "Session Statistics:"
               DISPLAY "  Cache Hits:   " WS-CACHE-HITS
               DISPLAY "  Cache Misses: " WS-CACHE-MISSES
               IF WS-CACHE-HITS + WS-CACHE-MISSES > 0
                   COMPUTE WS-TEMP-POS = (WS-CACHE-HITS * 100) /
                       (WS-CACHE-HITS + WS-CACHE-MISSES)
                   DISPLAY "  Hit Rate:     " WS-TEMP-POS "%"
               END-IF
           END-IF.
           IF WS-ERROR-COUNT > 0
               DISPLAY "  Errors:       " WS-ERROR-COUNT
           END-IF.
           DISPLAY SPACES.
