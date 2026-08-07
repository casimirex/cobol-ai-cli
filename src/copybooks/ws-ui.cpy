      *>================================================================*
      *> WORKING-STORAGE: Display constants, themes and spinner
      *>
      *> Colour codes, banner text, spinner frames, syntax highlighting.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

      *> SECTION: DISPLAY CONSTANTS (Enhanced UI)
      *>================================================================*
       01 WS-DISPLAY-CONSTANTS.
          05 WS-DIVIDER        PIC X(70) VALUE ALL "=".
          05 WS-DIVIDER-THIN   PIC X(70) VALUE ALL "-".
          05 WS-BANNER-TOP     PIC X(70) VALUE
             "+======================================================================+".
          05 WS-BANNER-MID     PIC X(70) VALUE
             "|                                                                      |".
          05 WS-BANNER-TITLE   PIC X(70) VALUE
             "|                    COBOL AI CLI v1.2.0                               |".
          05 WS-BANNER-SUB     PIC X(70) VALUE
             "|                  Powered by Ollama Cloud API                         |".
          05 WS-BANNER-BOT     PIC X(70) VALUE
             "+======================================================================+".
          05 WS-PROMPT-MSG     PIC X(70) VALUE
             "> Enter your prompt (or 'exit' to quit): ".
          05 WS-CONTINUE-MSG   PIC X(70) VALUE
             "> Press Enter to continue or 'exit' to quit: ".
          05 WS-HELP-HEADER    PIC X(70) VALUE
             "=== Available Commands ===".
          05 WS-INFO-ICON      PIC X(8) VALUE "[INFO]  ".
          05 WS-SUCCESS-ICON   PIC X(8) VALUE "[OK]    ".
          05 WS-ERROR-ICON     PIC X(8) VALUE "[ERR]   ".
          05 WS-SEND-ICON      PIC X(8) VALUE "[SEND]  ".
          05 WS-RECV-ICON      PIC X(8) VALUE "[RECV]  ".

      *> Spinner animation frames (Phase 1 - Loading Animation)
       01 WS-SPINNER.
          05 WS-SPINNER-CHARS  PIC X(4) VALUE "-\|/".
          05 WS-SPINNER-POS    PIC 9(1) VALUE 1.
          05 WS-SPINNER-FRAME  PIC X VALUE SPACES.
          05 WS-SPINNER-COUNT  PIC 9(3) VALUE 0.
          05 WS-SPINNER-MAX    PIC 9(3) VALUE 20.

      *> Theme settings (Phase 1 - Custom Themes)
       01 WS-THEME-SETTINGS.
          05 WS-CURRENT-THEME  PIC X(20) VALUE "dark".
             88 THEME-DARK     VALUE "dark".
             88 THEME-LIGHT    VALUE "light".
          05 WS-THEME-FILE-NAME PIC X(100) VALUE
              "/tmp/cobol-ai-theme.txt".
       01 WS-THEME-STATUS     PIC XX VALUE SPACES.

      *> Color codes for themes
       01 WS-COLOR-CODES.
          05 WS-COLOR-BANNER   PIC X(10) VALUE "\033[1;36m".
          05 WS-COLOR-PROMPT   PIC X(10) VALUE "\033[34m".
          05 WS-COLOR-RESPONSE PIC X(10) VALUE "\033[37m".
          05 WS-COLOR-ERROR    PIC X(10) VALUE "\033[31m".
          05 WS-COLOR-SUCCESS  PIC X(10) VALUE "\033[32m".
          05 WS-COLOR-WARNING  PIC X(10) VALUE "\033[33m".
          05 WS-COLOR-INFO     PIC X(10) VALUE "\033[35m".
          05 WS-COLOR-RESET    PIC X(5) VALUE "\033[0m".
          05 WS-COLOR-CODE     PIC X(10) VALUE "\033[36m".
          05 WS-COLOR-CODE-BG  PIC X(10) VALUE "\033[40m".

      *> Syntax highlighting for code blocks (Phase 1)
       01 WS-CODE-BLOCK-FLAGS.
          05 WS-IN-CODE-BLOCK  PIC X VALUE "N".
             88 IN-CODE-BLOCK  VALUE "Y".
             88 NOT-IN-CODE    VALUE "N".
          05 WS-CODE-LINE      PIC X(200) VALUE SPACES.
          05 WS-CODE-START     PIC X(3) VALUE "```".
          05 WS-CODE-END       PIC X(3) VALUE "```".

      *>================================================================*
