typedef unsigned int uint32_t;
typedef int int32_t;

typedef unsigned short uint16_t;
typedef short int16_t;

typedef unsigned char uint8_t;
typedef char int8_t;

typedef unsigned long long uint64_t;
typedef long long int64_t;

#define LED_REG       (*(volatile uint32_t *)0x20000104)

__attribute__((naked)) void _start(void)
{
    asm volatile(
        // 1) Set stack pointer
        "li    sp, 0x0FFFFFFF   \n\t"

        // 2) Call main()
        "call  main            \n\t"

        // 3) If main returns, loop forever
        "1:   j 1b             \n\t"
    );
}

static void simple_delay(volatile uint32_t count)
{
    while (count--) {
        asm volatile ("nop");
    }
}


/**************************************************************
 * main: Our main loop
 **************************************************************/

#define MAX_COUNT 0xFFFF

uint32_t g_counter = 1;


int main(void)
{
    
    /* 5) Main loop: increment g_counter, show on LED, do a small delay */
    while (1) {
        g_counter++;

        if (g_counter > MAX_COUNT) {
            g_counter = 0;
        }

        LED_REG = g_counter;  /* display current counter on LEDs */

        /* Simple busy-loop delay so the increment is visible */
        simple_delay(0x100000);
    }

    /* We never actually reach here in this bare-metal infinite loop. */
    return 0;
}