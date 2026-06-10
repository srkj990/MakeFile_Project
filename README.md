# MakeFile Project

This repository is an embedded C firmware project for an ARM Cortex-M target using FreeRTOS and a hand-written Makefile-based build system. It demonstrates how to organize application source files, FreeRTOS kernel sources, startup code, linker memory layout, build artifacts, and optional firmware signing/encryption scripts in one project.

The current build is configured for a Cortex-M4F target using the `arm-none-eabi` GNU toolchain. The output firmware is generated as ELF, BIN, Intel HEX, and Motorola S-record files.

## Project Contents

```text
.
|-- .github/workflows/      GitHub Actions workflow files
|-- FreeRTOS/               FreeRTOS kernel source tree and portable ports
|-- include/                Project header files
|-- source/                 Project application, startup, and syscall sources
|-- build/                  Makefile, linker script, helper scripts, and build output
|   |-- makefile            Main build file
|   |-- linker_script.ld    Target memory map and section placement
|   |-- build.sh            Firmware sign/encrypt/verify script
|   |-- build_copy.sh       Alternate sign/encrypt/verify script
|   |-- b.bat               Windows helper: clean and rebuild
|   |-- m.bat               Windows helper: build only
|   |-- objects/            Generated object and dependency files
|   `-- Full_bin/           Generated firmware images
`-- README.md
```

## Important Files

| File | Purpose |
| --- | --- |
| `source/main.c` | Application entry point. Creates two FreeRTOS tasks and starts the scheduler. |
| `source/sample1.c` | Sample application module used by one task. Also defines a large global array and a custom-section array. |
| `source/sample2.c` | Sample application module used by the other task. |
| `source/startup.c` | Startup code, vector table, reset handler, memory initialization, and default interrupt handlers. |
| `source/syscalls.c` | Minimal syscall stubs required when linking embedded C code with newlib/nosys-style environments. |
| `include/sample1.h`, `include/sample2.h` | Project headers for sample modules. |
| `build/makefile` | Main build automation file. Compiles project and FreeRTOS sources, links the ELF, and creates firmware images. |
| `build/linker_script.ld` | Defines FLASH/RAM/ITCM/DTCM/SRAM regions and places `.text`, `.data`, `.bss`, `.isr_vector`, and `.my_section`. |
| `build/build.sh` | Optional post-build script that signs, encrypts, appends metadata, and verifies firmware. |
| `build/build_copy.sh` | Alternate version of the signing/encryption/verification flow. |

## Application Flow

1. On reset, the CPU starts from the vector table in `source/startup.c`.
2. The first vector entry sets the initial stack pointer from `_estack`, which is provided by `build/linker_script.ld`.
3. The reset vector calls `Reset_Handler()`.
4. `Reset_Handler()` copies initialized data from FLASH to RAM using `_la_data`, `_sdata`, and `_edata`.
5. `Reset_Handler()` clears the `.bss` section using `_sbss` and `_ebss`.
6. `Reset_Handler()` calls `main()`.
7. `main()` creates two FreeRTOS tasks:
   - `vTask1()` repeatedly calls `Sub_main1()`.
   - `vTask2()` repeatedly calls `Sub_main2()`.
8. `main()` starts the FreeRTOS scheduler with `vTaskStartScheduler()`.
9. FreeRTOS schedules the two tasks according to their priority and tick configuration.
10. If the scheduler exits unexpectedly, `main()` falls into an infinite loop.

## Build Flow

The main Makefile is located in the `build` directory. It expects to be run from inside `build` because paths are relative to that directory.

The default `make all` target performs this sequence:

1. `create_dir`
   - Creates `objects/`.
   - Creates `Full_bin/`.
   - Creates nested object directories that mirror source paths.

2. Compile phase
   - Compiles application sources from `../source`.
   - Compiles selected FreeRTOS kernel sources from `../FreeRTOS/Source`.
   - Compiles the GCC ARM Cortex-M4F FreeRTOS port.
   - Compiles the `heap_4.c` FreeRTOS heap implementation.
   - Generates `.d` dependency files next to object files.

3. `generate_elf`
   - Links all object files into `Full_bin/program.elf`.
   - Uses `linker_script.ld`.
   - Generates `Full_bin/program.map`.

4. `generate_bin`
   - Converts the ELF file to raw binary: `Full_bin/program.bin`.

5. `generate_hex`
   - Converts the ELF file to Intel HEX: `Full_bin/program.hex`.

6. `generate_s19`
   - Converts the ELF file to Motorola S-record: `Full_bin/program.s19`.

7. `nm`
   - Prints selected linker/startup symbols for inspection, including `_sdata`, `_edata`, `_sbss`, `_ebss`, `_estack`, `_la_data`, `Reset_Handler`, and `Default_Handler`.

## Prerequisites

Install the following tools and make sure they are available in your terminal `PATH`:

