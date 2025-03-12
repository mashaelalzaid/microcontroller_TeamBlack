# RISC-V Timer Interrupt System
# With counter value displayed on LEDs
    # Initialize stack pointer
.section .data

.section .data__stack
    .space 1024 * 4
    # .align 8
    __stack_top:

.section .text

    la sp, __stack_top       # Set stack pointer to address 0x0FFFFFFF
    # Setup trap handler address in mtvec
    nop
    nop
    csrrw x0, 0x305, t0      # mtvec = 0x305
    nop
    # Enable timer interrupt in mie
    li t0, 0x80         # Set bit 7 (MTIE - Machine Timer Interrupt Enable)
    nop
    nop
    csrrw x0,0x304, t0      # mie = 0x304
    
    # Enable global interrupts in mstatus
    
    li t0, 0x8          # Set bit 3 (MIE - Machine Interrupt Enable)
    nop
    nop
    csrrw x0, 0x300, t0      # mstatus = 0x300
    
    # Initialize mtime and mtimecmp registers
#     li t0, 0x20000c08  # mtime address
    li t1, 0            # Initial value for mtime (should be 0 already in hardware)
#     sw t1, 0(t0)        # Lower 32 bits
#     sw t1, 4(t0)        # Upper 32 bits
    
    # Set mtimecmp to current time + interval
    li t0, 0x20000c00  # mtimecmp address
    li t2, 250000000         # Interrupt after 100 cycles
    nop
    nop
    sw t2, 0(t0)        # Lower 32 bits
    sw t1, 4(t0)        # upper 32 bits
    # Initialize counter A = 0 for main loop
    li a0, 0
    nop
    # Initialize LED output with counter value (0)
    li t0, 0x20000104    # LED control register address
    nop
    nop
    sw a0, 0(t0)        # Display initial counter value (0) on LEDs

# Main infinite loop (Pink section in flowchart)
main_loop:
    # A = A + 1
    addi a0, a0, 1
    
    # Check if A > 0xFFFF
    li t0, 0xFFFF
    nop
    nop
    ble a0, t0, update_leds
    # If A > 0xFFFF, reset A = 0
    nop
    nop
    li a0, 0
    nop
    nop
update_leds:
    # Update LEDs with current counter value
    li t0, 0x20000104   # LED control register address
    nop
    nop
    sw a0, 0(t0)        # Display current counter value on LEDs
    nop
    nop
    li t5, 2500000
    nop
    nop
    delay:
    addi t5,t5,-1
    bne t5, x0, delay
    nop
    nop
    # Continue the infinite loop
    j main_loop
nop
nop
# Trap handler (Orange section in flowchart)
.align 4  # Ensure 4-byte alignment
trap_handler:
    # 2. Save registers on stack
    addi sp, sp, -64    # Allocate stack space
    sw ra, 0(sp)        # Save return address
    sw t0, 4(sp)        # Save temporary registers
    sw t1, 8(sp)
    sw t2, 12(sp)
    sw t3, 16(sp)
    sw t4, 20(sp)
    sw t5, 24(sp)
    sw a0, 28(sp)       # Save A counter
    sw a1, 32(sp)
    sw a2, 36(sp)
    sw a3, 40(sp)
    sw a4, 44(sp)
    # 1. Clear timer by setting new mtimecmp value
    li t0, 0x20000c00  # mtimecmp address
    li t1, 0x20000c08  # mtime address
    nop
    nop
    # Read current mtime
    lw t2, 0(t1)        # Load lower 32 bits of mtime
    lw t3, 4(t1)        # Load upper 32 bits of mtime
    
    # Set new mtimecmp to current time + interval
    li t4, 250000000         # Interrupt interval (100 cycles)
    nop
    nop
    nop
    add t2, t2, t4      # Add to lower word
    sltu t5, t2, t4     # Check for overflow
    add t3, t3, t5      # Add carry to upper word if needed
    nop
    nop
    nop
    # Write new value to mtimecmp
    sw t2, 0(t0)        # Store lower 32 bits
    sw t3, 4(t0)        # Store upper 32 bits
    

    
    # 3. Clear interrupt signal in mip
    li t0, 0x80         # MTIP bit (bit 7)
    nop
    nop
    csrrc x0, 0x344, t0 # Clear the timer interrupt pending bit, mip = 0x344
    
        # 4. Handle the interrupt - Toggle a status LED
    # Assume status LED register is at address 0x10000004 (separate from counter LEDs)
    li t0, 0x20000104   # Status LED register address
    nop
    nop
       # First turn all LEDs ON
    li t1, 0xFFFF   # All bits set to 1 (all LEDs on)
    nop
    nop
    sw t1, 0(t0) 
#     lw t1, 0(t0)        # Read current status LED state
    
#     # Toggle the status LED
#     li t2, 0x1
    nop
    nop

      #====== Delay  
    li a1 , 0
        nop
    nop
    nop
    li t4, 0x100000
        nop
    nop
    nop
# To:
    For_Loop1:
    addi a1,a1 , 1
        nop
    nop
    nop
    ble a1, t4 , For_Loop1   # Use t4 instead of t2 for comparison
        # Then turn all LEDs OFF
    nop
    nop
    nop
    li t1, 0x0000   # All bits set to 0 (all LEDs off)
    nop
    nop
    sw t1, 0(t0)        # Turn all LEDs off
        nop
    nop
    nop
#     xor t1, t1, t2      # Flip the LSB to toggle status LED
#     sw t1, 0(t0)        # Write back to status LED control
          #====== Delay  
    li a1 , 0
        nop
    nop
    nop
    li t4, 0x100000
        nop
    nop
    nop
# To:
    For_Loop2:
    addi a1,a1 , 1
    nop
    nop
    nop
    ble a1, t4 , For_Loop2   # Use t4 instead of t2 for comparison
    nop
    nop
    nop
    # 5. Restore registers from stack
    lw a4, 44(sp)
    lw a3, 40(sp)
    lw a2, 36(sp)
    lw a1, 32(sp)
    lw a0, 28(sp)       # Restore A counter
    lw t5, 24(sp)
    lw t4, 20(sp)
    lw t3, 16(sp)
    lw t2, 12(sp)
    lw t1, 8(sp)
    lw t0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 64     # Restore stack pointer
    mret
    # 6. Return from trap
     # mret (0x30200073)
