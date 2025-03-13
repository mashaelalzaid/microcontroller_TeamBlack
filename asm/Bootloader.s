########################################################################### start of configurations ###########################################################################
li sp, 0x000000ff
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
li s0, 0x20000000      # UART base address 
li s2, 0x10000000      # inst mem address 

li s1, 0xAA # hello signal
wait_for_hello:
call read_uart_word    # wait for 0xAA and then respond by 0x55
bne a0,s1,wait_for_hello
# send hello back
li a0, 0x55
call send_uart_word
nop
nop
call read_uart_word    # read size of instructions
# a0 has the number of instructions
mv s3, a0              # Store instruction count in s3
call send_uart_word
nop
nop
receive_instructions:
nop
nop
call read_uart_byte    # a0 will hold the received byte
nop
nop
sb a0, 0(s2)           # store the inst in memory location 
nop
nop
call send_uart_byte
nop
nop
nop
addi s3, s3, -1        # Decrement instruction counter 
addi s2, s2, 1         # Increment memory pointer 
beq s3, zero, send_data     # Branch if all instructions received
nop
nop
j receive_instructions
send_data:
nop
nop
nop
li s2, 0x00000000
call read_uart_word    # read size of data
# a0 has the number of data
mv s3, a0              # Store instruction count in s3
call send_uart_word
receive_data:
nop
nop
call read_uart_byte    # a0 will hold the received word
nop
nop
sb a0, 0(s2)           # store the data in memory location 
nop
nop
call send_uart_byte
nop
nop
nop
addi s3, s3, -1        # Decrement instruction counter 
addi s2, s2, 1         # Increment memory pointer 
beq s3, zero, exit     # Branch if all instructions received
nop
nop
j receive_data
nop
nop
nop
exit:                  # give control to the inst memory
li s0, 0x10000000      # Load jump address
nop
nop
nop
nop
jalr s0                # Jump to loaded program
nop
nop
nop
nop

# return data in a0
read_uart_byte:
    li t0,0x20000000   #UART base address
    addi sp,sp ,-4
    sw ra, 0(sp)
    wait_rx:
    nop
    nop
    nop
    lw t1, 5(t0) # addr 5 is the status register
    andi t1, t1, 1
    beq t1, zero, wait_rx # if t1 is zero then keep listining ; maybe need to add a limit to the times of re try >TODO
    
    # here the data is recieved
    lw a0,0(t0) # load the data from Rx
    nop
    nop
    nop
    nop
    lw ra, 0(sp)
    addi sp,sp ,4
    nop
    nop
    ret
    nop
    nop
    nop
    #end of read_uart_byte
# return data in a0
read_uart_word:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)
    # Read LSB (byte 0) first
    call read_uart_byte
    mv s0, a0            # This is now the least significant byte
    # Read byte 1
    call read_uart_byte
    slli a0, a0, 8       # Shift second byte to bits 8-15
    or s0, s0, a0        # Combine with previous byte
    # Read byte 2
    call read_uart_byte
    slli a0, a0, 16      # Shift third byte to bits 16-23
    or s0, s0, a0        # Combine with previous bytes
    # Read MSB (byte 3) last
    call read_uart_byte
    slli a0, a0, 24      # Shift fourth byte to bits 24-31
    or s0, s0, a0        # Combine with previous bytes
    mv a0, s0            # Move result to return register
    lw s0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 8
    ret
    nop
    nop
    nop
# #end of read_uart_word

# send data should be in a0
send_uart_byte:
    li t0,0x20000000   #UART base address
    nop
    nop
    nop
    sw a0,0(t0)
    nop
    nop
    nop
    ret
    nop
    nop
    nop
    #end of send_uart_byte
    
# send data should be in a0
send_uart_word:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw a0, 8(sp)
    mv s0, a0
    # Extract and send LSB (byte 0) first
    andi a0, s0, 0xff
    call send_uart_byte
    # Send byte 1
    srli a0, s0, 8
    andi a0, a0, 0xff
    call send_uart_byte
    # Send byte 2
    srli a0, s0, 16
    andi a0, a0, 0xff
    call send_uart_byte
    # Send MSB (byte 3) last
    srli a0, s0, 24
    andi a0, a0, 0xff
    call send_uart_byte
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw a0, 8(sp)
    addi sp, sp, 12
    ret
    nop
    nop
    nop
# #end of send_uart_word