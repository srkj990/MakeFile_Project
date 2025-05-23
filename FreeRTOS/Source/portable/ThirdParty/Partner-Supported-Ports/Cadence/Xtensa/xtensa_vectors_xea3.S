 /*
 * FreeRTOS Kernel <DEVELOPMENT BRANCH>
 * Copyright (C) 2015-2024 Cadence Design Systems, Inc.
 * Copyright (C) 2021 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * https://www.FreeRTOS.org
 * https://github.com/FreeRTOS
 *
 */

/**************************************************************************/
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*  Xtensa exception and interrupt dispatch for XEA3.                     */
/*                                                                        */
/*  Interrupt handlers and user exception handlers support interaction    */
/*  with the RTOS by calling XT_RTOS_INT_ENTER and XT_RTOS_INT_EXIT       */
/*  before and after calling the user's specific interrupt handlers.      */
/*                                                                        */
/*  Users can install application-specific interrupt handlers by calling  */
/*  xt_set_interrupt_handler(). These handlers can be written in C and    */
/*  must follow the C calling convention. The handler table is indexed by */
/*  the interrupt number. Each handler may be provided with an argument.  */
/*                                                                        */
/*  Users can install application-specific exception handlers in the      */
/*  same way, by calling xt_set_exception_handler(). One handler slot is  */
/*  provided for each exception type. Note that some exceptions are       */
/*  handled by the porting layer itself, and cannot be taken over by      */
/*  application code. These are the alloca, syscall, and coprocessor      */
/*  exceptions.                                                           */
/*                                                                        */
/*  Exception handlers can be written in C, and must follow C calling     */
/*  convention. Each handler is passed a pointer to an exception frame as */
/*  its single argument. The exception frame is created on the stack and  */
/*  holds the saved context of the thread that took the exception. If the */
/*  handler returns, the context will be restored and the instruction     */
/*  that caused the exception will be retried. If the handler makes any   */
/*  changes to the saved state in the exception frame, the changes will   */
/*  be applied when restoring the context.                                */
/*                                                                        */
/**************************************************************************/


#include <xtensa/config/core.h>
#include <xtensa/coreasm.h>

#if XCHAL_HAVE_XEA3

#include "xtensa_context.h"

#if (XCHAL_HW_VERSION < XTENSA_HWVERSION_RH_2016_2)
#error Xtensa HW earlier than RH_2016.2 not supported.
#endif

#if XT_STK_XTRA_SZ
#define EXCFRAME_XTRA_OFF(field)        (XT_STK_XTRA_SZ + (field))
#else
#define EXCFRAME_XTRA_OFF(field)        (field)
#endif


//-----------------------------------------------------------------------------
// The entry point vectors are common for call0 and windowed configurations.
//-----------------------------------------------------------------------------

        .extern _DoubleExceptionHandler
        .extern _xtos_exc_dispatch

        .section .DispatchVector.text, "ax"
#if XCHAL_HAVE_VECBASE
        .align  64                      // 64-byte alignment needed when vecbase
#else                                   // is relocatable
        .align  4
#endif

        .org    0                       // Fixed offset for Reset Vector
        .global _DispatchVector
        .weak   _DispatchVector

_DispatchVector:
        j       _JumpToResetHandler

        .org    3                       // Reserved
        .local  _Reserved1

_Reserved1:
        ill

        .org    6                       // Fixed offset for Double Exception Vector
        .global _DoubleExceptionVector
        .weak   _DoubleExceptionVector

_DoubleExceptionVector:
        j       _DoubleExceptionHandler

        .org    9                       // Reserved
        .local  _Reserved2

_Reserved2:
        ill

//-----------------------------------------------------------------------------
// Start of dispatch code.
//-----------------------------------------------------------------------------

        .org    12                      // Fixed offset for Tailchain entry point
        .global _xt_dispatch

