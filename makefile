# Compiler and flags
CC = gcc
CFLAGS = -Wall -Iinclude

# Define short forms for commonly used commands
MKDIR=mkdir -p      # Use -p to create parent directories as needed
RM=rm -rf           # Use -rf to force removal of files/directories
ECHO=@echo
# Directories
SRC_DIR = src
OBJ_DIR = obj
FULL_BIN_DIR = Full_bin

# Target executable
TARGET = $(FULL_BIN_DIR)/program

# Find all .c files in the source directory
SRC_FILES = $(wildcard $(SRC_DIR)/*.c)
# Convert source files in src to object files in obj
OBJ_FILES = $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(SRC_FILES))

# Default target
all: create_dir $(TARGET)

# Rule to link object files and create the executable
$(TARGET): $(OBJ_FILES)
	$(ECHO) "Linking object files to create executable: $@"
	$(CC) $(CFLAGS) -o $@ $^

# Rule to compile .c files to .o files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(ECHO) "Compiling $< into $@"
	$(CC) $(CFLAGS) -c -o $@ $<

# Clean up build artifacts
clean:
	$(ECHO) "Cleaning up generated files..."
	$(RM) $(OBJ_DIR) $(FULL_BIN_DIR)

# Target to create necessary directories
create_dir:
	$(ECHO) "Creating directories: $(OBJ_DIR) and $(FULL_BIN_DIR)"
	$(MKDIR) $(OBJ_DIR) $(FULL_BIN_DIR)

# Phony targets
.PHONY: all clean
