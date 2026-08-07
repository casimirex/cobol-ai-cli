      *>================================================================*
      *> WORKING-STORAGE: Error handling
      *>
      *> Last-error state and the error code constants.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

      *> SECTION: ERROR HANDLING (Phase 4)
      *>================================================================*
       01 WS-ERROR-STATE.
          05 WS-LAST-ERROR-CODE   PIC S9(4) COMP VALUE 0.
          05 WS-LAST-ERROR-MSG    PIC X(200) VALUE SPACES.
          05 WS-ERROR-COUNT       PIC 9(4) VALUE 0.
          05 WS-FATAL-ERROR       PIC X VALUE "N".
             88 FATAL-ERROR       VALUE "Y".
             88 NO-FATAL-ERROR    VALUE "N".

       01 WS-ERROR-FILE-NAME    PIC X(200) VALUE SPACES.
       01 WS-ERROR-FILE-STATUS  PIC XX VALUE SPACES.
       01 WS-ERROR-CODE-DISP    PIC -9(4) VALUE 0.

       01 WS-ERROR-CODES.
          05 ERR-OK               PIC S9(4) COMP VALUE 0.
          05 ERR-INVALID-CONFIG   PIC S9(4) COMP VALUE 1.
          05 ERR-NETWORK          PIC S9(4) COMP VALUE 2.
          05 ERR-API              PIC S9(4) COMP VALUE 3.
          05 ERR-PARSE            PIC S9(4) COMP VALUE 4.
          05 ERR-CACHE            PIC S9(4) COMP VALUE 5.
          05 ERR-TIMEOUT          PIC S9(4) COMP VALUE 6.
          05 ERR-RETRY-EXHAUSTED  PIC S9(4) COMP VALUE 7.
          05 ERR-FILE-IO          PIC S9(4) COMP VALUE 8.

      *>================================================================*
