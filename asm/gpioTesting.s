nop
lui x11, 0x20000    # GPIO base address
addi x11, x11, 0x100#
lui x10, 0xF        # Load 0x0000FFFF for direction
addi x10, x10, -1   #
sw x10, 8(x11)      # Write to direction register (0x108)
######################################################################
back:
li x10, 0xF   # Set value 0xF
sw x10, 4(x11)      # Write to output register (0x104)
call delay
li x10, 0xF0   # Set value 0xF0
sw x10, 4(x11)      # Write to output register (0x104)
call delay
li x10, 0xF00  # Set value 0xF00
sw x10, 4(x11)      # Write to output register (0x104)
call delay
li x10, 0xF000   # Set value 0xF000
sw x10, 4(x11)      # Write to output register (0x104)
call delay
j back
nop
nop
nop


delay:
    li t6, 1
    delay_loop:
        addi t6, t6, -1
        bnez t6, delay_loop
    ret
   