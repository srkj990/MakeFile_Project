### SECTION 1 HOW gcc inputs works

The commands gcc -c input.c and gcc input.c serve different purposes in the compilation process:

gcc -c input.c:

This command compiles the source file input.c into an object file (input.o), but it does not link it. The -c flag tells gcc to stop after the compilation step, generating an object file that contains the compiled code but no executable. This is useful when you want to compile multiple source files separately before linking them together later.
gcc input.c:

This command compiles input.c and also links it to produce an executable file (usually named a.out by default on Unix-like systems). If there are no errors in the code, it will create an executable that you can run directly.


### SECTION 2 - USAGE of $

$@ - expands to the name of the target.

$< - Represents the first prerequisite of the target.
    obj/%.o: src/%.c
	$(CC) -c $< -o $@

    In this case, $< will expand to the specific source file being compiled (e.g., src/file1.c when compiling obj/file1.o).

$^ - Represents all the prerequisites of the target, with duplicates removed.
    my_program: file1.o file2.o file3.o
	$(CC) -o $@ $^c
    
    In this example, $^ will expand to file1.o file2.o file3.o, effectively listing all object files needed to create my_program.


### SECTION 3 - USAGE of Variable Assignment Operators

:=: Immediate evaluation.
=: Deferred evaluation.
?=: Assigns only if the variable is undefined.
+=: Appends to the current value.

CC := gcc                # Immediate assignment
CFLAGS ?= -Wall          # Assign if undefined
LDFLAGS += -lm           # Append to existing


### SECTION 6 - USAGE of wildcard 

$(wildcard pattern)

Using wildcard: The wildcard function in Makefiles is used to retrieve a list of files that match a specified pattern. It allows you to work with groups of files without needing to list each one explicitly, making your Makefile more flexible and easier to maintain.

SRC_FILES = $(wildcard Sample/*.c) collects all .c files from the Sample directory.
# *(matches any string, including an empty string) and ? (matches a single character).

### SECTION 7 - USAGE of patsubst 

The patsubst function in Makefiles is a powerful tool for manipulating strings, specifically for pattern substitution. It allows you to replace parts of file names or paths based on specified patterns.


$(patsubst pattern,replacement,text)

pattern: A pattern to match against parts of the text. It can contain wildcard characters (%).
replacement: The string that will replace the matched parts.
text: The input string(s) where the pattern matching and substitution will occur.

How It Works
patsubst looks for instances of pattern in text and replaces them with replacement.
The % wildcard matches any string of characters, which makes it versatile for file manipulations.


SRC_FILES = Sample/Sample1.c Sample/Sample2.c
OBJ_FILES = $(patsubst Sample/%.c,obj/%.o,$(SRC_FILES))



SECTION 8 - BASIC PATTERNS


In Makefiles for C compilation and executable generation, several types of patterns and constructs are commonly used. Here’s a breakdown of the most important ones:

### 1. Pattern Rules
Pattern rules define how to build targets from prerequisites using a specific pattern. They use the `%` wildcard to match variable parts of filenames.

**Example**:
```makefile
%.o: %.c
	$(CC) -c $< -o $@
```
- This rule says that any `.o` file can be built from a corresponding `.c` file by compiling it. 
- `$<` refers to the first prerequisite (the source file), and `$@` refers to the target (the object file).

### 2. Static Pattern Rules
Static pattern rules allow you to specify explicit targets and prerequisites with a pattern.

**Example**:
```makefile
objects = file1.o file2.o

$(objects): %.o: %.c
	$(CC) -c $< -o $@
```
- Here, you define which specific object files to build, but still use a pattern to specify how to create them.

### 3. Suffix Rules (Deprecated)
Suffix rules were used in older Makefiles but are now largely replaced by pattern rules. They specify how to build files based on their suffixes.

**Example**:
```makefile
.c.o:
	$(CC) -c $< -o $@
```
- This defines that any `.o` file can be created from a `.c` file. However, this is not recommended in modern Makefiles.

### 4. Implicit Rules
Make has built-in implicit rules for common file types. For example, it knows how to compile `.c` files into `.o` files and link them into executables.

- If you have `file.c`, you can simply write:
```makefile
file: file.c
```
- This implicitly uses the rule to compile `file.c` into `file.o` and then link it.

### 5. Using `patsubst`
You can use `patsubst` to create lists of object files from a list of source files.

**Example**:
```makefile
SRC_FILES = Sample/Sample1.c Sample/Sample2.c
OBJ_FILES = $(patsubst Sample/%.c,obj/%.o,$(SRC_FILES))
```
- This creates a list of object files from the source files, changing paths and extensions as needed.

### 6. Order-Only Prerequisites
Using the `|` symbol to specify order-only prerequisites ensures certain actions (like creating directories) happen before building the target, without affecting the target's rebuild condition.

**Example**:
```makefile
obj/%.o: Sample/%.c | create_dir
```
- This ensures `create_dir` runs before compiling the object files, but it won’t cause the object files to rebuild if `create_dir` is updated.

### Summary
These pattern types and rules are essential for efficiently managing the build process in C projects using Makefiles. Understanding how to leverage them helps streamline compilation, linking, and overall project organization.

4. Conditional Color Messages
You can add conditional colors for success or error messages:

makefile
Copy code
all:
	@if gcc -o program main.c; then \
		echo -e "$(GREEN)Build successful!$(RESET)"; \
	else \
		echo -e "$(RED)Build failed!$(RESET)"; \
	fi