       IDENTIFICATION DIVISION.
       PROGRAM-ID. JSON-PARSER.

      *> JSON-PARSER Module
      *> JSON utilities for COBOL AI CLI

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *> JSON strings
       01 WS-JSON-PAYLOAD       PIC X(2000) VALUE SPACES.
       01 WS-JSON-RESPONSE      PIC X(10000) VALUE SPACES.
       01 WS-EXTRACTED-VALUE    PIC X(5000) VALUE SPACES.

      *> Parsing variables
       01 WS-I                  PIC 9(5).
       01 WS-J                  PIC 9(5).
       01 WS-START              PIC 9(5).
       01 WS-LEN                PIC 9(5).
       01 WS-KEY-NAME           PIC X(50).

      *> Quote character
       01 WS-QUOTE-CHAR         PIC X VALUE QUOTE.

       LINKAGE SECTION.
       01 LS-MODEL              PIC X(50).
       01 LS-PROMPT             PIC X(1000).
       01 LS-PAYLOAD            PIC X(2000).
       01 LS-JSON-STRING        PIC X(10000).
       01 LS-FIELD-NAME         PIC X(50).
       01 LS-FIELD-VALUE        PIC X(5000).
       01 LS-ERROR-CODE         PIC 9(4).

       PROCEDURE DIVISION.

      *> BUILD-REQUEST-PAYLOAD - Create JSON request for Ollama API
       ENTRY "BUILD-REQUEST-PAYLOAD"
           USING LS-MODEL LS-PROMPT LS-PAYLOAD LS-ERROR-CODE.

           MOVE 0 TO LS-ERROR-CODE.
           MOVE SPACES TO LS-PAYLOAD.

      *> Build JSON: {"model": "xxx", "prompt": "xxx", "stream": false}
           STRING '{"model": "'
                  DELIMITED BY SIZE
                  FUNCTION TRIM(LS-MODEL)
                  DELIMITED BY SPACE
                  '", "prompt": "'
                  DELIMITED BY SIZE
                  FUNCTION TRIM(LS-PROMPT)
                  DELIMITED BY SPACE
                  '", "stream": false}'
                  DELIMITED BY SIZE
                  INTO LS-PAYLOAD
           END-STRING.

           IF LS-PAYLOAD = SPACES
               MOVE 3002 TO LS-ERROR-CODE
           END-IF.

      *> PARSE-RESPONSE - Extract response field from JSON
       ENTRY "PARSE-RESPONSE"
           USING LS-JSON-STRING LS-FIELD-VALUE LS-ERROR-CODE.

           MOVE 0 TO LS-ERROR-CODE.
           MOVE SPACES TO LS-FIELD-VALUE.
           MOVE LS-JSON-STRING TO WS-JSON-RESPONSE.

           PERFORM EXTRACT-RESPONSE-FIELD.

           IF WS-EXTRACTED-VALUE = SPACES
               MOVE 3001 TO LS-ERROR-CODE
           ELSE
               MOVE WS-EXTRACTED-VALUE TO LS-FIELD-VALUE
           END-IF.

       EXTRACT-RESPONSE-FIELD.
           MOVE SPACES TO WS-EXTRACTED-VALUE.

      *> Find "response": in JSON
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > FUNCTION LENGTH(WS-JSON-RESPONSE) - 10
               IF WS-JSON-RESPONSE(WS-I:10) = '"response"'
                   ADD 12 TO WS-I
                   MOVE WS-I TO WS-START
      *> Find closing quote
                   PERFORM VARYING WS-J FROM WS-I BY 1
                       UNTIL WS-J > FUNCTION LENGTH(WS-JSON-RESPONSE)
                       IF WS-JSON-RESPONSE(WS-J:1) = WS-QUOTE-CHAR
                           COMPUTE WS-LEN = WS-J - WS-START
                           IF WS-LEN > 0
                               MOVE WS-JSON-RESPONSE(WS-START:WS-LEN)
                                   TO WS-EXTRACTED-VALUE
                           END-IF
                           EXIT PERFORM
                       END-IF
                   END-PERFORM
                   EXIT PERFORM
               END-IF
           END-PERFORM.

      *> GET-ERROR-FIELD - Extract error field from JSON response
       ENTRY "GET-ERROR-FIELD"
           USING LS-JSON-STRING LS-FIELD-VALUE LS-ERROR-CODE.

           MOVE LS-JSON-STRING TO WS-JSON-RESPONSE.
           MOVE SPACES TO WS-EXTRACTED-VALUE.

      *> Find "error": in JSON
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > FUNCTION LENGTH(WS-JSON-RESPONSE) - 7
               IF WS-JSON-RESPONSE(WS-I:7) = '"error"'
                   ADD 9 TO WS-I
                   MOVE WS-I TO WS-START
      *> Find closing quote
                   PERFORM VARYING WS-J FROM WS-I BY 1
                       UNTIL WS-J > FUNCTION LENGTH(WS-JSON-RESPONSE)
                       IF WS-JSON-RESPONSE(WS-J:1) = WS-QUOTE-CHAR
                           COMPUTE WS-LEN = WS-J - WS-START
                           IF WS-LEN > 0
                               MOVE WS-JSON-RESPONSE(WS-START:WS-LEN)
                                   TO WS-EXTRACTED-VALUE
                           END-IF
                           EXIT PERFORM
                       END-IF
                   END-PERFORM
                   EXIT PERFORM
               END-IF
           END-PERFORM.

           IF WS-EXTRACTED-VALUE = SPACES
               MOVE 0 TO LS-ERROR-CODE
               MOVE SPACES TO LS-FIELD-VALUE
           ELSE
               MOVE 2002 TO LS-ERROR-CODE
               MOVE WS-EXTRACTED-VALUE TO LS-FIELD-VALUE
           END-IF.

       END PROGRAM JSON-PARSER.