_xt_dispatch:
#ifdef __XTENSA_CALL0_ABI__

        // NOTE: for call0, a15 is expected to be holding the previous stack pointer
        // when we get to the Tailchain segment.

        s32si.x4         a2, a15        // Select interrupt, a2 <- (intnum << 2)
        movi             a0,   0
        l32dis.it        a0,  a0        // a0 <- wrapper addr (handler_table[0])
        s32stk           a9, a15, 96    // Set new stack pointer
#if XT_STK_XTRA_SZ
        addi             a1,  a1, -XT_STK_XTRA_SZ       // Adjust for extra save area
#endif
        s32dis.h         a0,  a0        // Jump to handler if interrupt else fall through
                                        // Note this also clears local exclusive monitor

#else // windowed

        s32si.x4        a10,  a1        // Select interrupt, a10 <- (intnum << 2)
        movi             a8,   0
        l32dis.it        a8,  a8        // a8 <- wrapper addr (handler_table[0])
        s32stk           a9,  a1, 96    // Set new stack pointer
#if XT_STK_XTRA_SZ
        addi             a9,  a9, -XT_STK_XTRA_SZ       // Adjust for extra save area
#endif
        s32dis.h         a8,  a8        // Jump to handler if interrupt else fall through
                                        // Note this also clears local exclusive monitor

#endif // __XTENSA_CALL0_ABI__

.Lexit:
        j       _xt_exit

#ifndef __XTENSA_CALL0_ABI__
        .org    36                      // Fixed offset for Underflow segment
        .global _xt_underflow

_xt_underflow:
        l32e     a8,  a1, -64           //  a8 <- [a1-32]
        l32e     a9,  a1, -64           //  a9 <- [a1-28]
        l32e    a10,  a1, -64           // a10 <- [a1-24]
        l32e    a11,  a1, -64           // a11 <- [a1-20]
        l32e    a12,  a1, -64           // a12 <- [a1-16]
        l32e    a13,  a1, -64           // a13 <- [a1-12]
        l32e    a14,  a1, -64           // a14 <- [a1-8]
        l32e    a15,  a1, -64           // a15 <- [a1-4] ; Return (branch to EPC)
#endif

        .org    60                      // Fixed offset for Save/Overflow segment
        .global _xt_save

_xt_save:
#ifdef __XTENSA_CALL0_ABI__
        s32e     a0,  a1, -64           // [a1-64] <-  a0
        s32e     a2,  a1, -48           // [a1-56] <-  a2 ; a2 <- EPC
        s32e     a3,  a1, -64           // [a1-52] <-  a3
        s32e     a4,  a1, -64           // [a1-48] <-  a4
        s32e     a5,  a1, -64           // [a1-44] <-  a5
        s32e     a6,  a1, -64           // [a1-40] <-  a6
        s32e     a7,  a1, -64           // [a1-36] <-  a7
#else
        .global _xt_overflow
_xt_overflow:
#endif
        s32e     a8,  a1, -52           // [a1-32] <-  a8 ;  a8 <- ExcVAddr
        s32e     a9,  a1, -28           // [a1-28] <-  a9 ;  a9 <- PS/SAR
        s32e    a10,  a1, -48           // [a1-24] <- a10 ; a10 <- EPC
        s32e    a11,  a1, -24           // [a1-20] <- a11 ; a11 <- ExcCause
        s32e    a12,  a1, -44           // [a1-16] <- a12 ; a12 <- LBEG
        s32e    a13,  a1, -40           // [a1-12] <- a13 ; a13 <- LEND
        s32e    a14,  a1, -36           // [a1-8]  <- a14 ; a14 <- LCOUNT
        s32e    a15,  a1, -32           // [a1-4]  <- a15 ; a15 <- a1
                                        // If Overflow then return (branch to EPC)

_xt_entry:
        s32e     a8,  a1, -4            // [a1-68] <-  a8 (ExcVAddr)
        s32e    a11,  a1, -8            // [a1-72] <- a11 (ExcCause)
