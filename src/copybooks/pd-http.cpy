      *>================================================================*
      *> PROCEDURE: HTTP client, retry and response parsing
      *>
      *> Payload building, the retry loop, status classification, JSON parsing.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

       BUILD-JSON-PAYLOAD.
           MOVE FUNCTION TRIM(WS-PROMPT) TO WS-PROMPT-TRIMMED.
           MOVE SPACES TO WS-JSON-PAYLOAD.
           STRING '{"model":"'
                  DELIMITED BY SIZE
                  FUNCTION TRIM(WS-MODEL) DELIMITED BY SIZE
                  '","prompt":"'
                  DELIMITED BY SIZE
                  WS-PROMPT-TRIMMED DELIMITED BY SIZE
                  '","stream":false}'
                  DELIMITED BY SIZE
               INTO WS-JSON-PAYLOAD
           END-STRING.

       CALL-API-WITH-SPINNER.
      *> Phase 4: Retry logic with exponential backoff
           MOVE 0 TO WS-CURRENT-RETRY.
           MOVE "N" TO WS-JSON-FOUND.
           MOVE "N" TO WS-FATAL-ERROR.
           MOVE 0 TO WS-RETRY-DELAY.

           PERFORM UNTIL WS-CURRENT-RETRY > WS-MAX-RETRIES
               OR WS-JSON-FOUND = "Y"
               OR FATAL-ERROR
               IF WS-CURRENT-RETRY > 0 THEN
                   DISPLAY SPACES
                   DISPLAY "  [RETRY] Attempt " WS-CURRENT-RETRY " of " WS-MAX-RETRIES
                   DISPLAY "  Reason: " WS-RETRY-REASON
                   DISPLAY "  Waiting..."
                   PERFORM WAIT-RETRY-DELAY
               END-IF
               DISPLAY SPACES
               DISPLAY "[SEND] Sending request to Ollama API..."
               DISPLAY SPACES
      *> Build helper command
               MOVE SPACES TO WS-HELPER-CMD
               PERFORM WRITE-PROMPT-FILE
               STRING "./cobol-ai-helper.sh --prompt-file '"
                      DELIMITED BY SIZE
                      FUNCTION TRIM(WS-PROMPT-FILE-NAME)
                          DELIMITED BY SIZE
                      "' '"
                      DELIMITED BY SIZE
                      FUNCTION TRIM(WS-MODEL) DELIMITED BY SIZE
                      "'"
                      DELIMITED BY SIZE
                   INTO WS-HELPER-CMD
               END-STRING
      *> Start spinner animation
               PERFORM START-SPINNER
      *> Execute API call
               CALL "SYSTEM" USING WS-HELPER-CMD
      *> Stop spinner
               PERFORM STOP-SPINNER
      *> Try to read and parse response
               PERFORM READ-HTTP-STATUS
               PERFORM PARSE-RESPONSE
      *> Check if we got a valid response
               IF WS-JSON-FOUND = "Y" THEN
                   DISPLAY "[OK] Request completed!"
                   DISPLAY SPACES
               ELSE
                   PERFORM CLASSIFY-HTTP-STATUS
                   IF NOT HTTP-RETRYABLE THEN
      *> A bad key or a bad URL will fail identically every time,
      *> so stop rather than burning the full backoff schedule.
                       MOVE "Y" TO WS-FATAL-ERROR
                       DISPLAY SPACES
                       CALL "SYSTEM" USING
                           "printf '\033[31m[ERR]\033[0m Request failed, not retrying'"
                       DISPLAY SPACES
                       DISPLAY "  " FUNCTION TRIM(WS-RETRY-REASON)
                       DISPLAY SPACES
                       PERFORM LOG-ERROR
                   ELSE
                       IF WS-CURRENT-RETRY >= WS-MAX-RETRIES THEN
                           MOVE "Y" TO WS-FATAL-ERROR
                           DISPLAY "[ERR] All retry attempts exhausted"
                           DISPLAY "  Last reason: "
                               FUNCTION TRIM(WS-RETRY-REASON)
                           DISPLAY SPACES
                           PERFORM LOG-ERROR
                       END-IF
                   END-IF
               END-IF
               ADD 1 TO WS-CURRENT-RETRY
           END-PERFORM.

       READ-HTTP-STATUS.
      *> Pick up the status the helper recorded for the last request
           MOVE 0 TO WS-LAST-HTTP-STATUS.
           MOVE SPACES TO WS-STATUS-TEXT.
           OPEN INPUT STATUS-FILE.
           IF WS-STATUS-FILE-STATUS NOT = "00"
               AND WS-STATUS-FILE-STATUS NOT = "05"
               EXIT PARAGRAPH
           END-IF.
           READ STATUS-FILE INTO WS-STATUS-TEXT
               AT END
                   MOVE SPACES TO WS-STATUS-TEXT
           END-READ.
           CLOSE STATUS-FILE.
           IF FUNCTION TRIM(WS-STATUS-TEXT) NOT = SPACES
              AND FUNCTION TRIM(WS-STATUS-TEXT) IS NUMERIC
               COMPUTE WS-LAST-HTTP-STATUS =
                   FUNCTION NUMVAL(WS-STATUS-TEXT)
           END-IF.

       CLASSIFY-HTTP-STATUS.
      *> Decide whether another attempt could possibly succeed
           MOVE "N" TO WS-HTTP-RETRYABLE.
           MOVE SPACES TO WS-RETRY-REASON.
           EVALUATE TRUE
               WHEN WS-LAST-HTTP-STATUS = 0
                   MOVE "Y" TO WS-HTTP-RETRYABLE
                   MOVE ERR-NETWORK TO WS-LAST-ERROR-CODE
                   MOVE "Could not reach the API (network, DNS or timeout)"
                       TO WS-RETRY-REASON
               WHEN WS-LAST-HTTP-STATUS = 200
      *> Reached the API but the body was unusable - could be transient
                   MOVE "Y" TO WS-HTTP-RETRYABLE
                   MOVE ERR-PARSE TO WS-LAST-ERROR-CODE
                   MOVE "HTTP 200 but no response field in the JSON"
                       TO WS-RETRY-REASON
               WHEN WS-LAST-HTTP-STATUS = 429
                   MOVE "Y" TO WS-HTTP-RETRYABLE
                   MOVE ERR-API TO WS-LAST-ERROR-CODE
                   MOVE "HTTP 429 rate limited - backing off"
                       TO WS-RETRY-REASON
               WHEN WS-LAST-HTTP-STATUS >= 500
                   MOVE "Y" TO WS-HTTP-RETRYABLE
                   MOVE ERR-API TO WS-LAST-ERROR-CODE
                   MOVE "HTTP 5xx server error - retrying"
                       TO WS-RETRY-REASON
               WHEN WS-LAST-HTTP-STATUS = 401
                   MOVE ERR-INVALID-CONFIG TO WS-LAST-ERROR-CODE
                   MOVE "HTTP 401 unauthorized - check AI_OLLAMA_API_KEY"
                       TO WS-RETRY-REASON
               WHEN WS-LAST-HTTP-STATUS = 403
                   MOVE ERR-INVALID-CONFIG TO WS-LAST-ERROR-CODE
                   MOVE "HTTP 403 forbidden - key lacks access to this model"
                       TO WS-RETRY-REASON
               WHEN WS-LAST-HTTP-STATUS = 404
                   MOVE ERR-INVALID-CONFIG TO WS-LAST-ERROR-CODE
                   MOVE "HTTP 404 not found - check AI_OLLAMA_BASE_URL and model"
                       TO WS-RETRY-REASON
               WHEN WS-LAST-HTTP-STATUS >= 400
                   MOVE ERR-API TO WS-LAST-ERROR-CODE
                   MOVE "HTTP 4xx client error - the request was rejected"
                       TO WS-RETRY-REASON
               WHEN OTHER
                   MOVE "Y" TO WS-HTTP-RETRYABLE
                   MOVE ERR-API TO WS-LAST-ERROR-CODE
                   MOVE "Unexpected HTTP status" TO WS-RETRY-REASON
           END-EVALUATE.
           MOVE FUNCTION TRIM(WS-RETRY-REASON) TO WS-LAST-ERROR-MSG.

       WAIT-RETRY-DELAY.
      *> Wait for retry delay (simplified - uses shell sleep)
           MOVE SPACES TO WS-TEMP-STRING
           COMPUTE WS-RETRY-DELAY = WS-BASE-DELAY *
               (2 ** WS-CURRENT-RETRY)
           IF WS-RETRY-DELAY > WS-MAX-DELAY
               MOVE WS-MAX-DELAY TO WS-RETRY-DELAY
           END-IF
           COMPUTE WS-TEMP-POS = WS-RETRY-DELAY / 1000
           IF WS-TEMP-POS < 1
               MOVE 1 TO WS-TEMP-POS
           END-IF
           MOVE WS-TEMP-POS TO WS-TEMP-STRING
           STRING "sleep " DELIMITED BY SIZE
                  WS-TEMP-STRING DELIMITED BY SIZE
               INTO WS-HELPER-CMD
           END-STRING
           CALL "SYSTEM" USING WS-HELPER-CMD.

       PARSE-RESPONSE.
      *> Read response file
           MOVE "/tmp/cobol-ai-response.json"
               TO WS-RESPONSE-FILE.
           OPEN INPUT RESPONSE-FILE.
           IF WS-FILE-STATUS NOT = "00"
               CALL "SYSTEM" USING
                   "printf '\033[31m[ERR]\033[0m Could not read response file'"
               EXIT PARAGRAPH
           END-IF.
           READ RESPONSE-FILE INTO WS-HTTP-RESPONSE.
           CLOSE RESPONSE-FILE.

      *> Get response length with colored output (magenta)
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-HTTP-RESPONSE))
               TO WS-RESPONSE-LEN.
           CALL "SYSTEM" USING
               "printf '\033[35m[RECV]\033[0m Response received ('".
           DISPLAY WS-RESPONSE-LEN " bytes)".

      *> Find "response" field in JSON
           MOVE SPACES TO WS-JSON-EXTRACTED.
           MOVE "N" TO WS-JSON-FOUND.
           MOVE 1 TO WS-JSON-I.

           PERFORM VARYING WS-JSON-I FROM 1 BY 1
               UNTIL WS-JSON-I > WS-RESPONSE-LEN - 10
               IF WS-HTTP-RESPONSE(WS-JSON-I:10) = '"response"'
                   MOVE "Y" TO WS-JSON-FOUND
                   ADD 12 TO WS-JSON-I
                   MOVE WS-JSON-I TO WS-JSON-START
                   PERFORM VARYING WS-JSON-J FROM WS-JSON-I BY 1
                       UNTIL WS-JSON-J > WS-RESPONSE-LEN
      *> Check for closing quote (but not escaped quote \")
                       IF WS-HTTP-RESPONSE(WS-JSON-J:1) = WS-JSON-QUOTE
      *> Check if this quote is escaped (preceded by backslash)
                           IF WS-JSON-J > WS-JSON-START
                           AND WS-HTTP-RESPONSE(WS-JSON-J - 1:1) = "\"
      *> This is an escaped quote, continue searching
                               CONTINUE
                           ELSE
      *> Found the real closing quote
                               COMPUTE WS-JSON-LEN = WS-JSON-J - WS-JSON-START
                               IF WS-JSON-LEN > 0 AND WS-JSON-LEN < 25000
                                   MOVE WS-HTTP-RESPONSE(
                                       WS-JSON-START:WS-JSON-LEN)
                                       TO WS-JSON-EXTRACTED
                               END-IF
                               EXIT PERFORM
                           END-IF
                       END-IF
                   END-PERFORM
                   EXIT PERFORM
               END-IF
           END-PERFORM.

      *> Check for error in response
           IF WS-JSON-FOUND = "N"
               PERFORM CHECK-ERROR-FIELD
           END-IF.

       CHECK-ERROR-FIELD.
      *> Check for "error" field in response
           PERFORM VARYING WS-JSON-I FROM 1 BY 1
               UNTIL WS-JSON-I > WS-RESPONSE-LEN - 7
               IF WS-HTTP-RESPONSE(WS-JSON-I:7) = '"error"'
                   ADD 10 TO WS-JSON-I
                   MOVE WS-JSON-I TO WS-JSON-START
                   PERFORM VARYING WS-JSON-J FROM WS-JSON-I BY 1
                       UNTIL WS-JSON-J > WS-RESPONSE-LEN
                       IF WS-HTTP-RESPONSE(WS-JSON-J:1) = WS-JSON-QUOTE
                           COMPUTE WS-JSON-LEN = WS-JSON-J - WS-JSON-START
                           IF WS-JSON-LEN > 0
                               DISPLAY "API Error: "
                                   WS-HTTP-RESPONSE(
                                   WS-JSON-START:WS-JSON-LEN)
                           END-IF
                           EXIT PERFORM
                       END-IF
                   END-PERFORM
                   EXIT PERFORM
               END-IF
           END-PERFORM.

      *>================================================================*
      *> SECTION: RESPONSE CACHING (Phase 4)
      *>================================================================*