- `make`
- `arm-none-eabi-gcc`
- `arm-none-eabi-ld`
- `arm-none-eabi-objcopy`
- `arm-none-eabi-nm`
- `arm-none-eabi-readelf`
- `arm-none-eabi-objdump`
- `grep`
- Optional for signing/encryption scripts: `openssl`, `xxd`, `dd`, `cmp`, `diff`, `stat`, `wc`, and a Bash-compatible shell

On Windows, the Makefile uses Unix-style commands such as `mkdir -p`, `rm -rf`, and `grep`, so run it from Git Bash, MSYS2, WSL, or another shell that provides these tools.

For Windows Command Prompt setup, run the repository setup script:

```bat
setup_dependencies.bat
```

The script installs/checks Git, MSYS2 build utilities, OpenSSL, and Arm GNU Toolchain commands such as `arm-none-eabi-gcc`.

## Usage

From the repository root, enter the build directory:

```sh
cd build
```

Show available Makefile targets:

```sh
make help
```

Build the firmware:

```sh
make all
```

Clean generated files:

```sh
make clean
```

Clean and rebuild:

```sh
make clean
make all
```

Inspect the generated ELF file:

```sh
make read_elf
```

Disassemble the generated ELF file:

```sh
make obj_dump
```

Print selected symbols from the ELF file:

```sh
make nm
```

On Windows, the helper batch files in `build/` can also be used:

```bat
m.bat
```

or:

```bat
b.bat
```

`m.bat` runs `make all`. `b.bat` runs `make clean` followed by `make all`.

## Build Outputs

After a successful build, generated firmware files are placed in `build/Full_bin/`:

| Output | Description |
| --- | --- |
| `program.elf` | Linked executable with symbols and debug/link information. |
| `program.map` | Linker map showing memory placement and symbols. |
| `program.bin` | Raw binary firmware image. |
| `program.hex` | Intel HEX firmware image. |
| `program.s19` | Motorola S-record firmware image. |

Object and dependency files are placed under `build/objects/`.

## Optional Firmware Signing and Encryption

After `program.bin` has been generated, the scripts in `build/` can create signed and encrypted firmware packages.

Run from the `build` directory:

```sh
./build.sh
```

The script performs these high-level steps:

1. Creates `SecureBin/` and `SecureVerify/` output directories.
2. Generates an RSA-2048 key pair.
3. Generates AES/CMAC keys.
4. Computes a SHA-256 hash of `Full_bin/program.bin`.
5. Computes an AES-CMAC over the firmware.
6. Encrypts the firmware using AES-256-CBC.
7. Signs the firmware hash using the RSA private key.
8. Appends encrypted firmware, signature, CMAC, and IV into one package.
9. Extracts the package components again for verification.
10. Decrypts the firmware and verifies signature and CMAC values.

Typical generated files include:

```text
build/SecureBin/signed_encrypted_firmware.bin
build/SecureBin/private_key.pem
build/SecureBin/public_key.pem
build/SecureBin/public_key.der
build/SecureBin/encrypted_firmware.bin
build/SecureBin/signature.bin
build/SecureBin/firmware_cmac.bin
build/SecureVerify/firmware_decrypted.bin
```

`build_copy.sh` provides a similar alternate implementation of the same signing, encryption, extraction, and verification idea.

## Linker and Memory Layout

`build/linker_script.ld` defines these memory regions:

| Region | Origin | Length | Intended use |
| --- | --- | --- | --- |
| `FLASH` | `0x08000000` | `512K` | Vector table, code, constants, load image for initialized data. |
| `RAM` | `0x20000000` | `128K` | Runtime data, `.data`, `.bss`, stack. |
| `ITCM` | `0x00000000` | `64K` | Custom `.my_section` placement. |
| `DTCM` | `0x20010000` | `64K` | Defined for target-specific use. |
| `SRAM` | `0x20020000` | `128K` | Defined for target-specific use. |

The project places `custom_section_Array` from `source/sample1.c` into `.my_section`, which the linker maps to `ITCM`.

## FreeRTOS Integration

The Makefile currently builds these FreeRTOS files:

- `queue.c`
- `list.c`
- `tasks.c`
- `timers.c`
- `event_groups.c`
- `portable/GCC/ARM_CM4F/port.c`
- `portable/MemMang/heap_4.c`

The include path uses `FreeRTOS/Source/examples/coverity`, which contains the `FreeRTOSConfig.h` used by this build.

## Notes

- The Makefile is intended to run from `build/`, not from the repository root.
- Generated artifacts are currently present in the repository under `build/objects/` and `build/Full_bin/`.
- The linker script memory addresses are example Cortex-M style addresses and may need adjustment for a real target MCU.
- The startup file provides default interrupt handlers that loop forever. Replace these with board-specific handlers as needed.
- `source/syscalls.c` contains minimal stubs. Add real implementations if the application needs file I/O, dynamic allocation through `_sbrk`, or serial console output.