#if XCHAL_HAVE_LOOPS
        s32e    a12,  a1, -20           // [a1-84] <- a12 (LBEG)
        s32e    a13,  a1, -24           // [a1-88] <- a13 (LEND)
        s32e    a14,  a1, -28           // [a1-92] <- a14 (LCOUNT)
#endif
#if XCHAL_HAVE_EXCLUSIVE
        movi    a12,  0
        getex   a12
        s32e    a12,  a1, -32           // [a1-96] <- a12 (ATOMCTL)
#endif
#if (defined __XTENSA_WINDOWED_ABI__) && portUSING_MPU_WRAPPERS
        s32e     a2,  a1, -36           // [a1-100] <- a2 (syscall arg)
#endif

        j       1f                      // make room for literals

        .align  4
        .literal_position

.Le1:
        .word   xt_exception_table

1:
        // Call OS-specific code for additional work to be done. Stay on interruptee's
        // stack in case more saves are required into stack frame.
        // NOTE: OS-specific code can use a8, a12-a14, (+a2-a7: call0, a15: windowed).
        // ALL other registers must be preserved.

        XT_RTOS_INT_ENTER

        // This sequence checks the interrupt controller and loads the interrupt
        // number if available, and also loads the wrapper handler address.
        // If there is an interrupt, execution will branch to the wrapper which
        // will then forward to the correct handler.
        // All this happens only if there is a pending interrupt. If not, execution
        // falls through to exception handling.

#ifdef __XTENSA_CALL0_ABI__

        s32si.x4         a2,  a1        // [a1-80] <- a2 (EPC) ; a2 <- (intnum << 2)
        movi             a0,   0
        l32dis.it        a0,  a0        // a0 <- wrapper addr (handler_table[0])
        s32stk           a9,  a1, 96    // [a1-76] <- a9 (PS/SAR) ; a1 = a1-96
#if XT_STK_XTRA_SZ
        addi             a1,  a1, -XT_STK_XTRA_SZ       // Adjust for extra save area
#endif
        s32dis.h         a0,  a0        // Jump to handler if interrupt else fall through

#else // windowed

        s32si.x4        a10,  a1        // [a1-80] <- a10 (EPC) ; a10 <- (intnum << 2)
        movi             a8,   0
        l32dis.it        a8,  a8        // a8 <- wrapper addr (handler_table[0])

        // Exception frame size is 96 bytes for Windowed,
        // plus an extra 4 bytes if MPU wrappers are used (for XT_STK_A2)
        s32stk           a9,  a1, 96    // [a1-76] <- a9 (PS/SAR) ; a9 = a1-96
#if portUSING_MPU_WRAPPERS && XT_STK_XTRA_SZ
        addi             a9,  a9, -XT_STK_XTRA_SZ-4     // Adjust for extra save area + XT_STK_A2
#elif XT_STK_XTRA_SZ
        addi             a9,  a9, -XT_STK_XTRA_SZ       // Adjust for extra save area
#elif portUSING_MPU_WRAPPERS  
        addi             a9,  a9, -4    // Adjust for XT_STK_A2
#endif
        s32dis.h         a8,  a8        // Jump to handler if interrupt else fall through

#endif // __XTENSA_CALL0_ABI__

        // At this point we have:
        // (note window has rotated for windowed ABI)
        //    a0 holds return address (Tailchain+3)
        // For call0:
        //   a11 holds ExcCause, also saved in [oldsp - 72]
        //   a15 holds exception SP, a1 points to exception frame
        // For windowed:
        //    a3 holds ExcCause, also saved in [oldsp - 72]
        //    a1 holds new SP
        //    New SP + XT_STK_XTRA_SZ points to exception frame

        .global _xt_exception

_xt_exception:
#ifdef __XTENSA_CALL0_ABI__
        mov      a3,  a11                   // Copy exception cause to a3
#endif
        extui    a4,  a3, 0, 4              // Extract exception cause
