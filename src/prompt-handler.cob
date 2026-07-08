       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROMPT-HANDLER.

      *> PROMPT-HANDLER Module
      *> User input handling for COBOL AI CLI

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *> Input buffer
       01 WS-INPUT-BUFFER       PIC X(1000) VALUE SPACES.
       01 WS-INPUT-LENGTH       PIC 9(4) VALUE 0.

      *> Validation limits
       01 WS-MIN-PROMPT-LEN     PIC 9(4) VALUE 1.
       01 WS-MAX-PROMPT-LEN     PIC 9(4) VALUE 500.

      *> Command detection
       01 WS-COMMAND-TYPE       PIC X(20) VALUE SPACES.
          88 CMD-HELP VALUE "help".
          88 CMD-VERSION VALUE "version".
          88 CMD-EXIT VALUE "exit".
          88 CMD-QUIT VALUE "quit".
          88 CMD-CLEAR VALUE "clear".

      *> Trimmed input
       01 WS-TRIMMED            PIC X(1000) VALUE SPACES.

      *> Version info
       01 WS-VERSION-TEXT       PIC X(50) VALUE
           "COBOL AI CLI v1.0.0".

       LINKAGE SECTION.
       01 LS-PROMPT             PIC X(1000).
       01 LS-ERROR-CODE         PIC 9(4).
       01 LS-ARG-COUNT          PIC 9(4).
       01 LS-ARG-ARRAY.
          05 LS-ARG-ENTRY       PIC X(100) OCCURS 10 TIMES.

       PROCEDURE DIVISION.

      *> INIT-PROMPT-HANDLER - Initialize prompt handler
       ENTRY "INIT-PROMPT-HANDLER".
           MOVE SPACES TO WS-INPUT-BUFFER.
           MOVE 0 TO WS-INPUT-LENGTH.

      *> GET-PROMPT-INTERACTIVE - Get prompt from user interactively
       ENTRY "GET-PROMPT-INTERACTIVE" USING LS-PROMPT LS-ERROR-CODE.

           MOVE 0 TO LS-ERROR-CODE.
           MOVE SPACES TO LS-PROMPT.

      *> Display prompt
           DISPLAY "Enter your prompt (or 'help' for commands): "
               WITH NO ADVANCING.

      *> Accept input
           ACCEPT WS-INPUT-BUFFER.

      *> Trim and validate
           MOVE FUNCTION TRIM(WS-INPUT-BUFFER) TO WS-TRIMMED.
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-TRIMMED))
               TO WS-INPUT-LENGTH.

      *> Check for empty input
           IF WS-TRIMMED = SPACES OR WS-INPUT-LENGTH < WS-MIN-PROMPT-LEN
               MOVE 4001 TO LS-ERROR-CODE
               EXIT PROGRAM
           END-IF.

      *> Check for max length
           IF WS-INPUT-LENGTH > WS-MAX-PROMPT-LEN
               MOVE 4002 TO LS-ERROR-CODE
               EXIT PROGRAM
           END-IF.

      *> Check for special commands
           MOVE FUNCTION LOWER-CASE(WS-TRIMMED(1:20))
               TO WS-COMMAND-TYPE.

           IF CMD-HELP
               DISPLAY "COBOL AI CLI - Commands:"
               DISPLAY "  help    - Show this help message"
               DISPLAY "  version - Show version information"
               DISPLAY "  exit    - Exit the program"
               DISPLAY "  clear   - Clear the screen"
               DISPLAY "Or enter any prompt to send to the AI."
               MOVE 9999 TO LS-ERROR-CODE
               EXIT PROGRAM
           END-IF.

           IF CMD-VERSION
               DISPLAY WS-VERSION-TEXT
               MOVE 9999 TO LS-ERROR-CODE
               EXIT PROGRAM
           END-IF.

           IF CMD-EXIT OR CMD-QUIT
               DISPLAY "Exiting..."
               MOVE 8888 TO LS-ERROR-CODE
               EXIT PROGRAM
           END-IF.

           IF CMD-CLEAR
               CALL "SYSTEM" USING "clear"
               MOVE 9999 TO LS-ERROR-CODE
               EXIT PROGRAM
           END-IF.

           MOVE WS-TRIMMED TO LS-PROMPT.

      *> GET-PROMPT-ARGUMENT - Get prompt from command line argument
       ENTRY "GET-PROMPT-ARGUMENT"
           USING LS-ARG-COUNT LS-ARG-ARRAY LS-PROMPT LS-ERROR-CODE.

           MOVE 0 TO LS-ERROR-CODE.
           MOVE SPACES TO LS-PROMPT.

      *> Check if arguments provided
           IF LS-ARG-COUNT < 2
               MOVE 4001 TO LS-ERROR-CODE
               EXIT PROGRAM
           END-IF.

      *> Combine arguments into prompt (simple approach)
           MOVE LS-ARG-ENTRY(2) TO LS-PROMPT.

      *> Validate
           IF LS-PROMPT = SPACES
               MOVE 4001 TO LS-ERROR-CODE
               EXIT PROGRAM
           END-IF.

      *> IS-EXIT-COMMAND - Check if input is exit command
       ENTRY "IS-EXIT-COMMAND" USING LS-PROMPT LS-ERROR-CODE.
           MOVE 0 TO LS-ERROR-CODE.
           MOVE FUNCTION LOWER-CASE(FUNCTION TRIM(LS-PROMPT))
               TO WS-COMMAND-TYPE.
           IF CMD-EXIT OR CMD-QUIT
               MOVE 8888 TO LS-ERROR-CODE
           END-IF.

      *> DISPLAY-HELP - Show help information
       ENTRY "DISPLAY-HELP".
           DISPLAY "COBOL AI CLI - Commands:".
           DISPLAY "  help    - Show this help message".
           DISPLAY "  version - Show version information".
           DISPLAY "  exit    - Exit the program".
           DISPLAY "  clear   - Clear the screen".
           DISPLAY "Or enter any prompt to send to the AI.".

      *> DISPLAY-VERSION - Show version information
       ENTRY "DISPLAY-VERSION".
           DISPLAY WS-VERSION-TEXT.

       END PROGRAM PROMPT-HANDLER.