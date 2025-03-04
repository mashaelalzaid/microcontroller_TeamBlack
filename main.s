.section .text
.global _start

_start:
    csrr t0, mcause   # Read the mcause register (CSR instruction)
    mret              # Return from machine mode

    # Exit
    li a7, 10
    ecall
