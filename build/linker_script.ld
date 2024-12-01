ENTRY(Reset_Handler) /* The ENTRY(Reset_Handler) specifies the entry point of your program (usually the reset vector). */

/* Define memory regions */
MEMORY 
{
    /* FLASH is typically where code and constants are stored. */
    FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 512K  /* Adjust size and address for your MCU */

    /* RAM is used for runtime data like stack, heap, and variables.*/
    RAM (rw)   : ORIGIN = 0x20000000, LENGTH = 128K  /* Adjust size and address for your MCU */
    
    /* ITCM and DTCM are usually specific to certain ARM Cortex-M processors (e.g., Cortex-M7). */
    ITCM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
    DTCM (rw)  : ORIGIN = 0x20010000, LENGTH = 64K

    /* SRAM may need to be split into multiple sections for heap, stack, and other runtime uses. */
    SRAM (rw)  : ORIGIN = 0x20020000, LENGTH = 128K

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

    /* Custom section for the array */
    .my_section :
    {
        _start_my_section = .;
        *(.my_section*)
        _end_my_section = .;
    } > ITCM

    /* heap definitions for FreeRTOS */
    __heap_size__ = 4K;
    _end_of_heap = _sdata + __heap_size__;

    /* Stack pointer */
    _estack = ORIGIN(RAM) + LENGTH(RAM); /* Top of the stack */
    __stack_size = 2K;

    /* For copying initialized data from FLASH to RAM */
    _la_data = LOADADDR(.data); /* Start of .data in FLASH */
}
