# Colors
RED     := \033[31m
GREEN   := \033[32m
YELLOW  := \033[33m
BLUE    := \033[34m
MAGENTA := \033[35m
CYAN    := \033[36m
RESET   := \033[0m
BOLD    := \033[1m


# Define short forms for commonly used commands
MKDIR=mkdir -p     # Use -p to create parent directories as needed
RM=rm -rf           # Use -rf to force removal of files/directories
ECHO=@echo
SREC=srec_cat

# Directories
SOURCE_DIR = source
OBJECT_DIR = objects
INCLUDE_DIR = include
FULL_BIN_DIR = Full_bin

# Target executable
TARGET = $(FULL_BIN_DIR)/program
TARGET_BINARY = $(FULL_BIN_DIR)/program.bin
TARGET_HEX = $(FULL_BIN_DIR)/program.hex
TARGET_ELF = $(FULL_BIN_DIR)/program.elf
TARGET_MAP = $(FULL_BIN_DIR)/program.map

# Compiler and flags
#CC = gcc
CC = arm-none-eabi-gcc #Use -nostartfiles and -nodefaultlibs to exclude default system startup files and libraries.
LD = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
NM = arm-none-eabi-nm
READ_ELF = arm-none-eabi-readelf
OBJDUMP = arm-none-eabi-objdump

LDFLAGS = -T linker_script.ld -Map=$(TARGET_MAP)
#CFLAGS = -Wall -Werror
CFLAGS = -mcpu=cortex-m4 -mthumb -O2 -Wall -specs=nosys.specs
C_FLAGS_EXTRA = -I $(INCLUDE_DIR)
#COMPILE_CALL = $(CC) $(CFLAGS) $(C_FLAGS_EXTRA)
COMPILE_CALL = $(CC) #$(CFLAGS)

C_FLAGS_EXTRA1 = 0 # make all C_FLAGS_EXTRA1=0 or make all C_FLAGS_EXTRA1 = some other value.
C_FLAGS_EXTRA2 = 0 #

ifeq ($(C_FLAGS_EXTRA1),1)
	CFLAGS += -Wextra
else
	CFLAGS +=  -Wpedantic
endif

ifeq ($(C_FLAGS_EXTRA2),1)
	CFLAGS += -Wconversion
else
	CFLAGS +=  -Wswitch-enum
endif


# Find all .c files in the source directory
# $(wildcard pattern)
SOURCE_FILES = $(wildcard $(SOURCE_DIR)/*.c)
# Convert source files in source to object files in obj
#$(patsubst pattern,replacement,text)
OBJ_FILES = $(patsubst $(SOURCE_DIR)/%.c, $(OBJECT_DIR)/%.o, $(SOURCE_FILES))

# Default target
all: create_dir $(TARGET) nm
	@$(ECHO) "$(GREEN)***********************************************$(RESET)"
	@$(ECHO) "$(GREEN)*********** Build Successful ******************$(RESET)"
	@$(ECHO) "$(GREEN)***********************************************$(RESET)"

# Rule to link object files and create the executable
$(TARGET): $(OBJ_FILES)
    #Link object files to create an ELF file
	$(ECHO) "$(CYAN)Generating $(TARGET_ELF) from the obj files$(RESET)"
	@$(LD) -o $(TARGET_ELF) $(OBJ_FILES) $(LDFLAGS) 

    #Generate a binary file
	$(ECHO) "$(CYAN)Generating $(TARGET_BINARY) File from the $(TARGET_ELF)$(RESET)"
	@$(OBJCOPY) -O binary $(TARGET_ELF) $(TARGET_BINARY)

    #Generate a hex file
	$(ECHO) "$(CYAN)Generating $(TARGET_HEX) File from the $(TARGET_ELF)$(RESET)"
	@$(OBJCOPY) -O ihex $(TARGET_ELF) $(TARGET_HEX)

# Rule to compile .c files to .o files
$(OBJECT_DIR)/%.o: $(SOURCE_DIR)/%.c
	$(ECHO) "$(YELLOW)Compiling $< into $@$(RESET)"
	@if $(COMPILE_CALL) -c -o $@ $<; then\
		echo "$(GREEN)Compilation successful!$(RESET)";\
	else\
		echo "$(RED)Compilation failed!$(RESET)";\
	fi
	@$(COMPILE_CALL) -MM $< > $(OBJECT_DIR)/$*.d

#Clean up build artifacts
clean:
	$(ECHO) "Cleaning up generated files..."
	$(RM) $(OBJECT_DIR) $(FULL_BIN_DIR)

#Target to create necessary directories
create_dir:
	$(ECHO) "Creating directories: $(OBJECT_DIR) and $(FULL_BIN_DIR)"
	$(MKDIR) $(OBJECT_DIR) $(FULL_BIN_DIR)

read_elf:
#This displays detailed information about the ELF file
	$(ECHO) "Verifying elf file..."
	$(READ_ELF) -a $(TARGET_ELF)

obj_dump:	
#Useful for debugging and examining the assembly code.
	$(ECHO) "Disassembling elf file for debugging..."
	$(OBJDUMP) -d $(TARGET_ELF)
    #Example to check one array - arm-none-eabi-objdump -t program.elf | grep my_read_only_array

nm:
#nm to inspect the symbols in the ELF file
	$(ECHO) "$(MAGENTA)Inspecting the symbols in the ELF file for information...$(RESET)"
	$(NM) $(TARGET_ELF) | grep -E "_sdata|_edata|_sbss|_ebss|_estack|_la_data|Reset_Handler|Default_Handler"
help:
	@$(ECHO) "Available Targerts"
	@$(ECHO) " all        - (Default)"
	@$(ECHO) " clean      - Clean up build artifacts"
	@$(ECHO) " create_dir - Target to create necessary directories"
	@$(ECHO) " read_elf   - This displays detailed information about the ELF file"
	@$(ECHO) " obj_dump   - Useful for debugging and examining the assembly code."
	@$(ECHO) " nm         - to inspect the symbols in the ELF file "

# Phony targets
.PHONY: all clean
