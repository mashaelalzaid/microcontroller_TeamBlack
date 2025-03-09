ENTRY(_start)

SECTIONS
{
    /* Define memory regions */
    . = 0x80000000;  /* Start address of RAM */

    .text : {
        *(.text .text.*)  /* Code section */
    }

    .rodata : {
        *(.rodata .rodata.*)  /* Read-only data */
    }

    .data : {
        *(.data .data.*)  /* Initialized data */
    }

    .bss : {
        *(COMMON)  /* Common symbols */
        *(.bss .bss.*)  /* Uninitialized data */
    }

    /* Stack setup */
    . = ALIGN(4);
    .stack : {
        _stack_start = .;
        . += 0x1000;  /* 4 KB stack */
        _stack_end = .;
    }
}