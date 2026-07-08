       IDENTIFICATION DIVISION.
       PROGRAM-ID. RESPONSE-FORMATTER.

      *> RESPONSE-FORMATTER Module
      *> Output formatting for COBOL AI CLI

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *> Formatting constants
       01 WS-PREFIX            PIC X(15) VALUE "AI: ".
       01 WS-FMT-ERROR-PREFIX  PIC X(15) VALUE "ERROR: ".
       01 WS-DIVIDER           PIC X(50) VALUE
           "--------------------------------------------------".

      *> Response data
       01 WS-RESPONSE-TEXT     PIC X(5000) VALUE SPACES.
       01 WS-UNESCAPED        PIC X(5000) VALUE SPACES.

      *> Display options
       01 WS-SHOW-METADATA     PIC X VALUE "N".
          88 SHOW-METADATA VALUE "Y".
          88 HIDE-METADATA VALUE "N".

       LINKAGE SECTION.
       01 LS-RESPONSE          PIC X(5000).
       01 LS-MODEL             PIC X(50).
       01 LS-ERROR-MSG         PIC X(200).

       PROCEDURE DIVISION.

      *> INIT-RESPONSE-FORMATTER - Initialize formatter
       ENTRY "INIT-RESPONSE-FORMATTER".
           MOVE "N" TO WS-SHOW-METADATA.

      *> DISPLAY-RESPONSE - Display formatted AI response
       ENTRY "DISPLAY-RESPONSE" USING LS-RESPONSE.

      *> Display divider
           DISPLAY WS-DIVIDER.

      *> Display prefix and response
           MOVE LS-RESPONSE TO WS-RESPONSE-TEXT.
           DISPLAY WS-PREFIX FUNCTION TRIM(WS-RESPONSE-TEXT).

      *> Display closing divider
           DISPLAY WS-DIVIDER.

      *> DISPLAY-FORMAT-ERROR - Display formatted error message
       ENTRY "DISPLAY-FORMAT-ERROR" USING LS-ERROR-MSG.
           DISPLAY WS-FMT-ERROR-PREFIX LS-ERROR-MSG.

      *> ENABLE-METADATA - Enable metadata display
       ENTRY "ENABLE-METADATA".
           MOVE "Y" TO WS-SHOW-METADATA.

      *> DISABLE-METADATA - Disable metadata display
       ENTRY "DISABLE-METADATA".
           MOVE "N" TO WS-SHOW-METADATA.

      *> DISPLAY-SIMPLE - Display response without formatting
       ENTRY "DISPLAY-SIMPLE" USING LS-RESPONSE.
           DISPLAY WS-PREFIX LS-RESPONSE.

       END PROGRAM RESPONSE-FORMATTER.