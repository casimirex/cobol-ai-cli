Building an AI agent in a COBOL CLI that communicates with the Ollama Cloud API is a practical way to bring modern AI capabilities into a legacy environment. The core challenge is bridging COBOL's capabilities with a modern REST API, but this can be achieved by using system commands or third-party libraries to handle HTTP requests and JSON data.

Here is a comprehensive guide to building this integration.

### 🏗️ Architecture Overview

The general workflow for your COBOL program will be:

1.  **Accept User Input**: The COBOL CLI program takes a prompt or question as input from the user.
2.  **Construct the API Request**: It builds a JSON payload containing the user's prompt, the chosen cloud model, and other parameters (like `"stream": false` for a single response).
3.  **Send the HTTP Request**: Your COBOL program makes a `POST` request to the Ollama Cloud API endpoint (`https://ollama.com/api/generate`).
4.  **Process the Response**: It receives the JSON response from the API.
5.  **Parse the JSON**: The program parses the JSON to extract the AI's generated text.
6.  **Display the Result**: Finally, it displays the AI's response to the user in the CLI.

---

### 📝 Prerequisites

Before you begin, ensure you have the following:

1.  **Ollama Account & API Key**: You need an account on [ollama.com](https://ollama.com). Create an API key in your [settings](https://ollama.com/settings/keys).
2.  **COBOL Environment**: A working COBOL compiler and runtime (e.g., GnuCOBOL, IBM Enterprise COBOL, Micro Focus COBOL).
3.  **`curl` Command**: The `curl` utility must be installed on your system and accessible from the command line. This is the simplest way to make HTTP requests from COBOL.
4.  **JSON Parser**: Your COBOL environment needs a way to parse JSON. Options include:
    *   **IBM Enterprise COBOL**: Has the built-in `JSON PARSE` statement.
    *   **Other COBOL Environments**: You may need to use an external library or write a simple parser. For this guide, we will use a basic approach to extract the response, which can be adapted.

---

### 🛠️ Step-by-Step Implementation Guide

#### Step 1: Prepare the COBOL Program Structure

Start by defining the necessary sections in your COBOL program. This includes the `WORKING-STORAGE` for variables and the `PROCEDURE DIVISION` for the main logic.

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. OllamaAgent.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COMMAND            PIC X(500).
       01 WS-URL                PIC X(100) VALUE
               "https://ollama.com/api/generate".
       01 WS-API-KEY            PIC X(100).
       01 WS-MODEL              PIC X(50)  VALUE "gpt-oss:120b".
       01 WS-PROMPT             PIC X(200).
       01 WS-JSON-PAYLOAD       PIC X(1000).
       01 WS-RESPONSE-FILE      PIC X(50)  VALUE "ollama_response.json".
       01 WS-RESPONSE-DATA      PIC X(2000).
       01 WS-AI-RESPONSE        PIC X(2000).
       01 WS-EXIT-CODE          PIC 9(5).

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           DISPLAY "Enter your prompt for the AI agent: ".
           ACCEPT WS-PROMPT.
           
           PERFORM SEND-REQUEST.
           PERFORM READ-RESPONSE.
           PERFORM PARSE-RESPONSE.
           DISPLAY "AI Agent: " WS-AI-RESPONSE.
           
           STOP RUN.
```

#### Step 2: Send the HTTP Request to Ollama Cloud

The `SEND-REQUEST` subroutine constructs the `curl` command to make a `POST` request. This is the most critical part of the integration.

**Important**: You must authenticate your request by including your API key in the `Authorization` header.

```cobol
       SEND-REQUEST.
           MOVE "ollama_response.json" TO WS-RESPONSE-FILE

           STRING
               "curl -s -X POST " DELIMITED BY SIZE
               WS-URL DELIMITED BY SIZE
               " -H 'Authorization: Bearer " DELIMITED BY SIZE
               WS-API-KEY DELIMITED BY SIZE
               "' -H 'Content-Type: application/json' -d '" DELIMITED BY SIZE
               WS-JSON-PAYLOAD DELIMITED BY SIZE
               "' -o " DELIMITED BY SIZE
               WS-RESPONSE-FILE DELIMITED BY SIZE
               INTO WS-COMMAND
           END-STRING.

           CALL "SYSTEM" USING WS-COMMAND
               RETURNING WS-EXIT-CODE.
           IF WS-EXIT-CODE NOT = 0
               DISPLAY "Error sending request."
           END-IF.
```

#### Step 3: Build the JSON Payload

The JSON payload must contain the model name and your prompt. For the cloud API, the endpoint is `https://ollama.com/api/generate`. Here's an example of how to build it:

```cobol
       BUILD-JSON.
           STRING
               '{"model": "' DELIMITED BY SIZE
               WS-MODEL DELIMITED BY SIZE
               '", "prompt": "' DELIMITED BY SIZE
               WS-PROMPT DELIMITED BY SIZE
               '", "stream": false}' DELIMITED BY SIZE
               INTO WS-JSON-PAYLOAD
           END-STRING.
```

#### Step 4: Read the API Response

The `READ-RESPONSE` subroutine reads the JSON response from the file where `curl` saved it.

```cobol
       READ-RESPONSE.
           OPEN INPUT WS-RESPONSE-FILE.
           IF NOT WS-RESPONSE-FILE-STATUS = '00'
               DISPLAY "Error opening response file."
           ELSE
               READ WS-RESPONSE-FILE INTO WS-RESPONSE-DATA
               CLOSE WS-RESPONSE-FILE
           END-IF.
```

#### Step 5: Parse the JSON to Extract the AI's Response

This step extracts the AI-generated text from the JSON. The `response` field in the JSON contains the completion text.

```cobol
       PARSE-RESPONSE.
           PERFORM VARYING WS-I FROM 1 BY 1
                     UNTIL WS-I > FUNCTION LENGTH(WS-RESPONSE-DATA)
               IF WS-RESPONSE-DATA(WS-I:9) = '"response"'
                   COMPUTE WS-START = WS-I + 11
                   PERFORM VARYING WS-J FROM WS-START BY 1
                             UNTIL WS-J > FUNCTION LENGTH(WS-RESPONSE-DATA)
                       IF WS-RESPONSE-DATA(WS-J:1) = '"'
                           MOVE WS-RESPONSE-DATA(WS-START:WS-J - WS-START)
                             TO WS-AI-RESPONSE
                           EXIT PERFORM
                       END-IF
                   END-PERFORM
                   EXIT PERFORM
               END-IF
           END-PERFORM.
```

**Note**: This is a simplified parser. For production, consider using a proper JSON library or the `JSON PARSE` statement if your COBOL version supports it.

---

### 💡 Choosing Your Approach

*   **Using `SYSTEM` Calls**: The method above, using `CALL "SYSTEM"` to run `curl`, is the most portable and straightforward way to make HTTP requests from COBOL.
*   **Using COBOL HTTP Libraries**: Some COBOL implementations (e.g., isCOBOL, Micro Focus RMNet) have built-in HTTP client classes. If available, they offer more control and better integration.
*   **Using a Middleware**: For complex scenarios, you could create a simple Python or Node.js script that acts as a bridge, handling the API call and returning a simplified response to your COBOL program.

---

### 🚀 Running the AI Agent

1.  Set your API key as an environment variable:
    ```bash
    export OLLAMA_API_KEY="your_api_key_here"
    ```
2.  Compile your COBOL program. For example, with GnuCOBOL:
    ```bash
    cobc -x ollama_agent.cob -o ollama_agent
    ```
3.  Run the compiled program:
    ```bash
    ./ollama_agent
    ```

### 🔧 Important Considerations

*   **Security**: Never hardcode API keys in your source code. Use environment variables or secure credential stores.
*   **Error Handling**: Implement robust error handling for network issues, invalid API keys, and malformed JSON responses.
*   **Model Selection**: Choose an appropriate cloud model from Ollama's library. The example uses `gpt-oss:120b`.
*   **Streaming Responses**: For a better user experience, you can set `"stream": true` in the payload and process the response as a stream of JSON objects. This is more complex to implement in COBOL.
*   **JSON Parsing**: For production use, leverage a proper JSON parser. IBM Enterprise COBOL's `JSON PARSE` is a robust, built-in option.

This approach allows you to create a powerful AI agent that can be accessed from a COBOL CLI, seamlessly integrating modern AI capabilities with a classic development environment.