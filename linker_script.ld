ENTRY(Reset_Handler) /* The ENTRY(Reset_Handler) specifies the entry point of your program (usually the reset vector). */

/* Define memory regions */
MEMORY {
    /* FLASH is typically where code and constants are stored. */
    FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 512K  /* Adjust size and address for your MCU */
    /* RAM is used for runtime data like stack, heap, and variables.*/
    RAM (rw)   : ORIGIN = 0x20000000, LENGTH = 128K  /* Adjust size and address for your MCU */
}

/* Sections */
SECTIONS 
{
    /* Vector table and text */
    .isr_vector : 
    {
        KEEP(*(.isr_vector))
    } > FLASH

    /* .text: Stores executable code and read-only data. */
    .text : 
    {
        *(.text*)
        *(.rodata*)   /* Read-only data */
    } > FLASH

    /* Initialized data in RAM, loaded from FLASH */ /* .data: Initialized variables copied from FLASH to RAM during startup. */
    .data : 
    {
        _sdata = .;        /* Start of .data section in RAM */
        *(.data*)
        _edata = .;        /* End of .data section in RAM */
    } > RAM AT > FLASH

    /* Uninitialized data (zero-initialized at runtime) */ /* .bss: Uninitialized variables (zero-initialized by the startup code). */
    .bss : 
    {
        _sbss = .;         /* Start of .bss section */
        *(.bss*)
        *(COMMON)
        _ebss = .;         /* End of .bss section */
    } > RAM

    /* Stack pointer */
    _estack = ORIGIN(RAM) + LENGTH(RAM); /* Top of the stack */
    __stack_size = 1K;

    /* For copying initialized data from FLASH to RAM */
    _la_data = LOADADDR(.data); /* Start of .data in FLASH */
}
