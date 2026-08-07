      *>================================================================*
      *> WORKING-STORAGE: Prompt, file input, pipe and file output
      *>
      *> Typed prompt, attached file buffers, stdin capture, output file.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

      *> SECTION: INPUT/OUTPUT
      *>================================================================*
       01 WS-PROMPT             PIC X(1000) VALUE SPACES.
       01 WS-PROMPT-TRIMMED     PIC X(1000) VALUE SPACES.
       01 WS-PROMPT-LEN         PIC 9(4) VALUE 0.

      *>================================================================*
      *> SECTION: FILE INPUT (Phase 3)
      *>================================================================*
       01 WS-FILE-INPUT.
          05 WS-USER-FILE-NAME    PIC X(255) VALUE SPACES.
          05 WS-USER-FILE-STATUS  PIC XX VALUE SPACES.
          05 WS-FILE-CONTENT      PIC X(10000) VALUE SPACES.
          05 WS-FILE-MAX          PIC 9(5) VALUE 10000.
          05 WS-FILE-POS          PIC 9(5) VALUE 1.
          05 WS-FILE-LINE-LEN     PIC 9(5) VALUE 0.
          05 WS-FILE-LINES        PIC 9(5) VALUE 0.
          05 WS-FILE-CHARS        PIC 9(5) VALUE 0.
          05 WS-FILE-ARG          PIC X(1000) VALUE SPACES.
          05 WS-FILE-QUESTION     PIC X(1000) VALUE SPACES.
          05 WS-FILE-SPLIT        PIC 9(5) VALUE 0.
          05 WS-FILE-ARG-LEN      PIC 9(5) VALUE 0.
          05 WS-FILE-TRUNCATED    PIC X VALUE "N".
             88 FILE-TRUNCATED     VALUE "Y".
          05 WS-FILE-LOADED       PIC X VALUE "N".
             88 FILE-LOADED        VALUE "Y".

      *> The composed prompt actually sent to the API: either the typed
      *> prompt, or the question plus the attached file's contents.
       01 WS-FULL-PROMPT        PIC X(12000) VALUE SPACES.
       01 WS-PROMPT-FILE-NAME   PIC X(100) VALUE
           "/tmp/cobol-ai-prompt.txt".
       01 WS-PROMPT-FILE-STATUS PIC XX VALUE SPACES.
       01 WS-NL                 PIC X VALUE X"0A".

       01 WS-INPUT-LIMITS.
          05 WS-MIN-PROMPT-LEN PIC 9(4) VALUE 1.
          05 WS-MAX-PROMPT-LEN PIC 9(4) VALUE 500.

       01 WS-COMMAND-TYPE       PIC X(20) VALUE SPACES.
          88 CMD-HELP          VALUE "help".
          88 CMD-VERSION       VALUE "version".
          88 CMD-EXIT          VALUE "exit".
          88 CMD-QUIT          VALUE "quit".
          88 CMD-HISTORY       VALUE "history".
          88 CMD-CLEAR         VALUE "clear".
          88 CMD-THEME         VALUE "theme".
          88 CMD-EXPORT        VALUE "export".
          88 CMD-MODEL         VALUE "model".
          88 CMD-MODELS        VALUE "models".
          88 CMD-OUTPUT        VALUE "output".
          88 CMD-OUT           VALUE "out".

       01 WS-EXPORT-FORMAT      PIC X(10) VALUE "text".
          88 FORMAT-TEXT        VALUE "text".
          88 FORMAT-JSON        VALUE "json".
          88 FORMAT-MARKDOWN    VALUE "markdown".

       01 WS-ARG-COUNT          PIC 9(4) VALUE 0.
       01 WS-ARG-VALUE          PIC X(1000) VALUE SPACES.
       01 WS-CMD-LINE           PIC X(1000) VALUE SPACES.

      *>================================================================*
      *> SECTION: PIPE SUPPORT (Phase 3)
      *>================================================================*
       01 WS-STDIN-BUFFER       PIC X(5000) VALUE SPACES.
       01 WS-STDIN-LENGTH       PIC 9(4) VALUE 0.
       01 WS-HAS-STDIN          PIC X VALUE "N".
          88 HAS-STDIN          VALUE "Y".
          88 NO-STDIN           VALUE "N".
       01 WS-STDIN-TEMP-FILE    PIC X(100) VALUE "/tmp/cobol-ai-stdin.txt".
       01 WS-STDIN-FILE-STATUS  PIC XX VALUE SPACES.
       01 WS-STDIN-TEMP         PIC X VALUE "N".

      *>================================================================*
      *> SECTION: FILE OUTPUT (Phase 3)
      *>================================================================*
       01 WS-OUTPUT-FILE-NAME   PIC X(200) VALUE SPACES.
       01 WS-OUTPUT-FILE-STATUS PIC XX VALUE SPACES.
       01 WS-OUTPUT-ARG         PIC X(200) VALUE SPACES.
       01 WS-OUTPUT-LINE        PIC X(5000) VALUE SPACES.
       01 WS-OUTPUT-FORMAT      PIC X(10) VALUE "text".
          88 OUT-FORMAT-TEXT    VALUE "text".
          88 OUT-FORMAT-JSON    VALUE "json".
          88 OUT-FORMAT-MARKDOWN VALUE "markdown".

      *>================================================================*
