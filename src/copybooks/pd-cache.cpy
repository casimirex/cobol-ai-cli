      *>================================================================*
      *> PROCEDURE: Response cache
      *>
      *> Key building, lookup, storage, persistence and clearing.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

       BUILD-CACHE-KEY.
      *> Build the lookup key from model + prompt, then reduce it to a
      *> 64-char fingerprint held in WS-CACHE-HASH.
      *> WS-CACHE-HASH is scratch storage only - it must never be a table
      *> slot, or a lookup would compare an entry against itself.
      *> Key on the composed prompt, so attaching a different file to the
      *> same question produces a different cache entry.
           MOVE SPACES TO WS-CACHE-KEY.
           STRING FUNCTION TRIM(WS-MODEL) "|"
               FUNCTION TRIM(WS-FULL-PROMPT)
               DELIMITED BY SIZE INTO WS-CACHE-KEY.

      *> Rolling polynomial hash over the whole key so that prompts
      *> sharing a prefix do not collide.
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-CACHE-KEY))
               TO WS-HASH-KEY-LEN.
           MOVE 0 TO WS-HASH-ACC.
           PERFORM VARYING WS-HASH-POS FROM 1 BY 1
               UNTIL WS-HASH-POS > WS-HASH-KEY-LEN
               COMPUTE WS-HASH-ACC = FUNCTION MOD(
                   (WS-HASH-ACC * 31)
                   + FUNCTION ORD(WS-CACHE-KEY(WS-HASH-POS:1)),
                   999999937)
           END-PERFORM.

      *> Fingerprint = 12-digit hash + 4-digit length + first 48 chars
           MOVE WS-HASH-ACC TO WS-HASH-ACC-DISP.
           MOVE WS-HASH-KEY-LEN TO WS-HASH-LEN-DISP.
           MOVE SPACES TO WS-CACHE-HASH.
           STRING WS-HASH-ACC-DISP
                  WS-HASH-LEN-DISP
                  WS-CACHE-KEY(1:48)
               DELIMITED BY SIZE INTO WS-CACHE-HASH.

      *> The literal tail is kept for readability, but an attached file
      *> puts newlines in it, and a newline inside a LINE SEQUENTIAL
      *> record splits it across lines and destroys the entry on reload.
           INSPECT WS-CACHE-HASH REPLACING ALL X"0A" BY ".".
           INSPECT WS-CACHE-HASH REPLACING ALL X"0D" BY ".".
           INSPECT WS-CACHE-HASH REPLACING ALL X"09" BY ".".

       CHECK-RESPONSE-CACHE.
      *> Check if response exists in cache
           MOVE "N" TO WS-CACHE-FOUND.
           IF CACHE-DISABLED
               EXIT PARAGRAPH
           END-IF.

           PERFORM BUILD-CACHE-KEY.

      *> Search cache table
           PERFORM VARYING WS-CACHE-INDEX FROM 1 BY 1
               UNTIL WS-CACHE-INDEX > WS-CACHE-COUNT
               OR CACHE-FOUND
               IF WS-CACHE-VALID(WS-CACHE-INDEX) = "Y"
                   AND WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX) =
                       WS-CACHE-HASH
                   MOVE "Y" TO WS-CACHE-FOUND
                   MOVE WS-CACHE-RESPONSE(WS-CACHE-INDEX)
                       TO WS-JSON-EXTRACTED
                   MOVE "Y" TO WS-JSON-FOUND
               END-IF
           END-PERFORM.

       CACHE-RESPONSE.
      *> Store response in cache after successful API call
           IF CACHE-DISABLED
               EXIT PARAGRAPH
           END-IF.

           IF WS-JSON-FOUND = "N"
               EXIT PARAGRAPH
           END-IF.

      *> Check if cache is full
           IF WS-CACHE-COUNT >= WS-CACHE-MAX
      *> Remove oldest entry (shift down)
               PERFORM VARYING WS-CACHE-INDEX FROM 1 BY 1
                   UNTIL WS-CACHE-INDEX >= WS-CACHE-MAX
                   MOVE WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX + 1)
                       TO WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX)
                   MOVE WS-CACHE-RESPONSE(WS-CACHE-INDEX + 1)
                       TO WS-CACHE-RESPONSE(WS-CACHE-INDEX)
                   MOVE WS-CACHE-TIMESTAMP(WS-CACHE-INDEX + 1)
                       TO WS-CACHE-TIMESTAMP(WS-CACHE-INDEX)
                   MOVE WS-CACHE-VALID(WS-CACHE-INDEX + 1)
                       TO WS-CACHE-VALID(WS-CACHE-INDEX)
               END-PERFORM
               MOVE WS-CACHE-COUNT TO WS-CACHE-INDEX
           ELSE
               ADD 1 TO WS-CACHE-COUNT
               MOVE WS-CACHE-COUNT TO WS-CACHE-INDEX
           END-IF.

      *> Store cache entry - WS-CACHE-HASH was set by CHECK-RESPONSE-CACHE
      *> for this same prompt, so reuse it rather than rebuilding.
           MOVE WS-CACHE-HASH TO WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX).
           MOVE WS-JSON-EXTRACTED TO WS-CACHE-RESPONSE(WS-CACHE-INDEX).
           MOVE FUNCTION CURRENT-DATE(1:14)
               TO WS-CACHE-TIMESTAMP(WS-CACHE-INDEX).
           MOVE "Y" TO WS-CACHE-VALID(WS-CACHE-INDEX).

      *>================================================================*
      *> SECTION: CACHE PERSISTENCE
      *>================================================================*
       LOAD-RESPONSE-CACHE.
      *> Repopulate the cache table from disk so hits survive across runs
           MOVE 0 TO WS-CACHE-COUNT.
           MOVE 0 TO WS-CACHE-LOADED.
           IF CACHE-DISABLED
               EXIT PARAGRAPH
           END-IF.

           COMPUTE WS-CACHE-TODAY-INT = FUNCTION INTEGER-OF-DATE(
               FUNCTION NUMVAL(FUNCTION CURRENT-DATE(1:8))).

           OPEN INPUT CACHE-FILE.
           IF WS-CACHE-STATUS NOT = "00"
      *> No cache file yet (first run) - start empty, not an error
               EXIT PARAGRAPH
           END-IF.

           PERFORM UNTIL WS-CACHE-STATUS NOT = "00"
               OR WS-CACHE-COUNT >= WS-CACHE-MAX
               READ CACHE-FILE
                   AT END
                       MOVE "99" TO WS-CACHE-STATUS
                   NOT AT END
                       MOVE CACHE-RECORD TO WS-CACHE-REC
                       PERFORM ACCEPT-CACHE-RECORD
               END-READ
           END-PERFORM.
           CLOSE CACHE-FILE.

       ACCEPT-CACHE-RECORD.
      *> Add one on-disk record to the table if it is valid and fresh
           IF WS-CR-VALID NOT = "Y"
               EXIT PARAGRAPH
           END-IF.
           IF WS-CR-HASH = SPACES OR WS-CR-RESPONSE = SPACES
               EXIT PARAGRAPH
           END-IF.
           IF WS-CR-TIMESTAMP(1:8) NOT NUMERIC
               EXIT PARAGRAPH
           END-IF.

      *> Drop entries older than the TTL
           COMPUTE WS-CACHE-DATE-INT = FUNCTION INTEGER-OF-DATE(
               FUNCTION NUMVAL(WS-CR-TIMESTAMP(1:8))).
           IF WS-CACHE-TODAY-INT - WS-CACHE-DATE-INT > WS-CACHE-TTL-DAYS
               EXIT PARAGRAPH
           END-IF.

           ADD 1 TO WS-CACHE-COUNT.
           MOVE WS-CR-HASH TO WS-CACHE-PROMPT-HASH(WS-CACHE-COUNT).
           MOVE WS-CR-RESPONSE TO WS-CACHE-RESPONSE(WS-CACHE-COUNT).
           MOVE WS-CR-TIMESTAMP TO WS-CACHE-TIMESTAMP(WS-CACHE-COUNT).
           MOVE "Y" TO WS-CACHE-VALID(WS-CACHE-COUNT).
           ADD 1 TO WS-CACHE-LOADED.

       SAVE-RESPONSE-CACHE.
      *> Flush the in-memory table back to disk on exit
           IF CACHE-DISABLED OR WS-CACHE-COUNT = 0
               EXIT PARAGRAPH
           END-IF.

           OPEN OUTPUT CACHE-FILE.
           IF WS-CACHE-STATUS NOT = "00"
               EXIT PARAGRAPH
           END-IF.

           PERFORM VARYING WS-CACHE-INDEX FROM 1 BY 1
               UNTIL WS-CACHE-INDEX > WS-CACHE-COUNT
               IF WS-CACHE-VALID(WS-CACHE-INDEX) = "Y"
                   AND WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX) NOT = SPACES
      *> A literal newline would split the record across two lines
                   MOVE 0 TO WS-CACHE-NL-COUNT
                   INSPECT WS-CACHE-RESPONSE(WS-CACHE-INDEX)
                       TALLYING WS-CACHE-NL-COUNT FOR ALL X"0A"
                   IF WS-CACHE-NL-COUNT = 0
                       MOVE WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX)
                           TO WS-CR-HASH
                       MOVE WS-CACHE-TIMESTAMP(WS-CACHE-INDEX)
                           TO WS-CR-TIMESTAMP
                       MOVE "Y" TO WS-CR-VALID
                       MOVE WS-CACHE-RESPONSE(WS-CACHE-INDEX)
                           TO WS-CR-RESPONSE
                       MOVE WS-CACHE-REC TO CACHE-RECORD
                       WRITE CACHE-RECORD
                   END-IF
               END-IF
           END-PERFORM.
           CLOSE CACHE-FILE.

       CLEAR-RESPONSE-CACHE.
      *> Drop every entry, in memory and on disk
           MOVE 0 TO WS-CACHE-COUNT.
           PERFORM VARYING WS-CACHE-INDEX FROM 1 BY 1
               UNTIL WS-CACHE-INDEX > WS-CACHE-MAX
               MOVE SPACES TO WS-CACHE-PROMPT-HASH(WS-CACHE-INDEX)
               MOVE SPACES TO WS-CACHE-RESPONSE(WS-CACHE-INDEX)
               MOVE SPACES TO WS-CACHE-TIMESTAMP(WS-CACHE-INDEX)
               MOVE "N" TO WS-CACHE-VALID(WS-CACHE-INDEX)
           END-PERFORM.
           MOVE SPACES TO WS-PATH-CMD
           STRING "rm -f '" FUNCTION TRIM(WS-CACHE-FILE) "'"
               DELIMITED BY SIZE INTO WS-PATH-CMD
           CALL "SYSTEM" USING WS-PATH-CMD.
           DISPLAY SPACES.
           CALL "SYSTEM" USING
               "printf '\033[32m[OK]\033[0m Response cache cleared'".
           DISPLAY SPACES.
