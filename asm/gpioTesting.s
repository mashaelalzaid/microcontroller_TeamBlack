nop
nop
li x11, 0x20000100 # set up the base address of GPIO
loop:
nop
nop
lh x10, 0(x11) # read the input GPIO
nop
nop
sh x10,2(x11) # write input GPIO to output
j loop