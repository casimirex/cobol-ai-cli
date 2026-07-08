       IDENTIFICATION DIVISION.
       PROGRAM-ID. ERROR-HANDLER.

      *> ERROR-HANDLER Module
      *> Centralized error handling for COBOL AI CLI
      *> Error Codes:
      *>   0000 - Success (no error)
      *>   1000 - Configuration errors
      *>   2000 - HTTP/Network errors
      *>   3000 - JSON parsing errors
      *>   4000 - Input validation errors
      *>   5000 - System errors

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *> Error code definitions
       01 WS-ERROR-CODES.
          05 EC-SUCCESS          PIC 9(4) VALUE 0000.
          05 EC-CONFIG-MISSING   PIC 9(4) VALUE 1001.
          05 EC-CONFIG-INVALID   PIC 9(4) VALUE 1002.
          05 EC-HTTP-REQUEST     PIC 9(4) VALUE 2001.
          05 EC-HTTP-RESPONSE    PIC 9(4) VALUE 2002.
          05 EC-HTTP-TIMEOUT     PIC 9(4) VALUE 2003.
          05 EC-JSON-PARSE       PIC 9(4) VALUE 3001.
          05 EC-JSON-BUILD       PIC 9(4) VALUE 3002.
          05 EC-INPUT-EMPTY      PIC 9(4) VALUE 4001.
          05 EC-INPUT-TOO-LONG   PIC 9(4) VALUE 4002.
          05 EC-SYSTEM-ERROR    PIC 9(4) VALUE 5001.

      *> Error messages
       01 WS-ERROR-MESSAGES.
          05 EM-SUCCESS          PIC X(100) VALUE
             "Success".
          05 EM-CONFIG-MISSING   PIC X(100) VALUE
             "Configuration error: Missing required environment variable".
          05 EM-CONFIG-INVALID   PIC X(100) VALUE
             "Configuration error: Invalid configuration value".
          05 EM-HTTP-REQUEST     PIC X(100) VALUE
             "HTTP error: Failed to send request to API".
          05 EM-HTTP-RESPONSE    PIC X(100) VALUE
             "HTTP error: Invalid response from API".
          05 EM-HTTP-TIMEOUT     PIC X(100) VALUE
             "HTTP error: Request timed out".
          05 EM-JSON-PARSE       PIC X(100) VALUE
             "JSON error: Failed to parse JSON response".
          05 EM-JSON-BUILD       PIC X(100) VALUE
             "JSON error: Failed to build JSON payload".
          05 EM-INPUT-EMPTY      PIC X(100) VALUE
             "Input error: Prompt cannot be empty".
          05 EM-INPUT-TOO-LONG   PIC X(100) VALUE
             "Input error: Prompt exceeds maximum length".
          05 EM-SYSTEM-ERROR     PIC X(100) VALUE
             "System error: Internal error occurred".

      *> Working variables
       01 WS-CURRENT-ERROR-CODE  PIC 9(4) VALUE 0000.
       01 WS-ERROR-DETAIL         PIC X(200) VALUE SPACES.
       01 WS-FORMATTED-MSG        PIC X(300) VALUE SPACES.

       LINKAGE SECTION.
       01 LS-ERROR-CODE          PIC 9(4).
       01 LS-ERROR-MESSAGE       PIC X(300).
       01 LS-ERROR-DETAIL-IN     PIC X(200).

       PROCEDURE DIVISION.

      *> Main entry point - Initialize error handler
       ENTRY "INIT-ERROR-HANDLER".
           MOVE 0 TO WS-CURRENT-ERROR-CODE.
           MOVE SPACES TO WS-ERROR-DETAIL.

      *> GET-ERROR - Retrieve error message by code
      *> Input:  LS-ERROR-CODE - Error code
      *> Output: LS-ERROR-MESSAGE - Formatted error message
       ENTRY "GET-ERROR" USING LS-ERROR-CODE LS-ERROR-MESSAGE.
           EVALUATE LS-ERROR-CODE
               WHEN 0000
                   MOVE EM-SUCCESS TO LS-ERROR-MESSAGE
               WHEN 1001
                   MOVE EM-CONFIG-MISSING TO LS-ERROR-MESSAGE
               WHEN 1002
                   MOVE EM-CONFIG-INVALID TO LS-ERROR-MESSAGE
               WHEN 2001
                   MOVE EM-HTTP-REQUEST TO LS-ERROR-MESSAGE
               WHEN 2002
                   MOVE EM-HTTP-RESPONSE TO LS-ERROR-MESSAGE
               WHEN 2003
                   MOVE EM-HTTP-TIMEOUT TO LS-ERROR-MESSAGE
               WHEN 3001
                   MOVE EM-JSON-PARSE TO LS-ERROR-MESSAGE
               WHEN 3002
                   MOVE EM-JSON-BUILD TO LS-ERROR-MESSAGE
               WHEN 4001
                   MOVE EM-INPUT-EMPTY TO LS-ERROR-MESSAGE
               WHEN 4002
                   MOVE EM-INPUT-TOO-LONG TO LS-ERROR-MESSAGE
               WHEN 5001
                   MOVE EM-SYSTEM-ERROR TO LS-ERROR-MESSAGE
               WHEN OTHER
                   STRING "Unknown error code: "
                          DELIMITED BY SIZE
                          LS-ERROR-CODE DELIMITED BY SIZE
                          INTO LS-ERROR-MESSAGE
           END-EVALUATE.

      *> SET-ERROR - Set current error with optional detail
      *> Input:  LS-ERROR-CODE - Error code
      *>         LS-ERROR-DETAIL-IN - Additional error details
       ENTRY "SET-ERROR" USING LS-ERROR-CODE LS-ERROR-DETAIL-IN.
           MOVE LS-ERROR-CODE TO WS-CURRENT-ERROR-CODE.
           MOVE LS-ERROR-DETAIL-IN TO WS-ERROR-DETAIL.
           CALL "GET-ERROR" USING WS-CURRENT-ERROR-CODE WS-FORMATTED-MSG.
           IF WS-ERROR-DETAIL NOT = SPACES
               STRING WS-FORMATTED-MSG DELIMITED BY SPACE
                      " - " DELIMITED BY SIZE
                      WS-ERROR-DETAIL DELIMITED BY SPACE
                      INTO WS-FORMATTED-MSG
           END-IF.

      *> DISPLAY-ERROR - Print error to console
      *> Input:  LS-ERROR-CODE - Error code
      *>         LS-ERROR-DETAIL-IN - Additional details (optional)
       ENTRY "DISPLAY-ERROR" USING LS-ERROR-CODE LS-ERROR-DETAIL-IN.
           CALL "SET-ERROR" USING LS-ERROR-CODE LS-ERROR-DETAIL-IN.
           DISPLAY "ERROR: " WS-FORMATTED-MSG.

      *> IS-ERROR - Check if error code indicates an error
      *> Input:  LS-ERROR-CODE - Error code to check
      *> Output: LS-ERROR-MESSAGE - "YES" or "NO"
       ENTRY "IS-ERROR" USING LS-ERROR-CODE LS-ERROR-MESSAGE.
           IF LS-ERROR-CODE = 0000
               MOVE "NO" TO LS-ERROR-MESSAGE
           ELSE
               MOVE "YES" TO LS-ERROR-MESSAGE
           END-IF.

      *> GET-CURRENT-ERROR - Get last set error
      *> Output: LS-ERROR-CODE - Current error code
      *>         LS-ERROR-MESSAGE - Current error message
       ENTRY "GET-CURRENT-ERROR" USING LS-ERROR-CODE LS-ERROR-MESSAGE.
           MOVE WS-CURRENT-ERROR-CODE TO LS-ERROR-CODE.
           CALL "GET-ERROR" USING WS-CURRENT-ERROR-CODE LS-ERROR-MESSAGE.

       END PROGRAM ERROR-HANDLER.