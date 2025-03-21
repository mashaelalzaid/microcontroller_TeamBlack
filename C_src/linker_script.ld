ENTRY(_start)

MEMORY
{
    /* Instruction mem 0x10000000 */
    IMEM (rx) : ORIGIN = 0x10000000, LENGTH = 512K
    /*(RAM) 0x00000000 */
    DMEM (rwx) : ORIGIN = 0x00000000, LENGTH = 128K
}

SECTIONS
{
    .text :
    {
        /* Place .start section first to ensure _start is at the beginning */
        *(.start)
        /* Then include the rest of the text sections */
        *(.text*)
        *(.rodata)
        _etext = .;
    } > IMEM

    .data :
    {
        _sdata = .; /*start .data in RAM */
        *(.*data*);
        _edata = .; /* end of .data in RAM */
    } > DMEM AT> IMEM

    .bss :
    {
        _sbss = .; /* start .bss in ram */
        *(.bss)
        *(COMMON)
        _ebss = .; /* end of .bss in RAM */
    } > DMEM
}
