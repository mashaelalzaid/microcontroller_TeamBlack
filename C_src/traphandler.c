#include <stdint.h>

#define LED_ADDR 0x20000104
#define MTIME_ADDR 0x20000C08
#define MTIMECMP_ADDR 0x20000C00
#define INTERRUPT_INTERVAL 100

volatile uint32_t *led = (uint32_t *)LED_ADDR;
volatile uint32_t *mtime = (uint32_t *)MTIME_ADDR;
volatile uint32_t *mtimecmp = (uint32_t *)MTIMECMP_ADDR;

void trap_handler();

void setup_interrupts() {
    // Set trap handler in mtvec
    uintptr_t trap_handler_addr = (uintptr_t)trap_handler;
    asm volatile (
        "csrw mtvec, %0" :: "r"(trap_handler_addr)
    );

    // Enable timer interrupt in mie
    asm volatile (
        "li t0, 0x80\n"
        "csrs mie, t0\n"
        ::: "t0"
    );

    // Enable global interrupts in mstatus
    asm volatile (
        "li t0, 0x8\n"
        "csrs mstatus, t0\n"
        ::: "t0"
    );

    // Set initial mtimecmp
    *mtimecmp = *mtime + INTERRUPT_INTERVAL;
}

void trap_handler() {
    // Clear interrupt by setting new mtimecmp value
    uint32_t current_time = *mtime;
    *mtimecmp = current_time + INTERRUPT_INTERVAL;

    // Toggle LED
    *led ^= 1;
    
    // Clear timer interrupt in mip
    asm volatile (
        "li t0, 0x80\n"
        "csrc mip, t0\n"
        ::: "t0"
    );
}

int main() {
    setup_interrupts();

    uint32_t counter = 0;
    while (1) {
        counter++;
        if (counter > 0xFFFF) {
            counter = 0;
        }
        *led = counter;
    }
}
