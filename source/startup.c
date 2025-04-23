#include <stdint.h>
#include <string.h>
#include "../include/sample1.h"
// Forward declaration of the default handlers
void Reset_Handler(void);
void Default_Handler(void);
void NMI_Handler(void);
void HardFault_Handler(void);
void MemManage_Handler(void);
void BusFault_Handler(void);
void UsageFault_Handler(void);
void SVC_Handler(void);
void DebugMon_Handler(void);
void PendSV_Handler(void);
void SysTick_Handler(void);
void EXTI0_Handler(void);
void TIM1_UP_Handler(void);
void USART1_Handler(void);
void I2C1_EV_Handler(void);
void *memcpy(void *dest, const void *src, size_t n);
void *memcpy(void *dest, const void *src, size_t n) 
{
    unsigned char *d = dest;
    const unsigned char *s = src;
    while (n--) {
        *d++ = *s++;
    }
    return dest;
}
void *memset(void *s, int c, size_t n); 
void *memset(void *s, int c, size_t n) 
{
    unsigned char *ptr = s;  // Cast the void pointer to a char pointer
    while (n--) {
        *ptr = (unsigned char)c;  // Set each byte of the memory block
        ptr++;  // Move to the next byte
    }
    return s;  // Return the original pointer
}
// External symbols from the linker script
extern unsigned long _estack;    // Top of the stack
extern unsigned long _sdata;     // Start of initialized data
extern unsigned long _edata;     // End of initialized data
extern unsigned long _la_data;   // Start of data in flash
extern unsigned long _sbss;      // Start of uninitialized data
extern unsigned long _ebss;      // End of uninitialized data

// Vector table
__attribute__((section(".isr_vector")))
unsigned long *vector_table[] =
    {
        (unsigned long *)&_estack,           // Initial stack pointer
        (unsigned long *)Reset_Handler,      // Reset handler
        (unsigned long *)NMI_Handler,        // NMI Handler
        (unsigned long *)HardFault_Handler,  // HardFault Handler
        (unsigned long *)MemManage_Handler,  // Memory Management Fault Handler
        (unsigned long *)BusFault_Handler,   // Bus Fault Handler
        (unsigned long *)UsageFault_Handler, // Usage Fault Handler
        0, 0, 0, 0,                     // Reserved
        (unsigned long *)SVC_Handler,        // SVCall Handler
        (unsigned long *)DebugMon_Handler,   // Debug Monitor Handler
        0,                              // Reserved
        (unsigned long *)PendSV_Handler,     // PendSV Handler
        (unsigned long *)SysTick_Handler,    // SysTick Handler
        // Peripheral interrupts start here
        (unsigned long *)EXTI0_Handler,      // EXTI Line 0 Interrupt
        (unsigned long *)TIM1_UP_Handler,    // Timer 1 Update Interrupt
        (unsigned long *)USART1_Handler,     // UART1 Interrupt
        (unsigned long *)I2C1_EV_Handler,    // I2C Event Interrupt
        // Additional peripheral handlers...
};

// Reset handler, called when the system is reset or powered on
void Reset_Handler(void) 
{
    unsigned long *src, *dest;

    // Copy initialized data from flash to RAM
    src = &_la_data;
    for (dest = &_sdata; dest < &_edata; ) 
    {
        *dest++ = *src++;
    }

    // Zero initialize the .bss section
    for (dest = &_sbss; dest < &_ebss; ) 
    {
        *dest++ = 0;
    }

    // Call the main function
    main();

    // If main exits, loop forever
    while (1);
}

// Default handler for interrupts that don't have a specific handler
void Default_Handler(void) 
{
    while (1);
}

/* Handler for Non-Maskable Interrupts (NMI) An NMI is a type of interrupt that
 cannot be ignored or masked by the CPU, meaning that it will always be processed
 immediately, regardless of the current state of the system. */
void NMI_Handler(void) 
{
    while (1);
}

// Handler for hard faults, which occur when the processor encounters an unrecoverable error
void HardFault_Handler(void) 
{
    while (1);
}

// Handler for memory management faults, such as invalid memory accesses
void MemManage_Handler(void) 
{
    while (1);
}

// Handler for bus faults, which occur when the processor encounters an error accessing memory or peripherals
void BusFault_Handler(void) 
{
    while (1);
}

// Handler for usage faults, which occur when the processor encounters an invalid instruction or operand
void UsageFault_Handler(void) 
{
    while (1);
}

// Handler for Supervisor Call (SVC) interrupts, used to request services from the operating system
void SVC_Handler(void) 
{
    while (1);
}

// Handler for debug monitor interrupts, used for debugging and testing
void DebugMon_Handler(void) 
{
    while (1);
}

// Handler for Pendable Service Call (PendSV) interrupts, used for scheduling and synchronization
void PendSV_Handler(void) 
{
    while (1);
}

// Handler for system tick interrupts, which occur at regular intervals
void SysTick_Handler(void) 
{
    while (1);
}

// Handler for External Interrupt 0, triggered by an external event
void EXTI0_Handler(void) 
{
    while (1);
}

// Handler for Timer 1 Update interrupts, triggered when the timer reaches a specific value
void TIM1_UP_Handler(void) 
{
    while (1);
}

// Handler for USART 1 interrupts, triggered by serial communication events
void USART1_Handler(void) 
{
    while (1);
}

// Handler for I2C 1 Event interrupts, triggered by I2C communication events
void I2C1_EV_Handler(void) 
{
    while (1);
}