#if portUSING_MPU_WRAPPERS
        // Handle "RAISE PRIVILEGE" SYSCALL in assembly;
        // others use registered syscall handler
        bnei     a4,  EXCCAUSE_SYSCALL, .L_xt_proc_full_exc
        l32i     a2,  a1, EXCFRAME_XTRA_OFF(XT_STK_A2)  // ExcFrame + A2 offset
        beqi     a2,  SYSCALL_raise_priv, do_raise_priv
        beqi     a2,  SYSCALL_is_priv, do_is_priv

.L_xt_proc_full_exc:
#endif  /* portUSING_MPU_WRAPPERS */
        l32r     a2,  .Le1                  // Load exc table address
        addx4    a2,  a4, a2                // Index into exc table
        l32i     a4,  a2, 0                 // Load handler address
#if XT_STK_XTRA_SZ
        addi     a2,  a1, XT_STK_XTRA_SZ    // Argument = Exception frame ptr
#else
        mov      a2,  a1                    // Argument = Exception frame ptr
#endif
        jx       a4                         // Return directly from handler

#if portUSING_MPU_WRAPPERS
        .align      4
do_is_priv:
        l32i    a2,  a1, EXCFRAME_XTRA_OFF(XT_STK_PS)  // ExcFrame + PS offset
        movi    a4,  1
        extui   a2,  a2, PS_RING_SHIFT, 1
        xor     a2,  a2, a4
        j       privilege_return

        // raise privilege syscall
do_raise_priv:
        l32i    a4,  a1, EXCFRAME_XTRA_OFF(XT_STK_PS)  // ExcFrame + PS offset
        bbsi    a4,  PS_RING_SHIFT, raise_privilege
        movi    a2,  1
privilege_return:
        l32i    a4,  a1, EXCFRAME_XTRA_OFF(XT_STK_PC)  // ExcFrame + PC offset
        addi    a4,  a4, 3                  // ++PC (3-byte syscall instruction)
        s32i    a4,  a1, EXCFRAME_XTRA_OFF(XT_STK_PC)  // ExcFrame + PC offset
        s32i    a2,  a1, EXCFRAME_XTRA_OFF(XT_STK_A2)  // Syscall return value
#ifdef __XTENSA_CALL0_ABI__
        ret.n                               // Emulate end of handler
#else
        retw.n                              // Emulate end of handler
#endif
raise_privilege:
        movi    a2,  ~PS_RING_MASK          // PS.RING = 0
        and     a4,  a4, a2
        s32i    a4,  a1, EXCFRAME_XTRA_OFF(XT_STK_PS)  // ExcFrame + PS offset
        movi    a2,  0
        j       privilege_return
#endif  /* portUSING_MPU_WRAPPERS */

        // Exit/restore sequence

        .global _xt_exit

_xt_exit:
#if portUSING_MPU_WRAPPERS
        mov      a8, a0
        call0    _xt_mpu_restore
        mov      a0, a8
#endif
#ifdef __XTENSA_CALL0_ABI__
        mov      a1, a15                    // Restore stack pointer
#endif

        // Run OS-specific code to determine what to restore.
        // Interrupts will remain disabled through this sequence.
        // WARNING: stack pointer may change within this macro
        // so all restores off the stack must happen afterwards.

        XT_RTOS_INT_EXIT

        .global _xt_restore

_xt_restore:
        // Some loads must happen before DISPST = Restore, as these
        // will not be accessible via L32E once DISPST = Restore.

#if !(defined __XTENSA_CALL0_ABI__) && portUSING_MPU_WRAPPERS
        l32e     a2,  a1, -36           // a2 <- [a1-100] (syscall return)
#endif
#if XCHAL_HAVE_EXCLUSIVE
        l32e    a12,  a1, -32           // a12 <- [a1-96] (ATOMCTL)
        getex   a12
