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
###############################
_start:
    # Receive handshake byte (0xAA)
    call uart_receive
    nop             # NOP after function call
    nop
    nop
    li t0, 0xAA
    bne a0, t0, _start  # If not 0xAA, wait for it
    nop             # NOP after branch
    nop
    nop
    # Send acknowledgment byte (0x55)
    li a0, 0x55
    call uart_send
    nop             # NOP after function call
    nop
    nop
    # Receive first file size (4 bytes)
    call receive_size
    nop             # NOP after function call
    nop
    nop
    li s1, 0x10000000  # Store first file at 0x10000000
    call receive_file
    nop             # NOP after function call
    nop
    nop
    # Receive second file size (4 bytes)
    call receive_size
    nop             # NOP after function call
    nop
    nop
    li s1, 0x00000000  # Store second file at 0x00000000
    call receive_file
    nop             # NOP after function call
    nop
    nop
    li x10, 0x10000000 #give control to instruction memory
    nop
    nop
    nop
    jalr x10
    nop             # NOP after jump
    nop
    nop

# Receive 4-byte size value and store in s2
receive_size:
    call uart_receive
    nop             # NOP after function call
    nop
    nop
    mv s2, a0
    nop             # NOP after register dependency
    nop
    nop
    call uart_receive
    nop             # NOP after function call
    nop
    nop
    slli s2, s2, 8
    or s2, s2, a0
    nop             # NOP after register dependency
    nop
    nop
    call uart_receive
    nop             # NOP after function call
    nop
    nop
    slli s2, s2, 8
    or s2, s2, a0
    nop             # NOP after register dependency
    nop
    nop
    call uart_receive
    nop             # NOP after function call
    nop
    nop
    slli s2, s2, 8
    or s2, s2, a0
    nop             # NOP after register dependency
    nop
    nop
    ret
    nop             # NOP after return
    nop
    nop

# Receive file data and store in memory (s1 = memory address, s2 = size)
receive_file:
    li t1, 0  # Byte counter
recv_loop:
    bge t1, s2, recv_done  # If received all bytes, exit
    nop             # NOP after branch
    nop
    nop
    call uart_receive
    nop             # NOP after function call
    nop
    nop
    sb a0, 0(s1)    # Store byte in memory
    nop             # NOP after memory operation
    nop
    nop
    addi s1, s1, 1  # Increment memory address
    addi t1, t1, 1  # Increment counter
    nop
    nop
    nop
    j recv_loop
    nop             # NOP after jump
    nop
    nop
recv_done:
    ret
    nop             # NOP after return
    nop
    nop

# UART receive function (returns received byte in a0)
uart_receive:
    li t0, 0x20000000  # UART base address
wait_rx:
    lw t1, 5(t0)    # Load status register 
    nop             # NOP after memory load
    nop
    nop
    andi t1, t1, 1  # check if rx status register is set
    nop
    nop
    nop
    beq t1, x0, wait_rx  # Wait if no data received
    nop             # NOP after branch
    nop
    nop
    lw a0, 0(t0)    # Load the data from Rx
    nop             # NOP after memory load
    nop
    nop
    ret
    nop             # NOP after return
    nop
    nop

# UART send function (sends byte in a0)
uart_send:
    li t0, 0x20000000  # UART base address
wait_tx:
    sw a0, 0(t0)    # Send byte
    nop             # NOP after memory store
    nop
    nop
    ret
    nop             # NOP after return
    nop
    nop