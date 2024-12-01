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

#root directory
ROOT = ..
# Directories
SOURCE_DIR = $(ROOT)/source
OBJECT_DIR = objects
INCLUDE_DIRS = \
	$(ROOT)/FreeRTOS/Source/include \
	$(ROOT)/FreeRTOS/Source/portable/GCC/ARM_CM4F \
	$(ROOT)/FreeRTOS/Source/portable/MemMang \
	$(ROOT)/FreeRTOS/Source/examples/coverity \
	$(ROOT)/include

INCLUDE_FLAGS = $(addprefix -I, $(INCLUDE_DIRS))
FULL_BIN_DIR = Full_bin

APP_SRC = \
    $(ROOT)/source/main.c \
    $(ROOT)/source/sample1.c \
    $(ROOT)/source/sample2.c \
    $(ROOT)/source/startup.c \
    $(ROOT)/source/syscalls.c

FREERTOS_SRC = \
    $(ROOT)/FreeRTOS/Source/queue.c \
    $(ROOT)/FreeRTOS/Source/list.c \
	$(ROOT)/FreeRTOS/Source/tasks.c \
    $(ROOT)/FreeRTOS/Source/timers.c \
    $(ROOT)/FreeRTOS/Source/event_groups.c \
    $(ROOT)/FreeRTOS/Source/portable/GCC/ARM_CM4F/port.c \
    $(ROOT)/FreeRTOS/Source/portable/MemMang/heap_4.c

# Target executable
TARGET_BINARY = $(FULL_BIN_DIR)/program.bin
TARGET_HEX = $(FULL_BIN_DIR)/program.hex
TARGET_ELF = $(FULL_BIN_DIR)/program.elf
TARGET_MAP = $(FULL_BIN_DIR)/program.map
TARGET_S19 = $(FULL_BIN_DIR)/program.s19

# Compiler and flags
#CC = gcc
CC = arm-none-eabi-gcc #Use -nostartfiles and -nodefaultlibs to exclude default system startup files and libraries.
LD = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
NM = arm-none-eabi-nm
READ_ELF = arm-none-eabi-readelf
OBJDUMP = arm-none-eabi-objdump

LDFLAGS = -T linker_script.ld -Map=$(TARGET_MAP)
LDFLAGS += #-nostartfiles -nodefaultlibs -Wl,--gc-sections -Wl,
#CFLAGS = -Wall -Werror
CFLAGS = -mcpu=cortex-m4 -mthumb -O2 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -specs=nosys.specs
CFLAGS += $(INCLUDE_FLAGS) 

#COMPILE_CALL = $(CC) $(CFLAGS) $(C_FLAGS_EXTRA)
COMPILE_CALL = $(CC) $(CFLAGS)

C_FLAGS_EXTRA1 = 0 # make all C_FLAGS_EXTRA1=0 or make all C_FLAGS_EXTRA1 = some other value.
C_FLAGS_EXTRA2 = 0 #

ifeq ($(C_FLAGS_EXTRA1),1)
	CFLAGS += -Wextra -Wpedantic
else
	CFLAGS += 
endif

ifeq ($(C_FLAGS_EXTRA2),1)
	CFLAGS += -Wconversion -Wswitch-enum
else
	CFLAGS +=  
endif


# Find all .c files in the source directory
# $(wildcard pattern)
SOURCE_FILES += $(APP_SRC)
SOURCE_FILES += $(FREERTOS_SRC)

# Convert source files in source to object files in obj
#$(patsubst pattern,replacement,text)
OBJ_FILES = $(patsubst $(ROOT)/%, $(OBJECT_DIR)/%, $(SOURCE_FILES:%.c=%.o))

# Default target
all: create_dir build nm

read_obj:
	@$(ECHO) "$(INCLUDE_FLAGS)"
	@$(ECHO) "$(OBJ_FILES)"
#@$(ECHO) "$(SOURCE_FILES)"
#@$(ECHO) "$(OBJ_FILES)"

# Rule to link object files and create the executable
build: generate_elf generate_bin generate_hex generate_s19
	@$(ECHO) "$(GREEN)***********************************************$(RESET)"
	@$(ECHO) "$(GREEN)*********** Build Successful ******************$(RESET)"
	@$(ECHO) "$(GREEN)***********************************************$(RESET)"
	 

generate_elf: $(OBJ_FILES)
    #Link object files to create an ELF file
	$(ECHO) "$(CYAN)Generating $(TARGET_ELF) from the obj files$(RESET)"
	@$(LD) -o $(TARGET_ELF) $(OBJ_FILES) $(LDFLAGS) 

generate_bin: $(TARGET_ELF)
    #Generate a binary file
	$(ECHO) "$(CYAN)Generating $(TARGET_BINARY) File from the $(TARGET_ELF)$(RESET)"
	@$(OBJCOPY) -O binary $(TARGET_ELF) $(TARGET_BINARY)

generate_hex: $(TARGET_ELF)
    #Generate a hex file
	$(ECHO) "$(CYAN)Generating $(TARGET_HEX) File from the $(TARGET_ELF)$(RESET)"
	@$(OBJCOPY) -O ihex $(TARGET_ELF) $(TARGET_HEX)

generate_s19: $(TARGET_ELF)
    #Generate a hex file
	$(ECHO) "$(CYAN)Generating $(TARGET_S19) File from the $(TARGET_ELF)$(RESET)"
	@$(OBJCOPY) -O srec $(TARGET_ELF) $(TARGET_S19)

# Rule to compile .c files to .o files
$(OBJECT_DIR)/%.o: $(ROOT)/%.c
	@$(MKDIR) $(dir $@)
	@$(ECHO) "$(YELLOW)Compiling $< into $(notdir $@)$(RESET)"
	@if $(COMPILE_CALL) -c -o $@ $<; then\
		echo "$(GREEN)Compilation successful!$(RESET)";\
	else\
		echo "$(RED)Compilation failed!$(RESET)";\
	fi
#Rule to create the .d files for dependency tracking from the obj files
	@$(COMPILE_CALL) -MM $< > $(subst .o,.d,$@)

#Clean up build artifacts
clean:
	$(ECHO) "Cleaning up generated files..."
	$(RM) $(OBJECT_DIR) $(FULL_BIN_DIR)

#Target to create necessary directories
create_dir:
	$(ECHO) "Creating directories: $(OBJECT_DIR) and $(FULL_BIN_DIR)"
	$(MKDIR) $(OBJECT_DIR) $(FULL_BIN_DIR)
	$(MKDIR) $(sort $(dir $(OBJ_FILES)))

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
