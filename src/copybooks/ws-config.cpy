      *>================================================================*
      *> WORKING-STORAGE: Configuration and retry state
      *>
      *> API credentials, keyring lookup buffers, defaults, retry schedule.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

      *>================================================================*
      *> SECTION: CONFIGURATION
      *>================================================================*
       01 WS-CONFIG.
          05 WS-API-KEY         PIC X(200) VALUE SPACES.
          05 WS-BASE-URL        PIC X(100) VALUE "https://ollama.com".
          05 WS-MODEL           PIC X(50) VALUE "gpt-oss:120b".
          05 WS-TIMEOUT         PIC 9(6) VALUE 60000.
          05 WS-CONFIG-LOADED   PIC X VALUE "N".
             88 CONFIG-LOADED   VALUE "Y".
          05 WS-ENCRYPTED-KEY   PIC X VALUE "N".
             88 KEY-ENCRYPTED   VALUE "Y".

       01 WS-KEYRING.
          05 WS-KEYRING-FILE-NAME   PIC X(100) VALUE
              "/tmp/cobol-ai-key.txt".
          05 WS-KEYRING-FILE-STATUS PIC XX VALUE SPACES.
          05 WS-KEYRING-VALUE       PIC X(200) VALUE SPACES.
          05 WS-KEYRING-CMD         PIC X(500) VALUE SPACES.

       01 WS-DEFAULTS.
          05 WS-DEFAULT-URL     PIC X(100) VALUE "https://ollama.com".
          05 WS-DEFAULT-MODEL   PIC X(50) VALUE "gpt-oss:120b".
          05 WS-DEFAULT-TIMEOUT PIC 9(6) VALUE 60000.

      *>================================================================*
      *> SECTION: RETRY LOGIC (Phase 4)
      *>================================================================*
       01 WS-RETRY-CONFIG.
          05 WS-MAX-RETRIES     PIC 9(2) VALUE 3.
          05 WS-CURRENT-RETRY   PIC 9(2) VALUE 0.
          05 WS-RETRY-DELAY     PIC 9(4) VALUE 1000.
          05 WS-BASE-DELAY      PIC 9(4) VALUE 1000.
          05 WS-MAX-DELAY       PIC 9(5) VALUE 30000.
          05 WS-LAST-HTTP-STATUS PIC S9(4) COMP VALUE 0.
          05 WS-RETRY-REASON    PIC X(100) VALUE SPACES.
          05 WS-HTTP-RETRYABLE  PIC X VALUE "N".
             88 HTTP-RETRYABLE   VALUE "Y".
          05 WS-STATUS-TEXT     PIC X(10) VALUE SPACES.
       01 WS-STATUS-FILE-NAME   PIC X(100) VALUE
           "/tmp/cobol-ai-status.txt".
       01 WS-STATUS-FILE-STATUS PIC XX VALUE SPACES.

      *>================================================================*
