# RISC-V ECALL Test Program

.equ DELAY, 1

.text
    # Initialize stack pointer
    li sp, 0xff       # Set stack pointer

    # Setup trap handler address in mtvec
    la t0, trap_handler
    nop
    nop
    csrrw x0, 0x305, t0      # mtvec = 0x305
    nop
    
    # Enable global interrupts in mstatus
    li t0, 0x8          # Set bit 3 (MIE - Machine Interrupt Enable)
    nop
    nop
    csrrw x0, 0x300, t0      # mstatus = 0x300
    
    # Initialize counter A = 42 for our test
    li a0, 42
    nop
    # Display initial value on LEDs
    li t0, 0x20000104    # LED control register address
    nop
    nop
    sw a0, 0(t0)        # Display initial counter value on LEDs

    # Execute ECALL instruction to test exception handling
    ecall                # This should trigger our trap handler

    # After returning from ECALL, set another value to verify we returned
    li a0, 13
    nop
    nop
    # Update LEDs with new value to verify main program continues
    li t0, 0x20000104   # LED control register address
    nop
    nop
    sw a0, 0(t0)        # Display updated value on LEDs
    
# Main infinite loop
main_loop:
    nop
    nop
    j main_loop

# Trap handler 
.align 4  # Ensure 4-byte alignment
trap_handler:
    # Save registers on stack
    addi sp, sp, -64    # Allocate stack space
    sw ra, 0(sp)        # Save return address
    sw t0, 4(sp)        # Save temporary registers
    sw t1, 8(sp)
    sw t2, 12(sp)
    sw a1, 16(sp)
    
    # Check if it's an ECALL (mcause = 11)
    csrrw x0, 0x342  , t0    # Read mcause
    li t1, 11           # ECALL from M-mode has cause 11
    nop
    nop
    bne t0, t1, not_ecall
    
    # It's an ECALL - add 5 to a0
    addi a0, a0, 5
    nop
    nop
    
    # Update LEDs to show we're in the trap handler
    li t0, 0x20000104   # LED control register address
    nop
    nop
    sw a0, 0(t0)        # Display a0 value on LEDs
    
    # Add a delay to make the LED change visible
    li a1, 0
    nop
    nop
    lui t2, 0xfff       # Delay constant
    nop
    nop

    
not_ecall:
    # Get the return address and add 4 to point to next instruction
    csrrw x0, 0x341, t0      # Read mepc
    addi t0, t0, 4      # Point to next instruction
    csrrw x0, 0x341, t0      # Update mepc
    
    # Restore registers from stack
    lw a1, 16(sp)
    lw t2, 12(sp)
    lw t1, 8(sp)
    lw t0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 64     # Restore stack pointer
    
    # Return from trap
    nop 
    nop
    mret 
    nop                 # Return from trap
