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
#define TIMER_INTERVAL   (100u)

/* A maximum for our main counter (like 0xFFFF) */
#define MAX_COUNT        0xFFFF

/* Bits we need for machine interrupts */
#define MSTATUS_MIE  (1 << 3)   /* Machine Interrupt Enable bit */
#define MIE_MTIE     (1 << 7)   /* Machine Timer Interrupt Enable bit */
#define MIP_MTIP     (1 << 7)   /* Machine Timer Interrupt Pending bit */

/* Minimal inline assembly for CSR operations */
static inline void write_csr_mtvec(void (*handler)(void))
{
    /* mtvec <- address of trap handler */
    asm volatile ("csrw mtvec, %0" : : "r"(handler));
}

static inline void set_csr_mie(uint32_t mask)
{
    /* mie |= mask (set bits) */
    asm volatile ("csrs mie, %0" : : "r"(mask));
}

static inline void set_csr_mstatus(uint32_t mask)
{
    /* mstatus |= mask (set bits) */
    asm volatile ("csrs mstatus, %0" : : "r"(mask));
}

static inline void clear_csr_mip(uint32_t mask)
{
    /* mip &= ~mask */
    asm volatile ("csrc mip, %0" : : "r"(mask));
}

/**************************************************************
 * Global counter for main loop
 **************************************************************/
volatile uint32_t g_counter = 0;

/**************************************************************
 * Simple delay routine
 **************************************************************/
static void simple_delay(volatile uint32_t count)
{
    while (count--) {
        asm volatile ("nop");
    }
}

/**************************************************************
 *  _start: The true entry point (matches ENTRY(_start) in the
 *  linker script). We do bare-metal initialization here, then
 *  call main(). If main ever returns, we can loop forever.
 **************************************************************/
__attribute__((naked)) void _start(void)
{
    asm volatile(
        /* 1) Set stack pointer. Adjust if your memory map differs. */
        "li sp, 0x0FFFFFFF        \n\t"

        /* 2) Call main(). The return address after main() 
              is the next instruction, which we can just loop. */
        "call main                \n\t"
        
        /* 3) If main() returns, loop forever. */
        "1:  j 1b                 \n\t"
    );
}

/**************************************************************
 * trap_handler_c: The "C" portion of the interrupt handler.
 *   - Reads mtime, adds TIMER_INTERVAL
 *   - Writes mtimecmp
 *   - Clears interrupt pending bit
 *   - Toggles LEDs with small delays
 **************************************************************/
void trap_handler_c(void)
{
    /* 1) Read current mtime */
    uint32_t lo = MTIME[0];
    uint32_t hi = MTIME[1];

    /* 2) Add the timer interval */
    uint32_t old_lo = lo;
    lo += TIMER_INTERVAL;
    if (lo < old_lo) {
        /* overflow carry */
        hi++;
    }

    /* 3) Write back to mtimecmp */
    MTIMECMP[0] = lo;
    MTIMECMP[1] = hi;

    /* 4) Clear the pending bit in mip (clear MIP.MTIP) */
    clear_csr_mip(MIP_MTIP);

    /* 5) Toggle LED pattern: turn all ON, delay, then turn all OFF, delay */
    LED_REG = 0xFFFF;      /* all bits on */
    simple_delay(0x10);
    LED_REG = 0x0000;      /* all bits off */
    simple_delay(0x10);
}

/**************************************************************
 * trap_handler: Naked function that does:
 *   - Push registers
 *   - Call trap_handler_c()
 *   - Pop registers
 *   - mret
 **************************************************************/
__attribute__((naked)) void trap_handler(void)
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

        /* Call the C handler code */
        "   call   trap_handler_c    \n\t"

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

        /* Return from machine-mode trap */
        "   mret                     \n\t"
    );
}

/**************************************************************
 * main: Our main loop
 **************************************************************/
int main(void)
{
    /* 1) Set the trap handler: mtvec = trap_handler */
    write_csr_mtvec(trap_handler);

    /* 2) Enable machine-timer interrupt in mie (set MTIE=bit7) */
    set_csr_mie(MIE_MTIE);

    /* 3) Enable global interrupts in mstatus (set MIE=bit3) */
    set_csr_mstatus(MSTATUS_MIE);

    /* 4) Initialize mtimecmp to cause the first timer interrupt */
    MTIMECMP[0] = TIMER_INTERVAL;  /* lower 32 bits */
    MTIMECMP[1] = 0;               /* upper 32 bits */

    /* 5) Main loop: increment g_counter, show on LED, do a small delay */
    while (1) {
        g_counter++;

        if (g_counter > MAX_COUNT) {
            g_counter = 0;
        }

        LED_REG = g_counter;  /* display current counter on LEDs */

        /* Simple busy-loop delay so the increment is visible */
        simple_delay(0x10);
    }

    /* We never actually reach here in this bare-metal infinite loop. */
    return 0;
}
