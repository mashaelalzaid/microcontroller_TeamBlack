    li t0, 0x10000000      # Base memory address

    li t1, 0x00000013     # Load instruction
    sw t1, 0(t0)          # Store to memory

    li t1, 0x200005B7
    sw t1, 4(t0)

    li t1, 0x10058593
    sw t1, 8(t0)

    li t1, 0x0000F537
    sw t1, 12(t0)

    li t1, 0xFFF50513
    sw t1, 16(t0)

    li t1, 0x00A5A423
    sw t1, 20(t0)

    li t1, 0x00F00513
    sw t1, 24(t0)

    li t1, 0x00A5A223
    sw t1, 28(t0)

    li t1, 0x10000637
    sw t1, 32(t0)

    li t1, 0x00060613
    sw t1, 36(t0)

    li t1, 0x000600E7
    sw t1, 40(t0)

    li t1, 0x00000013
    sw t1, 44(t0)

    li t1, 0x00000013
    sw t1, 48(t0)

    li t1, 0x00000013
    sw t1, 52(t0)
    jalr t0
    nop