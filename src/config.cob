       IDENTIFICATION DIVISION.
       PROGRAM-ID. CONFIG.

      *> CONFIG Module
      *> Environment variable parsing and configuration management

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *> Configuration values
       01 WS-CONFIG.
          05 WS-PROVIDER        PIC X(50) VALUE "ollama".
          05 WS-API-KEY         PIC X(200) VALUE SPACES.
          05 WS-BASE-URL        PIC X(100) VALUE "https://ollama.com".
          05 WS-MODEL           PIC X(50) VALUE "gpt-oss:120b".
          05 WS-TIMEOUT         PIC 9(6) VALUE 60000.
          05 WS-CONFIG-LOADED   PIC X VALUE "N".

      *> Validation
       01 WS-IS-VALID          PIC X VALUE "N".
          88 CONFIG-VALID      VALUE "Y".
          88 CONFIG-INVALID    VALUE "N".

       LINKAGE SECTION.
       01 LS-API-KEY           PIC X(200).
       01 LS-BASE-URL          PIC X(100).
       01 LS-MODEL             PIC X(50).
       01 LS-TIMEOUT           PIC 9(6).
       01 LS-VALID             PIC X.
       01 LS-ERROR-CODE        PIC 9(4).

       PROCEDURE DIVISION.

      *> INIT-CONFIG - Initialize configuration from environment
       ENTRY "INIT-CONFIG" USING LS-ERROR-CODE.
           IF WS-CONFIG-LOADED = "Y"
               MOVE 0 TO LS-ERROR-CODE
               EXIT PROGRAM
           END-IF.

      *> Load AI_OLLAMA_API_KEY (required)
           ACCEPT WS-API-KEY FROM ENVIRONMENT "AI_OLLAMA_API_KEY".
           IF WS-API-KEY = SPACES
               MOVE 1001 TO LS-ERROR-CODE
               EXIT PROGRAM
           END-IF.

      *> Load AI_OLLAMA_BASE_URL
           ACCEPT WS-BASE-URL FROM ENVIRONMENT "AI_OLLAMA_BASE_URL".
           IF WS-BASE-URL = SPACES
               MOVE "https://ollama.com" TO WS-BASE-URL
           END-IF.

      *> Load AI_OLLAMA_DEFAULT_MODEL
           ACCEPT WS-MODEL FROM ENVIRONMENT "AI_OLLAMA_DEFAULT_MODEL".
           IF WS-MODEL = SPACES
               MOVE "gpt-oss:120b" TO WS-MODEL
           END-IF.

      *> Validate configuration
           IF WS-API-KEY NOT = SPACES
               MOVE 0 TO LS-ERROR-CODE
               MOVE "Y" TO WS-CONFIG-LOADED
           ELSE
               MOVE 1001 TO LS-ERROR-CODE
           END-IF.

      *> GET-API-KEY - Retrieve API key from config
       ENTRY "GET-API-KEY" USING LS-API-KEY.
           MOVE WS-API-KEY TO LS-API-KEY.

      *> GET-BASE-URL - Retrieve base URL from config
       ENTRY "GET-BASE-URL" USING LS-BASE-URL.
           MOVE WS-BASE-URL TO LS-BASE-URL.

      *> GET-MODEL - Retrieve model name from config
       ENTRY "GET-MODEL" USING LS-MODEL.
           MOVE WS-MODEL TO LS-MODEL.

      *> GET-TIMEOUT - Retrieve timeout value from config
       ENTRY "GET-TIMEOUT" USING LS-TIMEOUT.
           MOVE WS-TIMEOUT TO LS-TIMEOUT.

      *> IS-CONFIG-VALID - Check if configuration is valid
       ENTRY "IS-CONFIG-VALID" USING LS-VALID.
           IF CONFIG-VALID
               MOVE "Y" TO LS-VALID
           ELSE
               MOVE "N" TO LS-VALID
           END-IF.

      *> DISPLAY-CONFIG - Display current configuration
       ENTRY "DISPLAY-CONFIG".
           DISPLAY "=== Configuration ===".
           DISPLAY "Provider: " WS-PROVIDER.
           DISPLAY "API Key: ********".
           DISPLAY "Base URL: " WS-BASE-URL.
           DISPLAY "Model: " WS-MODEL.
           DISPLAY "Timeout: " WS-TIMEOUT " ms".

       END PROGRAM CONFIG.