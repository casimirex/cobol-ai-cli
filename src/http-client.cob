       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTTP-CLIENT.

      *> HTTP-CLIENT Module
      *> HTTP request handling for COBOL AI CLI via curl

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT RESPONSE-FILE ASSIGN TO WS-RESPONSE-FILE
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD RESPONSE-FILE.
       01 RESPONSE-LINE         PIC X(10000).

       WORKING-STORAGE SECTION.

      *> File status
       01 WS-FILE-STATUS        PIC XX VALUE SPACES.

      *> Command buffers
       01 WS-CURL-COMMAND       PIC X(3000) VALUE SPACES.
       01 WS-RESPONSE-FILE      PIC X(100) VALUE SPACES.

      *> Configuration
       01 WS-API-URL            PIC X(200) VALUE SPACES.
       01 WS-API-KEY            PIC X(200) VALUE SPACES.
       01 WS-TIMEOUT-MS         PIC 9(6) VALUE 60000.
       01 WS-TIMEOUT-SEC        PIC 9(4) VALUE 60.

      *> Exit code handling
       01 WS-EXIT-CODE          PIC S9(4) COMP.

      *> Response handling
       01 WS-RESPONSE-DATA      PIC X(10000) VALUE SPACES.
       01 WS-TEMP-FILE          PIC X(100) VALUE SPACES.
       01 WS-TIME-VALUE         PIC X(14) VALUE SPACES.

       LINKAGE SECTION.
       01 LS-API-URL            PIC X(200).
       01 LS-API-KEY            PIC X(200).
       01 LS-PAYLOAD            PIC X(2000).
       01 LS-RESPONSE           PIC X(10000).
       01 LS-TIMEOUT            PIC 9(6).
       01 LS-ERROR-CODE         PIC 9(4).

       PROCEDURE DIVISION.

      *> INIT-HTTP-CLIENT - Initialize HTTP client with config
       ENTRY "INIT-HTTP-CLIENT"
           USING LS-API-URL LS-API-KEY LS-TIMEOUT.

           MOVE LS-API-URL TO WS-API-URL.
           MOVE LS-API-KEY TO WS-API-KEY.
           MOVE LS-TIMEOUT TO WS-TIMEOUT-MS.

      *> Convert milliseconds to seconds for curl
           DIVIDE WS-TIMEOUT-MS BY 1000 GIVING WS-TIMEOUT-SEC ROUNDED.

      *> SEND-POST-REQUEST - Send POST request to API
       ENTRY "SEND-POST-REQUEST"
           USING LS-PAYLOAD LS-RESPONSE LS-ERROR-CODE.

           MOVE 0 TO LS-ERROR-CODE.
           MOVE SPACES TO LS-RESPONSE.
           MOVE SPACES TO WS-CURL-COMMAND.

      *> Generate unique response file
           ACCEPT WS-TIME-VALUE FROM TIME.
           STRING "/tmp/cobol-ai-response-"
                  DELIMITED BY SIZE
                  WS-TIME-VALUE DELIMITED BY SPACE
                  ".json"
                  DELIMITED BY SIZE
                  INTO WS-RESPONSE-FILE
           END-STRING.

      *> Build curl command
           STRING "curl -s -X POST "
                  DELIMITED BY SIZE
                  FUNCTION TRIM(WS-API-URL)
                  DELIMITED BY SPACE
                  "/api/generate -H 'Authorization: Bearer "
                  DELIMITED BY SIZE
                  FUNCTION TRIM(WS-API-KEY)
                  DELIMITED BY SPACE
                  "' -H 'Content-Type: application/json' -d '"
                  DELIMITED BY SIZE
                  FUNCTION TRIM(LS-PAYLOAD)
                  DELIMITED BY SPACE
                  "' -o "
                  DELIMITED BY SIZE
                  WS-RESPONSE-FILE DELIMITED BY SPACE
                  " --max-time "
                  DELIMITED BY SIZE
                  WS-TIMEOUT-SEC DELIMITED BY SIZE
                  INTO WS-CURL-COMMAND
           END-STRING.

      *> Execute curl command
           CALL "SYSTEM" USING WS-CURL-COMMAND
               RETURNING WS-EXIT-CODE.

      *> Check curl exit status
           IF WS-EXIT-CODE NOT = 0
               MOVE 2001 TO LS-ERROR-CODE
               EXIT PROGRAM
           END-IF.

      *> Read response from file
           OPEN INPUT RESPONSE-FILE.

           IF WS-FILE-STATUS NOT = "00"
               MOVE 2002 TO LS-ERROR-CODE
               EXIT PROGRAM
           END-IF.

           READ RESPONSE-FILE INTO WS-RESPONSE-DATA.
           CLOSE RESPONSE-FILE.

      *> Clean up temporary file
           STRING "rm -f "
                  DELIMITED BY SIZE
                  WS-RESPONSE-FILE DELIMITED BY SPACE
                  INTO WS-TEMP-FILE
           END-STRING.
           CALL "SYSTEM" USING WS-TEMP-FILE.

      *> Return response
           MOVE WS-RESPONSE-DATA TO LS-RESPONSE.

       END PROGRAM HTTP-CLIENT.