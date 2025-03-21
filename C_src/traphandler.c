/**************************************************************
 * Example of bare-metal startup in one file:
 *  - _start: the linker/entry point (sets SP, calls main)
 *  - main(): the usual main function
 *  - trap_handler, etc., for interrupts
 *
 * You have a linker script that says:
 *    ENTRY(_start)
 * 
 * And your code includes _start below.
 **************************************************************/

#include <stdint.h>

/* Memory-mapped registers for your hardware */
#define LED_REG       (*(volatile uint32_t *)0x20000104)
#define MTIMECMP      ((volatile uint32_t *)0x20000c00)
#define MTIME         ((volatile uint32_t *)0x20000c08)

/* Timer interrupt interval */
#define TIMER_INTERVAL_LO   (0xfffffff)
#define TIMER_INTERVAL_HI   (0x00)

/* A maximum for our main counter (like 0xFFFF) */
#define MAX_COUNT        0xFFFF

/* Bits we need for machine interrupts */
#define MSTATUS_MIE  0x08   /* Machine Interrupt Enable bit */
#define MIE_MTIE     0x80   /* Machine Timer Interrupt Enable bit */
#define MIP_MTIP     0x80  /* Machine Timer Interrupt Pending bit */

#define DELAY 0x100000
/* Minimal inline assembly for CSR operations */
#define SET_TRAP_HANDLER(handler) \
    asm volatile ( \
        "add zero, zero, %0 \n\t" \
        "add zero, zero, %0 \n\t" \
        "csrw mtvec, %0" \
        : : "r"(handler) \
    )

#define SET_CSR_MIE(value) \
    asm volatile ( \
        "add zero, zero, %0 \n\t" \
        "add zero, zero, %0 \n\t" \
        "csrs mie, %0" \
        : : "r"(value) \
    )

#define SET_CSR_MSTATUS(value) \
    asm volatile ( \
        "add zero, zero, %0 \n\t" \
        "add zero, zero, %0 \n\t" \
        "csrs mstatus, %0" \
        : : "r"(value) \
    )

#define CLEAR_CSR_MIP(value) \
asm volatile ( \
    "add zero, zero, %0 \n\t" \
    "add zero, zero, %0 \n\t" \
    "csrc mip, %0" \
    : : "r"(value) \
)


/**************************************************************
 * Simple delay routine
 **************************************************************/
#define SIMPLE_DELAY(DELAY) \
    do { \
        uint32_t count = DELAY; \
        while (count > 0) { \
            count--; \
        } \
    } while(0)

/**************************************************************
 *  _start: The true entry point (matches ENTRY(_start) in the
 *  linker script). We do bare-metal initialization here, then
 *  call main(). If main ever returns, we can loop forever.
 **************************************************************/
// __attribute__((naked)) void _start(void)
__attribute__((section(".start"))) __attribute__((naked)) void _start(void)
{
    asm volatile(
        /* 1) Set stack pointer. Adjust if your memory map differs. */
        "li sp, 0x1000       \n\t"

        /* 2) Call main(). The return address after main() 
              is the next instruction, which we can just loop. */
        "call main                \n\t"
        
        /* 3) If main() returns, loop forever. */
        "1:  j 1b                 \n\t"
    );
}

/**************************************************************
 * trap_handler: Naked function that does:
 *   - Push registers
 *   - handle int
 *   - Pop registers
 *   - mret
 **************************************************************/
__attribute__((naked, aligned(4))) void trap_handler(void)
{
    asm volatile(
        /* Save registers on stack (64 bytes) */
        "   addi   sp, sp, -64       \n\t"
        "   sw     ra,  0(sp)        \n\t"
        "   sw     t0,  4(sp)        \n\t"
        "   sw     t1,  8(sp)        \n\t"
        "   sw     t2, 12(sp)        \n\t"
        "   sw     t3, 16(sp)        \n\t"
        "   sw     t4, 20(sp)        \n\t"
        "   sw     t5, 24(sp)        \n\t"
        "   sw     a0, 28(sp)        \n\t"
        "   sw     a1, 32(sp)        \n\t"
        "   sw     a2, 36(sp)        \n\t"
        "   sw     a3, 40(sp)        \n\t"
        "   sw     a4, 44(sp)        \n\t"
        "   sw     a5, 48(sp)        \n\t"
        "   sw     a6, 52(sp)        \n\t"
        "   sw     a7, 56(sp)        \n\t"
        "   nop                      \n\t"
        "   nop                      \n\t"
        "   nop                      \n\t"
        );
        /* 4) Clear the pending bit in mip (clear MIP.MTIP) */
        CLEAR_CSR_MIP(MIP_MTIP);
        /* 5) Toggle LED pattern: turn all ON, delay, then turn all OFF, delay */
        LED_REG = 0xFFFF;      /* all bits on */
        SIMPLE_DELAY(DELAY*4);
        LED_REG = 0x0000;      /* all bits off */
        SIMPLE_DELAY(DELAY*4);
        MTIME[0]=0;
        MTIME[1]=0;
        asm volatile(
        /* Restore registers */
        "   lw     a7, 56(sp)        \n\t"
        "   lw     a6, 52(sp)        \n\t"
        "   lw     a5, 48(sp)        \n\t"
        "   lw     a4, 44(sp)        \n\t"
        "   lw     a3, 40(sp)        \n\t"
        "   lw     a2, 36(sp)        \n\t"
        "   lw     a1, 32(sp)        \n\t"
        "   lw     a0, 28(sp)        \n\t"
        "   lw     t5, 24(sp)        \n\t"
        "   lw     t4, 20(sp)        \n\t"
        "   lw     t3, 16(sp)        \n\t"
        "   lw     t2, 12(sp)        \n\t"
        "   lw     t1,  8(sp)        \n\t"
        "   lw     t0,  4(sp)        \n\t"
        "   lw     ra,  0(sp)        \n\t"
        "   addi   sp,  sp, 64       \n\t"
        "   nop                      \n\t"
        "   nop                      \n\t"
        "   nop                      \n\t"
        /* Return from machine-mode trap */
        "   mret                     \n\t"
        "   nop                      \n\t"
        "   nop                      \n\t"
        "   nop                      \n\t"
    );
}

/**************************************************************
 * main: Our main loop
 **************************************************************/
int main(void)
{
    /* 1) Set the trap handler: mtvec = trap_handler */
    // write_csr_mtvec(trap_handler);
    SET_TRAP_HANDLER(trap_handler);

    /* 2) Enable machine-timer interrupt in mie (set MTIE=bit7) */
    // set_csr_mie(MIE_MTIE);
    SET_CSR_MIE(MIE_MTIE);

    /* 3) Enable global interrupts in mstatus (set MIE=bit3) */
    // set_csr_mstatus(MSTATUS_MIE);
    SET_CSR_MSTATUS(MSTATUS_MIE);
    /* 4) Initialize mtimecmp to cause the first timer interrupt */
    MTIMECMP[0] = TIMER_INTERVAL_LO;  /* lower 32 bits */
    MTIMECMP[1] = TIMER_INTERVAL_HI;  /* upper 32 bits */

    uint32_t counter = 1;
    /* 5) Main loop: increment g_counter, show on LED, do a small delay */
    while (1) {
        counter++;
        LED_REG = counter;  /* display current counter on LEDs */
        
        /* Simple busy-loop delay so the increment is visible */
        SIMPLE_DELAY(DELAY);
    }

    /* We never actually reach here in this bare-metal infinite loop. */
    return 0;
}
