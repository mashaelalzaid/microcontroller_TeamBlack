`timescale 1ns/1ps

module csr_file_tb;
    // Clock and reset signals
    logic clk;
    logic reset_n;
    
    // CSR Interface signals
    logic [11:0] csr_addr;
    logic [31:0] csr_wdata;
    logic        csr_wen;
    logic [2:0]  csr_op;
    logic [31:0] csr_rdata;
    
    // Interrupt signals
    logic        timer_int;
    
    // Trap handling signals
    logic [31:0] current_pc;
    logic        trap_taken;
    logic [31:0] trap_pc;
    
    // MRET signals
    logic        mret_exec;
    logic [31:0] mret_pc;
    
    // CSR Addresses
    localparam CSR_MSTATUS  = 12'h300;
    localparam CSR_MIE      = 12'h304;
    localparam CSR_MTVEC    = 12'h305;
    localparam CSR_MSCRATCH = 12'h340;
    localparam CSR_MEPC     = 12'h341;
    localparam CSR_MCAUSE   = 12'h342;
    localparam CSR_MIP      = 12'h344;
    
    // CSR operations
    localparam CSR_WRITE = 3'b001;  // CSRRW
    localparam CSR_SET   = 3'b010;  // CSRRS
    localparam CSR_CLEAR = 3'b011;  // CSRRC
    
    // Instantiate the DUT
    csr_file dut (
        .clk(clk),
        .reset_n(reset_n),
        .csr_addr(csr_addr),
        .csr_wdata(csr_wdata),
        .csr_wen(csr_wen),
        .csr_op(csr_op),
        .csr_rdata(csr_rdata),
        .timer_int(timer_int),
        .current_pc(current_pc),
        .trap_taken(trap_taken),
        .trap_pc(trap_pc),
        .mret_exec(mret_exec),
        .mret_pc(mret_pc)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Test sequence
    initial begin
        // Initialize signals
        reset_n = 0;
        csr_addr = 0;
        csr_wdata = 0;
        csr_wen = 0;
        csr_op = 0;
        timer_int = 0;
        current_pc = 32'h1000;
        mret_exec = 0;
        
        // Apply reset
        #20;
        reset_n = 1;
        #10;
        
        // Display header
        $display("=== CSR File Testbench ===");
        $display("Testing reset state of all CSRs...");
        
        // Test 1: Check reset values
        check_csr_reset_values();
        
        // Test 2: Test CSR write operations for all CSRs
        $display("\nTesting CSR write operations...");
        test_csr_write_operations();
        
        // Test 3: Test CSR set and clear operations
        $display("\nTesting CSR set operations...");
        test_csr_set_operations();
        
        $display("\nTesting CSR clear operations...");
        test_csr_clear_operations();
        
        // Test 4: Test timer interrupt
        $display("\nTesting timer interrupt handling...");
        test_timer_interrupt();
        
        // Test 5: Test MRET instruction
        $display("\nTesting MRET instruction...");
        test_mret_instruction();
        
        // Test 6: Test vector mode of MTVEC
        $display("\nTesting vectored interrupt mode...");
        test_vectored_interrupt_mode();
        
        // Test 7: Test timer interrupt when global interrupts are disabled
        $display("\nTesting disabled interrupts...");
        test_disabled_interrupts();
        
        // Test 8: Test timer interrupt when timer interrupts are disabled in MIE
        $display("\nTesting disabled timer interrupts...");
        test_disabled_timer_interrupts();
        
        // Finish simulation
        $display("\n=== All tests completed ===");
        #20;
        $finish;
    end
    
    // Task to check reset values of all CSRs
    task check_csr_reset_values();
        // Read all CSRs after reset
        read_csr(CSR_MSTATUS);
        assert(csr_rdata == 32'h0) 
            $display("✓ MSTATUS reset value correct");
        else
            $error("✗ MSTATUS reset value incorrect. Got %h, expected 0", csr_rdata);
            
        read_csr(CSR_MIE);
        assert(csr_rdata == 32'h0)
            $display("✓ MIE reset value correct");
        else
            $error("✗ MIE reset value incorrect. Got %h, expected 0", csr_rdata);
            
        read_csr(CSR_MTVEC);
        assert(csr_rdata == 32'h0)
            $display("✓ MTVEC reset value correct");
        else
            $error("✗ MTVEC reset value incorrect. Got %h, expected 0", csr_rdata);
            
        read_csr(CSR_MSCRATCH);
        assert(csr_rdata == 32'h0)
            $display("✓ MSCRATCH reset value correct");
        else
            $error("✗ MSCRATCH reset value incorrect. Got %h, expected 0", csr_rdata);
            
        read_csr(CSR_MEPC);
        assert(csr_rdata == 32'h0)
            $display("✓ MEPC reset value correct");
        else
            $error("✗ MEPC reset value incorrect. Got %h, expected 0", csr_rdata);
            
        read_csr(CSR_MCAUSE);
        assert(csr_rdata == 32'h0)
            $display("✓ MCAUSE reset value correct");
        else
            $error("✗ MCAUSE reset value incorrect. Got %h, expected 0", csr_rdata);
            
        read_csr(CSR_MIP);
        assert(csr_rdata == 32'h0)
            $display("✓ MIP reset value correct");
        else
            $error("✗ MIP reset value incorrect. Got %h, expected 0", csr_rdata);
    endtask
    
    // Task to test CSR write operations
    task test_csr_write_operations();
        // Test MSTATUS write
        write_csr(CSR_MSTATUS, 32'hAABBCCDD, CSR_WRITE);
        read_csr(CSR_MSTATUS);
        $display("MSTATUS after write: %h", csr_rdata);
        
        // Test MIE write
        write_csr(CSR_MIE, 32'h00000080, CSR_WRITE); // Enable timer interrupt
        read_csr(CSR_MIE);
        assert(csr_rdata == 32'h00000080)
            $display("✓ MIE write successful");
        else
            $error("✗ MIE write failed. Got %h, expected 0x00000080", csr_rdata);
        
        // Test MTVEC write - direct mode
        write_csr(CSR_MTVEC, 32'h80000000, CSR_WRITE);
        read_csr(CSR_MTVEC);
        assert(csr_rdata == 32'h80000000)
            $display("✓ MTVEC write (direct mode) successful");
        else
            $error("✗ MTVEC write failed. Got %h, expected 0x80000000", csr_rdata);
        
        // Test MTVEC write - vectored mode
        write_csr(CSR_MTVEC, 32'h80000001, CSR_WRITE);
        read_csr(CSR_MTVEC);
        assert(csr_rdata == 32'h80000001)
            $display("✓ MTVEC write (vectored mode) successful");
        else
            $error("✗ MTVEC write failed. Got %h, expected 0x80000001", csr_rdata);
        
        // Test MSCRATCH write
        write_csr(CSR_MSCRATCH, 32'h12345678, CSR_WRITE);
        read_csr(CSR_MSCRATCH);
        assert(csr_rdata == 32'h12345678)
            $display("✓ MSCRATCH write successful");
        else
            $error("✗ MSCRATCH write failed. Got %h, expected 0x12345678", csr_rdata);
        
        // Test MEPC write (should be aligned)
        write_csr(CSR_MEPC, 32'hABCDEF01, CSR_WRITE);
        read_csr(CSR_MEPC);
        assert(csr_rdata == 32'hABCDEF00)
            $display("✓ MEPC write successful with automatic alignment");
        else
            $error("✗ MEPC write alignment failed. Got %h, expected 0xABCDEF00", csr_rdata);
        
        // Test MCAUSE write
        write_csr(CSR_MCAUSE, 32'h80000007, CSR_WRITE);
        read_csr(CSR_MCAUSE);
        assert(csr_rdata == 32'h80000007)
            $display("✓ MCAUSE write successful");
        else
            $error("✗ MCAUSE write failed. Got %h, expected 0x80000007", csr_rdata);
    endtask
    
    // Task to test CSR set operations
    task test_csr_set_operations();
        // Initialize MIE to 0
        write_csr(CSR_MIE, 32'h0, CSR_WRITE);
        
        // Set MTIE bit (bit 7)
        write_csr(CSR_MIE, 32'h00000080, CSR_SET);
        read_csr(CSR_MIE);
        assert(csr_rdata == 32'h00000080)
            $display("✓ MIE set operation successful");
        else
            $error("✗ MIE set operation failed. Got %h, expected 0x00000080", csr_rdata);
        
        // Set another bit
        write_csr(CSR_MIE, 32'h00000100, CSR_SET);
        read_csr(CSR_MIE);
        assert(csr_rdata == 32'h00000180)
            $display("✓ MIE additional set operation successful");
        else
            $error("✗ MIE additional set operation failed. Got %h, expected 0x00000180", csr_rdata);
    endtask
    
    // Task to test CSR clear operations
    task test_csr_clear_operations();
        // Initialize MIE to have multiple bits set
        write_csr(CSR_MIE, 32'h000001FF, CSR_WRITE);
        
        // Clear MTIE bit (bit 7)
        write_csr(CSR_MIE, 32'h00000080, CSR_CLEAR);
        read_csr(CSR_MIE);
        assert(csr_rdata == 32'h0000017F)
            $display("✓ MIE clear operation successful");
        else
            $error("✗ MIE clear operation failed. Got %h, expected 0x0000017F", csr_rdata);
        
        // Clear another bit
        write_csr(CSR_MIE, 32'h00000100, CSR_CLEAR);
        read_csr(CSR_MIE);
        assert(csr_rdata == 32'h0000007F)
            $display("✓ MIE additional clear operation successful");
        else
            $error("✗ MIE additional clear operation failed. Got %h, expected 0x0000007F", csr_rdata);
    endtask
    
    // Task to test timer interrupt
    task test_timer_interrupt();
        // Setup for interrupt test
        current_pc = 32'h2000_0000;
        
        // Enable global interrupts
        write_csr(CSR_MSTATUS, 32'h00000008, CSR_WRITE); // Set MIE bit (bit 3)
        
        // Enable timer interrupts
        write_csr(CSR_MIE, 32'h00000080, CSR_WRITE); // Set MTIE bit (bit 7)
        
        // Set trap vector
        write_csr(CSR_MTVEC, 32'h1000_0000, CSR_WRITE); // Direct mode
        
        // Check initial state
        assert(trap_taken == 0)
            $display("✓ trap_taken initially 0 as expected");
        else
            $error("✗ trap_taken should be 0 initially");
        
        // Assert timer interrupt
        timer_int = 1;
        #10; // Wait one cycle
        
        // Check if trap is taken
        assert(trap_taken == 1)
            $display("✓ trap_taken asserted correctly");
        else
            $error("✗ trap_taken not asserted");
        
        // Check trap address
        assert(trap_pc == 32'h1000_0000)
            $display("✓ trap_pc set correctly to MTVEC value");
        else
            $error("✗ trap_pc incorrect. Got %h, expected 0x10000000", trap_pc);
        
        // Check updates to CSRs after one more cycle
        #10;
        
        // Check MEPC
        read_csr(CSR_MEPC);
        assert(csr_rdata == (current_pc & 32'hFFFF_FFFE))
            $display("✓ MEPC updated correctly to %h", csr_rdata);
        else
            $error("✗ MEPC not updated correctly. Got %h, expected %h", 
                   csr_rdata, (current_pc & 32'hFFFF_FFFE));
        
        // Check MCAUSE
        read_csr(CSR_MCAUSE);
        assert(csr_rdata == 32'h8000_0007)
            $display("✓ MCAUSE set correctly for timer interrupt");
        else
            $error("✗ MCAUSE incorrect. Got %h, expected 0x80000007", csr_rdata);
        
        // Check MSTATUS (MIE should be cleared, MPIE should have old MIE value)
        read_csr(CSR_MSTATUS);
        assert((csr_rdata & 32'h00000088) == 32'h00000080)
            $display("✓ MSTATUS updated correctly (MIE->MPIE)");
        else
            $error("✗ MSTATUS not updated correctly. Got %h", csr_rdata);
        
        // Deassert timer interrupt
        timer_int = 0;
        #10;
    endtask
    logic [31:0] expected_pc;
    // Task to test MRET instruction
    task test_mret_instruction();
        // Read current MEPC to check MRET PC
        read_csr(CSR_MEPC);
        expected_pc = csr_rdata;
        
        // Execute MRET
        mret_exec = 1;
        #10;
        
        // Check mret_pc
        assert(mret_pc == expected_pc)
            $display("✓ mret_pc set correctly to MEPC value");
        else
            $error("✗ mret_pc incorrect. Got %h, expected %h", mret_pc, expected_pc);
        
        // Check MSTATUS after MRET (MIE should be restored from MPIE, MPIE should be set)
        read_csr(CSR_MSTATUS);
        assert((csr_rdata & 32'h00000088) == 32'h00000088)
            $display("✓ MSTATUS updated correctly after MRET");
        else
            $error("✗ MSTATUS not updated correctly after MRET. Got %h", csr_rdata);
        
        // Clear MRET
        mret_exec = 0;
        #10;
    endtask
    
    // Task to test vectored interrupt mode
    task test_vectored_interrupt_mode();
        // Setup vectored mode
        write_csr(CSR_MTVEC, 32'h2000_0001, CSR_WRITE); // Vectored mode (bit 0 set)
        
        // Enable global interrupts
        write_csr(CSR_MSTATUS, 32'h00000008, CSR_WRITE);
        
        // Enable timer interrupts
        write_csr(CSR_MIE, 32'h00000080, CSR_WRITE);
        
        // Assert timer interrupt
        timer_int = 1;
        #10;
        
        // Check trap address for timer interrupt (cause 7)
        // In vectored mode: trap_pc = mtvec_base + 4*cause
        assert(trap_pc == 32'h2000_001C) // Base + 7*4 = 0x2000_0000 + 0x1C
            $display("✓ Vectored mode trap_pc calculated correctly");
        else
            $error("✗ Vectored mode trap_pc incorrect. Got %h, expected 0x2000001C", trap_pc);
        
        // Deassert timer interrupt
        timer_int = 0;
        #10;
    endtask
    
    // Task to test when global interrupts are disabled
    task test_disabled_interrupts();
        // Setup direct mode
        write_csr(CSR_MTVEC, 32'h3000_0000, CSR_WRITE);
        
        // Disable global interrupts
        write_csr(CSR_MSTATUS, 32'h00000000, CSR_WRITE); // Clear MIE bit
        
        // Enable timer interrupts in MIE
        write_csr(CSR_MIE, 32'h00000080, CSR_WRITE);
        
        // Assert timer interrupt
        timer_int = 1;
        #10;
        
        // Check if trap is NOT taken
        assert(trap_taken == 0)
            $display("✓ trap_taken correctly not asserted when global interrupts disabled");
        else
            $error("✗ trap_taken incorrectly asserted when global interrupts disabled");
        
        // Deassert timer interrupt
        timer_int = 0;
        #10;
    endtask
    
    // Task to test when timer interrupts are disabled
    task test_disabled_timer_interrupts();
        // Setup direct mode
        write_csr(CSR_MTVEC, 32'h3000_0000, CSR_WRITE);
        
        // Enable global interrupts
        write_csr(CSR_MSTATUS, 32'h00000008, CSR_WRITE);
        
        // Disable timer interrupts in MIE
        write_csr(CSR_MIE, 32'h00000000, CSR_WRITE); // Clear MTIE bit
        
        // Assert timer interrupt
        timer_int = 1;
        #10;
        
        // Check if trap is NOT taken
        assert(trap_taken == 0)
            $display("✓ trap_taken correctly not asserted when timer interrupts disabled");
        else
            $error("✗ trap_taken incorrectly asserted when timer interrupts disabled");
        
        // Deassert timer interrupt
        timer_int = 0;
        #10;
    endtask
    
    // Helper task to write to a CSR
    task write_csr(logic [11:0] addr, logic [31:0] data, logic [2:0] operation);
        @(posedge clk);
        csr_addr  = addr;
        csr_wdata = data;
        csr_wen   = 1;
        csr_op    = operation;
        @(posedge clk);
        csr_wen   = 0;
        #5; // Allow time for update
    endtask
    
    // Helper task to read from a CSR
    task read_csr(logic [11:0] addr);
        @(posedge clk);
        csr_addr = addr;
        csr_wen  = 0;
        #5; // Allow time for read
    endtask
    
endmodule
