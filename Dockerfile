# COBOL AI CLI - container image
#
# Build:  docker build -t cobol-ai-cli .
# Run:    docker run --rm -e AI_OLLAMA_API_KEY=... cobol-ai-cli "What is 2+2?"
#
# Two stages so the runtime image carries libcob but not the compiler.

# ---------- build ----------
FROM debian:bookworm-slim AS build

RUN apt-get update \
 && apt-get install -y --no-install-recommends gnucobol make \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY Makefile ./
COPY src/ ./src/
RUN make dirs && cobc -x -free -I src/copybooks -o cobol-ai.bin src/main.cob

# ---------- runtime ----------
FROM debian:bookworm-slim

# libcob4 is the GnuCOBOL runtime; curl performs the actual API calls.
# libxml2 and libgmp are libcob's own dependencies.
RUN apt-get update \
 && apt-get install -y --no-install-recommends libcob4 curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /src/cobol-ai.bin /usr/local/bin/cobol-ai.bin
COPY cobol-ai-helper.sh /usr/local/bin/cobol-ai-helper.sh
COPY cobol-ai /usr/local/bin/cobol-ai
RUN chmod 755 /usr/local/bin/cobol-ai /usr/local/bin/cobol-ai.bin \
              /usr/local/bin/cobol-ai-helper.sh

# Run unprivileged, with a real home so the state directory has somewhere
# to live. Persist it with: -v cobol-ai-state:/home/cobol/.local/state
RUN useradd --create-home --shell /bin/bash cobol
USER cobol
WORKDIR /home/cobol
ENV HOME=/home/cobol

ENTRYPOINT ["/usr/local/bin/cobol-ai"]
