       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBOL-AI-CLI.

      *>================================================================*
      *> COBOL-AI-CLI - Main Program
      *>
      *> Description: AI Agent CLI for Ollama Cloud API Integration
      *> Version:     1.9.0 (Per-Run State Paths)
      *> Author:      COBOL AI CLI Team
      *> License:     MIT
      *>
      *> Features:
      *>   - Animated loading spinner during API requests
      *>   - Colored UI with banners and themes (light/dark)
      *>   - Command history navigation
      *>   - One-shot and interactive modes
      *>   - JSON parsing with unicode support
      *>   - Syntax highlighting for code blocks
      *>   - Real-time prompt length validation
      *>   - Retry logic with HTTP status classification (Phase 4)
      *>   - Persistent response caching to reduce API calls (Phase 4)
      *>   - File input: ask questions about a file (Phase 3)
      *>   - Output file: append exchanges to a file (Phase 3)
      *>   - Keyring credential storage via secret-tool (Phase 4)
      *>   - Comprehensive error handling (Phase 4)
      *>
      *> Layout:
      *>   This file holds only the program skeleton: the file control
      *>   entries, the FDs, and the main entry point. Data definitions
      *>   and paragraphs live in src/copybooks, one file per concern:
      *>
      *>     ws-config      credentials, keyring, defaults, retry state
      *>     ws-cache       cache table, record layout, hashing state
      *>     ws-errors      error state and error code constants
      *>     ws-http        request/response buffers, JSON cursors
      *>     ws-io          prompt, attached file, pipe, output file
      *>     ws-ui          colours, banner text, spinner, highlighting
      *>     ws-state       run mode, history, conversation, models
      *>
      *>     pd-config      loading and validating configuration
      *>     pd-errors      logging and reporting errors
      *>     pd-runmode     pipe/argument detection and the prompt loop
      *>     pd-http        payload, retry loop, status, JSON parsing
      *>     pd-cache       cache lookup, storage and persistence
      *>     pd-fileio      file input and the output file
      *>     pd-history     command history
      *>     pd-conversation  conversation recording and export
      *>     pd-models      model selection and statistics
      *>     pd-ui          banner, themes, help, response rendering
      *>     pd-cleanup     shutdown and session summary
      *>
      *>   Build with: cobc -x -free -I src/copybooks src/main.cob
      *>   (the Makefile does this; a bare cobc without -I will fail)
      *>================================================================*
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT RESPONSE-FILE ASSIGN TO WS-RESPONSE-FILE
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
           SELECT HISTORY-FILE ASSIGN TO WS-HISTORY-FILE
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-HISTORY-STATUS.
           SELECT THEME-FILE ASSIGN TO WS-THEME-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-THEME-STATUS.
           SELECT CONVERSATION-FILE ASSIGN TO WS-CONV-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-CONV-STATUS.
           SELECT STDIN-FILE ASSIGN TO WS-STDIN-TEMP-FILE
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-STDIN-FILE-STATUS.
           SELECT OPTIONAL OUTPUT-FILE ASSIGN TO WS-OUTPUT-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUTPUT-FILE-STATUS.
           SELECT CACHE-FILE ASSIGN TO WS-CACHE-FILE
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-CACHE-STATUS.
           SELECT USER-FILE ASSIGN TO WS-USER-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-USER-FILE-STATUS.
           SELECT PROMPT-FILE ASSIGN TO WS-PROMPT-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-PROMPT-FILE-STATUS.
           SELECT OPTIONAL STATUS-FILE ASSIGN TO WS-STATUS-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-STATUS-FILE-STATUS.
           SELECT OPTIONAL KEYRING-FILE ASSIGN TO WS-KEYRING-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-KEYRING-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD RESPONSE-FILE.
       01 RESPONSE-LINE         PIC X(50000).
       FD HISTORY-FILE.
       01 HISTORY-LINE          PIC X(1000).
       FD THEME-FILE.
       01 THEME-LINE            PIC X(20).
       FD CONVERSATION-FILE.
       01 CONVERSATION-LINE     PIC X(5000).
       FD STDIN-FILE.
       01 STDIN-RECORD          PIC X(5000).
       FD OUTPUT-FILE.
       01 OUTPUT-RECORD         PIC X(25000).
       FD CACHE-FILE.
       01 CACHE-RECORD          PIC X(25079).
       FD USER-FILE.
       01 USER-FILE-LINE        PIC X(2000).
       FD PROMPT-FILE.
       01 PROMPT-FILE-LINE      PIC X(12000).
       FD STATUS-FILE.
       01 STATUS-LINE           PIC X(10).
       FD KEYRING-FILE.
       01 KEYRING-LINE          PIC X(200).

       WORKING-STORAGE SECTION.

      *> Data definitions live in src/copybooks/ws-*.cpy, grouped by the
      *> concern they serve. Order is not significant between groups.
       COPY "ws-config.cpy".
       COPY "ws-cache.cpy".
       COPY "ws-errors.cpy".
       COPY "ws-http.cpy".
       COPY "ws-io.cpy".
       COPY "ws-ui.cpy".
       COPY "ws-state.cpy".

       PROCEDURE DIVISION.

      *>================================================================*
      *> MAIN ENTRY POINT
      *>
      *> This must remain the first paragraph: control falls into the
      *> first paragraph of the PROCEDURE DIVISION, and STOP RUN below
      *> stops it running on into the copybooks that follow.
      *>================================================================*
       MAIN-PROCEDURE.
           PERFORM INITIALIZE-PROGRAM.
           PERFORM DETERMINE-RUN-MODE.
           PERFORM RUN-APPLICATION.
           PERFORM CLEANUP-PROGRAM.
           STOP RUN.

       INITIALIZE-PROGRAM.
      *> Must run first: everything below opens files by these paths.
           PERFORM INIT-PATHS.
           PERFORM DISPLAY-BANNER.
           PERFORM LOAD-CONFIGURATION.
           PERFORM VALIDATE-CONFIGURATION.
           PERFORM LOAD-HISTORY.
           PERFORM LOAD-THEME.
           PERFORM LOAD-RESPONSE-CACHE.
           PERFORM INIT-CONVERSATION-HISTORY.
           PERFORM INIT-MODEL-LIST.

      *> Paragraphs live in src/copybooks/pd-*.cpy, grouped by concern.
      *> All are reached by PERFORM, so their order is not significant.
       COPY "pd-config.cpy".
       COPY "pd-errors.cpy".
       COPY "pd-runmode.cpy".
       COPY "pd-http.cpy".
       COPY "pd-cache.cpy".
       COPY "pd-fileio.cpy".
       COPY "pd-history.cpy".
       COPY "pd-conversation.cpy".
       COPY "pd-models.cpy".
       COPY "pd-ui.cpy".
       COPY "pd-cleanup.cpy".

       END PROGRAM COBOL-AI-CLI.
