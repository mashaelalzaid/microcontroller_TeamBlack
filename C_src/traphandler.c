#include <stdint.h>

/************************************************************
 * Minimal Bare-Metal RISC-V Program (Mostly in C)
 * 
 * - Sets up stack pointer (SP)
 * - Installs a machine-mode trap handler (timer interrupt)
 * - Increments a counter, displays on LEDs
 * - On each timer interrupt, toggles LEDs briefly
 *
 * Compile with something like:
 *   riscv64-unknown-elf-gcc -march=rv32imac -mabi=ilp32 \
 *       -nostartfiles -nostdlib -o main.elf main.c
 * (Adjust options and toolchain to match your setup.)
 ************************************************************/

#include <stdint.h>

/* ----------------------------------------------------------------
   1) Memory-mapped registers
   Adjust these addresses to match your hardware
   ----------------------------------------------------------------*/
#define LED_REG       (*(volatile uint32_t *)0x20000104)
#define MTIMECMP      ((volatile uint32_t *)0x20000c00)
#define MTIME         ((volatile uint32_t *)0x20000c08)

/* Timer interrupt interval */
#define TIMER_INTERVAL   (250000000u)  /* e.g. "interrupt after ~some cycles" */

/* A maximum for our main counter (like 0xFFFF in your code) */
#define MAX_COUNT        0xFFFF

/* ----------------------------------------------------------------
   2) CSR manipulation macros in (mostly) C + small inline assembly
   ----------------------------------------------------------------*/
static inline void write_csr_mtvec(void (*handler)(void)) {
    /* mtvec <- address of trap handler */
    asm volatile ("csrw mtvec, %0" : : "r"(handler));
}

static inline void set_csr_mie(uint32_t mask) {
    /* mie |= mask */
    asm volatile ("csrs mie, %0" : : "r"(mask));
}

static inline void set_csr_mstatus(uint32_t mask) {
    /* mstatus |= mask */
    asm volatile ("csrs mstatus, %0" : : "r"(mask));
}

static inline void clear_csr_mip(uint32_t mask) {
    /* mip &= ~mask */
    asm volatile ("csrc mip, %0" : : "r"(mask));
}

/*
 * Bits we need:
 *  - mstatus.MIE = (1<<3)
 *  - mie.MTIE    = (1<<7)
 *  - mip.MTIP    = (1<<7)
 */
#define MSTATUS_MIE  (1 << 3)  /* Machine Interrupt Enable bit */
#define MIE_MTIE     (1 << 7)  /* Machine Timer Interrupt Enable bit */
#define MIP_MTIP     (1 << 7)  /* Machine Timer Interrupt Pending bit */

/* ----------------------------------------------------------------
   3) Global counter for main loop
   ----------------------------------------------------------------*/
volatile uint32_t g_counter = 0;

/* ----------------------------------------------------------------
   4) Simple software delay in C
   ----------------------------------------------------------------*/
static void simple_delay(volatile uint32_t count)
{
    while (count--) {
        asm volatile ("nop");
    }
}

/* ----------------------------------------------------------------
   5) Trap handler:
      We split it into two functions:
      - trap_handler (naked): does the manual push/pop + mret
      - trap_handler_c (normal C): does the actual logic
   ----------------------------------------------------------------*/

/* The C part: read mtime, add INTERVAL, write mtimecmp, clear pending bit, 
 * and toggle the LEDs (on then off) with a delay.
 */
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
    LED_REG = 0xFFFF;    /* all bits on */
    simple_delay(0x100000);
    LED_REG = 0x0000;    /* all bits off */
    simple_delay(0x100000);
}

/*
 * The actual interrupt/trap entry in assembly, marked "naked" so the compiler
 * does not generate its own prologue/epilogue. We manually save/restore
 * registers and do "mret" at the end.
 */
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
        /* Call C function to handle the interrupt logic */
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

/* ----------------------------------------------------------------
   6) Main function in (mostly) C
   ----------------------------------------------------------------*/
int main(void)
{
    /*
     * If you're in full control of the environment (no CRT startup),
     * you may want to set the stack pointer here. 
     * In many linker setups, the linker script + reset code do this instead.
     */
    asm volatile ("li sp, 0x0FFFFFFF");

    /* 1) Set trap (interrupt) handler */
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
        simple_delay(2500000);
    }

    /* We never reach here in a true bare-metal infinite loop */
    return 0;
}
