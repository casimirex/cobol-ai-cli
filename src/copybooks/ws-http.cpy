      *>================================================================*
      *> WORKING-STORAGE: HTTP client and JSON parsing
      *>
      *> Request/response buffers, helper command, JSON scan cursors.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

      *> SECTION: HTTP CLIENT
      *>================================================================*
       01 WS-HTTP-REQUEST       PIC X(10000) VALUE SPACES.
       01 WS-HTTP-RESPONSE      PIC X(50000) VALUE SPACES.
       01 WS-HTTP-STATUS        PIC S9(4) COMP VALUE 0.

       01 WS-RESPONSE-FILE      PIC X(200) VALUE SPACES.
       01 WS-FILE-STATUS        PIC XX VALUE SPACES.
       01 WS-TIME-VALUE         PIC X(14) VALUE SPACES.

       01 WS-HELPER-SCRIPT      PIC X(200) VALUE SPACES.
       01 WS-HELPER-PROBE-STATUS PIC XX VALUE SPACES.
       01 WS-HELPER-CMD         PIC X(5000) VALUE SPACES.

      *>================================================================*
      *> SECTION: JSON PARSING
      *>================================================================*
       01 WS-JSON-PAYLOAD       PIC X(5000) VALUE SPACES.
       01 WS-JSON-EXTRACTED     PIC X(25000) VALUE SPACES.

       01 WS-JSON-I            PIC 9(5) VALUE 0.
       01 WS-JSON-J            PIC 9(5) VALUE 0.
       01 WS-JSON-START        PIC 9(5) VALUE 0.
       01 WS-JSON-LEN          PIC 9(5) VALUE 0.
       01 WS-JSON-QUOTE        PIC X VALUE QUOTE.
       01 WS-JSON-FOUND        PIC X VALUE "N".
          88 JSON-FOUND        VALUE "Y".
          88 JSON-NOT-FOUND    VALUE "N".

      *>================================================================*
