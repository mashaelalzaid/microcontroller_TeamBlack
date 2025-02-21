back:
nop
lui x11, 0x20000    # GPIO base address
addi x11, x11, 0x100#
lui x10, 0xF        # Load 0x0000FFFF for direction
addi x10, x10, -1   #
sw x10, 8(x11)      # Write to direction register (0x108)
addi x10, x0, 0xF   # Set value 0xF
sw x10, 4(x11)      # Write to output register (0x104)
li x12, 0x10000000
jalr x12             # Loop
nop
nop
nop