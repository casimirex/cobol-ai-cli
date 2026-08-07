      *>================================================================*
      *> WORKING-STORAGE: Program state, history and conversation
      *>
      *> Run mode, command history, response buffer, conversation, models.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

      *> SECTION: PROGRAM STATE
      *>================================================================*
       01 WS-RUN-MODE           PIC X(10) VALUE SPACES.
          88 MODE-INTERACTIVE   VALUE "interactive".
          88 MODE-ONE-SHOT      VALUE "oneshot".

       01 WS-CONTINUE           PIC X VALUE "Y".
          88 SHOULD-CONTINUE   VALUE "Y".
          88 SHOULD-EXIT       VALUE "N".

       01 WS-TEMP-CHAR          PIC X VALUE SPACES.
       01 WS-TEMP-POS          PIC 9(5) VALUE 0.
       01 WS-TEMP-STRING        PIC X(100) VALUE SPACES.

      *>================================================================*
      *> SECTION: COMMAND HISTORY (NEW - Phase 1)
      *>================================================================*
       01 WS-HISTORY-FILE       PIC X(100) VALUE SPACES.
       01 WS-HISTORY-STATUS     PIC XX VALUE SPACES.
       01 WS-HISTORY-COUNT      PIC 9(4) VALUE 0.
       01 WS-HISTORY-MAX        PIC 9(4) VALUE 100.
       01 WS-HISTORY-INDEX      PIC 9(4) VALUE 0.

       01 WS-HISTORY-TABLE.
          05 WS-HISTORY-ENTRY OCCURS 100 TIMES.
             10 WS-HIST-TEXT   PIC X(1000).

       01 WS-HIST-FILE-NAME     PIC X(100) VALUE
           "/tmp/cobol-ai-history.txt".

      *>================================================================*
      *> SECTION: RESPONSE BUFFER
      *>================================================================*
       01 WS-RESPONSE-TEXT      PIC X(25000) VALUE SPACES.
       01 WS-RESPONSE-LEN       PIC 9(5) VALUE 0.
       01 WS-CLEAN-RESPONSE     PIC X(25000) VALUE SPACES.
       01 WS-OUT-POS            PIC 9(5) VALUE 0.

      *>================================================================*
      *> SECTION: CONVERSATION HISTORY (Phase 2)
      *>================================================================*
       01 WS-CONVERSATION-FILE  PIC X(100) VALUE SPACES.
       01 WS-CONV-STATUS        PIC XX VALUE SPACES.
       01 WS-CONV-COUNT         PIC 9(4) VALUE 0.
       01 WS-CONV-MAX           PIC 9(4) VALUE 50.
       01 WS-CONV-INDEX         PIC 9(4) VALUE 0.

       01 WS-CONVERSATION-TABLE.
          05 WS-CONVERSATION-ENTRY OCCURS 50 TIMES.
             10 WS-CONV-PROMPT   PIC X(1000).
             10 WS-CONV-RESPONSE PIC X(5000).
             10 WS-CONV-TIMESTAMP PIC X(20).

       01 WS-CONV-FILE-NAME     PIC X(100) VALUE
           "/tmp/cobol-ai-conversation.json".
       01 WS-EXPORT-FILE-NAME   PIC X(100) VALUE SPACES.

      *>================================================================*
      *> SECTION: MODEL MANAGEMENT (Phase 2)
      *>================================================================*
       01 WS-VALID-MODELS.
          05 WS-VALID-MODEL-ENTRY OCCURS 6 TIMES VALUE SPACES.
             10 WS-VM-NAME        PIC X(50).
