      *>================================================================*
      *> WORKING-STORAGE: Response cache
      *>
      *> Cache table, on-disk record layout, key hashing and expiry state.
      *> Included by src/main.cob - not compiled on its own.
      *>================================================================*

      *> SECTION: RESPONSE CACHING (Phase 4)
      *>================================================================*
       01 WS-CACHE-CONFIG.
          05 WS-CACHE-ENABLED   PIC X VALUE "Y".
             88 CACHE-ENABLED   VALUE "Y".
             88 CACHE-DISABLED VALUE "N".
          05 WS-CACHE-HITS      PIC 9(5) VALUE 0.
          05 WS-CACHE-MISSES    PIC 9(5) VALUE 0.
          05 WS-CACHE-FILE      PIC X(100) VALUE "/tmp/cobol-ai-cache.dat".
          05 WS-CACHE-STATUS    PIC XX VALUE SPACES.
          05 WS-CACHE-KEY       PIC X(12100) VALUE SPACES.
          05 WS-CACHE-HASH      PIC X(64) VALUE SPACES.

       01 WS-CACHE-TABLE.
          05 WS-CACHE-ENTRY OCCURS 20 TIMES.
             10 WS-CACHE-PROMPT-HASH PIC X(64).
             10 WS-CACHE-RESPONSE    PIC X(25000).
             10 WS-CACHE-TIMESTAMP   PIC X(14).
             10 WS-CACHE-VALID       PIC X VALUE "Y".

       01 WS-CACHE-COUNT         PIC 9(4) VALUE 0.
       01 WS-CACHE-MAX           PIC 9(4) VALUE 20.
       01 WS-CACHE-INDEX         PIC 9(4) VALUE 0.
       01 WS-CACHE-FOUND         PIC X VALUE "N".
          88 CACHE-FOUND          VALUE "Y".
          88 CACHE-NOT-FOUND      VALUE "N".

      *> Persistent cache record layout (matches CACHE-RECORD)
       01 WS-CACHE-REC.
          05 WS-CR-HASH          PIC X(64).
          05 WS-CR-TIMESTAMP     PIC X(14).
          05 WS-CR-VALID         PIC X.
          05 WS-CR-RESPONSE      PIC X(25000).

      *> Cache key hashing and expiry
       01 WS-CACHE-WORK.
          05 WS-HASH-ACC         PIC 9(12) VALUE 0.
          05 WS-HASH-POS         PIC 9(5) VALUE 0.
          05 WS-HASH-KEY-LEN     PIC 9(5) VALUE 0.
          05 WS-HASH-ACC-DISP    PIC 9(12) VALUE 0.
          05 WS-HASH-LEN-DISP    PIC 9(4) VALUE 0.
          05 WS-CACHE-TTL-DAYS   PIC 9(4) VALUE 7.
          05 WS-CACHE-DATE-INT   PIC 9(8) VALUE 0.
          05 WS-CACHE-TODAY-INT  PIC 9(8) VALUE 0.
          05 WS-CACHE-NL-COUNT   PIC 9(4) VALUE 0.
          05 WS-CACHE-LOADED     PIC 9(4) VALUE 0.

      *>================================================================*
