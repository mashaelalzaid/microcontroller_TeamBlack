
########################################################################### start of configurations ###########################################################################
nop
nop
lui x10, 0x20000
addi x10, x10, 0x003 # access the address of Line Control Register
# UART address: 0x2000_0000

# set UART config for devisor (baudrate config)
# modify-config mode = 1
li x11, 0x9b
sw x11, 0(x10)

# set value used to get right baudrate
# equation: value = sys_clk / (16 * baudrate
#           {D2, D1} = 50MHz / (16 * 9600Hz)
# set address D2
lui x10, 0x20000
addi x10, x10, 0x001

# store on MSB latch
addi x11,x0 , 0x01
sw x11, 0(x10)

# set address D1
lui x10, 0x20000
addi x10, x10, 0x000

# store on LSB latch
addi x11,x0 ,0x46
sw x11, 0(x10)


# rx - tx
# close modify-config mode of UART to start working based on that config set before
# modify-config mode = 0
lui x10, 0x20000
addi x10, x10, 0x003
li x11, 0x1b
sw x11, 0(x10)
########################################################################### end of configurations ############################################################################
################################################################################ bootloader ##################################################################################
li x10,0x20000000
li x12,0x10000000 # inst mem address
li x13,512 # number of bytes that should be sent 512 byte /4 = 128 instructions
Listen:
    lw x11, 5(x10) # addr 5 is the status register
    andi x11, x11, 1
    beq x11, x0, Listen # if x11 is zero then keep listining
# here the data is recieved
lw x11,0(x10) # load the data from Rx
nop
nop
nop
sw x13,0(x10) # send x13
nop
nop
sb x11,0(x12) # store the data in n-th mem location
nop
nop
nop
addi x12, x12, 1
addi x13, x13, -1
beq x13, x0, exit
nop
nop
j Listen
nop
nop
nop
li x11,0xabcdef # load HEX 0xabcdef to indicate end of instructions
nop
nop
nop
sw x11,0(x10) # send 0xabcdef
nop
nop
nop
exit: #give control to the inst memory
li x10, 0x10000000
nop
nop
nop
jalr x10
nop
nop
nop
nop