#endif
        l32e    a10,  a1, -12           // a10 <- [a1-76] (PS/SAR)
        l32e    a12,  a1, -20           // a12 <- [a1-84] (LBEG)
        l32e    a13,  a1, -24           // a13 <- [a1-88] (LEND)
        l32e    a14,  a1, -28           // a14 <- [a1-92] (LCOUNT)
        l32dis.epc  a11, a1             // a11 <- [a1-80] (EPC)
                                        // If interrupt goto tailchain else fall through

#ifdef __XTENSA_CALL0_ABI__
        l32e     a0,  a1, -64           // a0 <- [a1-64]
        l32e     a2,  a1, -64           // a2 <- [a1-56]
        l32e     a3,  a1, -64           // a3 <- [a1-52]
        l32e     a4,  a1, -64           // a4 <- [a1-48]
        l32e     a5,  a1, -64           // a5 <- [a1-44]
        l32e     a6,  a1, -64           // a6 <- [a1-40]
        l32e     a7,  a1, -64           // a7 <- [a1-36]
#endif

        // Important: the following restrictions must be observed:
        // 1) The LCOUNT register must be restored after LBEG/LEND.
        // 2) There must be at least 3 instructions between the LCOUNT
        //    restore and the last L32E (the one that branches).

        l32e    a12,  a1, -44           // LBEG   <- a12, a12 <- [a1-16]
        l32e    a13,  a1, -40           // LEND   <- a13, a13 <- [a1-12]
        l32e    a14,  a1, -36           // LCOUNT <- a14, a14 <- [a1-8]
        l32e     a8,  a1, -64           // a8 <- [a1-32]
        l32e     a9,  a1, -64           // a9 <- [a1-28]
        l32e    a10,  a1, -60           // PS/SAR <- a10, a10 <- [a1-24]
        l32e    a11,  a1, -48           // EPC    <- a11, a11 <- [a1-20]
        l32e    a15,  a1, -64           // a15 <- [a1-4], Branch to EPC if no interrupt
                                        // If interrupt, branch to Tailchain


//-----------------------------------------------------------------------------
// Branch to reset handler code from here. Use CALL0 as a branch, will expand
// to CALLX0 if needed when built with the -mlongcalls option.
//-----------------------------------------------------------------------------

        .align  4
        .local  _JumpToResetHandler

_JumpToResetHandler:
        call0   _ResetHandler


//-----------------------------------------------------------------------------
// Scheduler interrupt handler. Triggered by context switch. At this time only
// useful for windowed ABI to spill register windows.
//-----------------------------------------------------------------------------

        .align  4
        .global xt_sched_handler

xt_sched_handler:
#ifdef __XTENSA_WINDOWED_ABI__
        entry   a1, 32
        ssai    1
        spillw
        retw
#else
        ret
#endif


//-----------------------------------------------------------------------------
// Symbols for the debugger to use in identifying interrupt / exception frames.
//-----------------------------------------------------------------------------

        .global _Interrupt
        .set    _Interrupt, _xt_dispatch - 1
        .size   _Interrupt, 1

        .global _GeneralException
        .set    _GeneralException, _xt_dispatch
        .size   _GeneralException, .Lexit - _xt_dispatch

        // Size of interrupt frame
        .global _InterruptFrameSize
        .set    _InterruptFrameSize, XT_STK_FRMSZ

        // Register save offset in interrupt frame
        .global _InterruptRegisterSaveOffset
        .set    _InterruptRegisterSaveOffset, 0x20

        // EPC offset in interrupt frame
        .global _InterruptEPCSaveOffset
        .set    _InterruptEPCSaveOffset, 0x10

        // Size of exc frame
        .global _GeneralExceptionFrameSize
        .set    _GeneralExceptionFrameSize, XT_STK_FRMSZ

        // Register save offset in exc frame
        .global _GeneralExceptionRegisterSaveOffset
        .set    _GeneralExceptionRegisterSaveOffset, 0x20

        // EPC offset in exc frame
        .global _GeneralExceptionEPCSaveOffset
        .set    _GeneralExceptionEPCSaveOffset, 0x10

#endif // XCHAL_HAVE_XEA3
