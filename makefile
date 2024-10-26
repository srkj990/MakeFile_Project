# Makefile for building a C project
# This Makefile compiles .c files into .o files and links them into an executable file.

# --- Define short forms for commonly used commands ---
MKDIR = mkdir -p            # Use -p to create parent directories as needed
RM    = sudo rm -rf         # Use -rf to force removal of files/directories

# --- Directories ---
SRC_DIR = src                # Source directory containing .c files
OBJ_DIR = obj                # Directory for compiled .o files
FULL_DIR = Full   # Directory for the final executables

# --- File lists ---
SRC_FILES = $(wildcard $(SRC_DIR)/*.c)               # All .c files in the source directory
OBJ_FILES = $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(SRC_FILES))  # Corresponding .o files

# --- Compiler settings ---
CC = gcc                    # Compiler to use
CFLAGS = -Wall -Wextra -O2  # Compiler flags for warnings and optimizations

# --- Target executable ---
TARGET = Project_unsigned.bin  # Name of the final executable

# --- Default target ---
all: create_dir $(OBJ_FILES) $(TARGET)  # Build all object files and the final target
	@echo "Moving executable to $(FULL_DIR)"
	mv $(TARGET) $(FULL_DIR)  # Move executable to designated directory

# --- Build the executable ---
$(TARGET): $(OBJ_FILES)
	@echo "Linking object files to create executable: $@"
	$(CC) $(CFLAGS) -o $@ $^  # Link all object files into the final executable

# --- Rule for generating .o files from .c files ---
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@echo "Compiling $< to $@"
	$(CC) $(CFLAGS) -c $< -o $@  # Compile each .c file into a .o file

# --- Clean target to remove generated files ---
clean:
	@echo "Cleaning up generated files..."
	$(RM) $(OBJ_DIR) $(FULL_DIR)  # Remove all object files and executables

# --- Target to create necessary directories ---
create_dir:
	@echo "Creating directories: $(OBJ_DIR) and $(FULL_DIR)"
	$(MKDIR) $(OBJ_DIR) $(FULL_DIR)  # Create obj and Binary_files directories

# --- Phony targets ---
.PHONY: all clean create_dir  # Declare phony targets to avoid conflicts with file names
