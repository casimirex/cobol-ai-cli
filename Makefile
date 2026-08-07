# COBOL AI CLI - Makefile
# Build automation - main.cob plus copybooks in src/copybooks

# Compiler settings
COBC = cobc
COPY_DIR = src/copybooks
COBC_FLAGS = -x -free -I $(COPY_DIR)

# Directories
SRC_DIR = src
BIN_DIR = bin
OBJ_DIR = lib
TEST_DIR = tests
DOC_DIR = docs

# Source files
MAIN_SRC = $(SRC_DIR)/main.cob
COPYBOOKS = $(wildcard $(COPY_DIR)/*.cpy)

# Main executable
EXECUTABLE = $(BIN_DIR)/cobol-ai-cli

# Binary invoked by the ./cobol-ai wrapper - this is what users actually
# run, so it must be built by the same target the tests use.
WRAPPER_BIN = cobol-ai.bin

# Default target
.PHONY: all
all: dirs $(EXECUTABLE) $(WRAPPER_BIN)

# Create directories
.PHONY: dirs
dirs:
	@mkdir -p $(BIN_DIR) $(OBJ_DIR)

# Compile main program
$(EXECUTABLE): $(MAIN_SRC) $(COPYBOOKS) | dirs
	@echo "Building $(EXECUTABLE)..."
	$(COBC) $(COBC_FLAGS) -o $@ $(MAIN_SRC)

# Compile the wrapper's binary from the same source
$(WRAPPER_BIN): $(MAIN_SRC) $(COPYBOOKS)
	@echo "Building $(WRAPPER_BIN)..."
	$(COBC) $(COBC_FLAGS) -o $@ $(MAIN_SRC)

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BIN_DIR)/* $(OBJ_DIR)/*
	rm -f $(WRAPPER_BIN)
	rm -f main.c main.c.h main.c.l.h main.i
	rm -f /tmp/cobol-ai-*.json

# Run the program
.PHONY: run
run: all
	@./run-test.sh

# Run with a specific prompt
.PHONY: prompt
prompt: all
	@read -p "Enter prompt: " PROMPT; \
	./run-test.sh "$$PROMPT"

# Run tests
.PHONY: test
test: all
	@echo "Running tests..."
	@./$(TEST_DIR)/test-runner.sh

# Check dependencies
.PHONY: check-deps
check-deps:
	@echo "Checking dependencies..."
	@which cobc > /dev/null 2>&1 || { echo "Error: GnuCOBOL (cobc) not found"; exit 1; }
	@which curl > /dev/null 2>&1 || { echo "Error: curl not found"; exit 1; }
	@echo "All dependencies satisfied."

# Lint COBOL files
.PHONY: lint
lint:
	@echo "Linting $(MAIN_SRC)..."
	$(COBC) -fsyntax-only -free -I $(COPY_DIR) $(MAIN_SRC)

# Build with debug symbols
.PHONY: debug
debug: COBC_FLAGS = -x -free -I $(COPY_DIR) -g
debug: all
	@echo "Built with debug symbols."

# Install system-wide
.PHONY: install
install: all
	@echo "Installing to /usr/local/bin..."
	@cp $(EXECUTABLE) /usr/local/bin/
	@cp cobol-ai-helper.sh /usr/local/bin/
	@echo "Installation complete."

# Uninstall
.PHONY: uninstall
uninstall:
	@echo "Uninstalling from /usr/local/bin..."
	@rm -f /usr/local/bin/cobol-ai-cli
	@rm -f /usr/local/bin/cobol-ai-helper.sh
	@echo "Uninstallation complete."

# Show architecture
.PHONY: show-arch
show-arch:
	@echo "COBOL AI CLI Architecture:"
	@echo "=========================="
	@echo "Single-file modular design:"
	@echo "  - src/main.cob contains all modules"
	@echo "  - Clear section separation:"
	@echo "    * Configuration"
	@echo "    * HTTP Client"
	@echo "    * JSON Parser"
	@echo "    * Input/Output"
	@echo "    * Program State"
	@echo "  - Clean paragraph organization"

# Help
.PHONY: help
help:
	@echo "COBOL AI CLI - Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all           - Build the main executable (default)"
	@echo "  clean         - Remove build artifacts"
	@echo "  run           - Build and run the program"
	@echo "  prompt        - Build and run with a specific prompt"
	@echo "  test          - Run all tests"
	@echo "  check-deps    - Verify dependencies are installed"
	@echo "  lint          - Syntax check COBOL files"
	@echo "  debug         - Build with debug symbols"
	@echo "  install       - Install system-wide (requires sudo)"
	@echo "  uninstall     - Remove system installation"
	@echo "  show-arch     - Display architecture information"
	@echo "  help          - Show this help message"
	@echo ""
	@echo "Usage:"
	@echo "  ./cobol-ai 'your prompt'   # One-shot mode (recommended)"
	@echo "  ./cobol-ai                 # Interactive mode (recommended)"
	@echo "  make run                   # Build and run"
	@echo "  make test                  # Run tests"
	@echo ""
	@echo "Architecture:"
	@echo "  Single-file design with modular sections"
	@echo "  See 'make show-arch' for details"