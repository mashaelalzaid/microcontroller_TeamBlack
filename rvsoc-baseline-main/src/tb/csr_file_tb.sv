module csr_file_tb;
    // Testbench signals
    logic clk;
    logic reset_n;
    
    // CSR interface signals
    logic [11:0] csr_addr;
    logic [31:0] csr_wdata;
    logic        csr_wen;
    logic [2:0]  csr_op;
    logic [31:0] csr_rdata;
    logic [31:0] read_data;

    // CLINT interface
    logic timer_int;
    
    // Control signals
    logic [31:0] current_pc;
    logic        trap_taken;
    logic [31:0] trap_pc;
    
    // MRET signals
    logic        mret_exec;
    logic [31:0] mret_pc;
    
    // Instance of CSR file
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
    always begin
        #5 clk = ~clk;
    end
    
    // Define CSR addresses
    localparam CSR_MSTATUS     = 12'h300;
    localparam CSR_MIE         = 12'h304;
    localparam CSR_MTVEC       = 12'h305;
    localparam CSR_MSCRATCH    = 12'h340;
    localparam CSR_MEPC        = 12'h341;
    localparam CSR_MCAUSE      = 12'h342;
    localparam CSR_MIP         = 12'h344;
    
    // CSR operation types
    localparam CSR_WRITE = 3'b001;  // CSRRW
    localparam CSR_SET   = 3'b010;  // CSRRS
    localparam CSR_CLEAR = 3'b011;  // CSRRC
    
    // Test task for writing to CSR
    task write_csr(input [11:0] addr, input [31:0] data, input [2:0] op);
        @(posedge clk);
        csr_addr = addr;
        csr_wdata = data;
        csr_wen = 1'b1;
        csr_op = op;
        @(posedge clk);
        csr_wen = 1'b0;
    endtask
    
    // Test task for reading from CSR
    task read_csr(input [11:0] addr, output [31:0] data);
        @(posedge clk);
        csr_addr = addr;
        csr_wen = 1'b0;
        @(posedge clk);
        data = csr_rdata;
    endtask
    
    // Test case: Initialize, then trigger and handle timer interrupt
    initial begin
        // Initialize signals
        clk = 0;
        reset_n = 0;
        csr_addr = 0;
        csr_wdata = 0;
        csr_wen = 0;
        csr_op = 0;
        timer_int = 0;
        current_pc = 32'h1000_0000;
        mret_exec = 0;
        
        // Apply reset
        #20 reset_n = 1;
        
        // Setup CSRs for interrupt handling
        write_csr(CSR_MTVEC, 32'h2000_0000, CSR_WRITE); // Set trap vector to 0x20000000 (direct mode)
        write_csr(CSR_MIE, 32'h00000080, CSR_WRITE);    // Enable timer interrupts (bit 7)
        write_csr(CSR_MSTATUS, 32'h00000008, CSR_WRITE); // Enable interrupts (MIE bit 3)
        
        // Read back and verify CSR values
        read_csr(CSR_MTVEC, read_data);
        $display("MTVEC = 0x%h (Expected 0x20000000)", read_data);
        read_csr(CSR_MIE, read_data);
        $display("MIE = 0x%h (Expected 0x00000080)", read_data);
        read_csr(CSR_MSTATUS, read_data);
        $display("MSTATUS = 0x%h (Expected 0x00000008)", read_data);
        
        // Wait a few cycles
        repeat(5) @(posedge clk);
        
        // Trigger timer interrupt
        timer_int = 1;
        @(posedge clk);
        
        // Check if trap is taken
        $display("Trap taken = %b (Expected 1)", trap_taken);
        $display("Trap PC = 0x%h (Expected 0x20000000)", trap_pc);
        
        // Wait a few cycles to let the interrupt be processed
        repeat(5) @(posedge clk);
        
        // Read back CSR values after interrupt
        read_csr(CSR_MEPC, read_data);
        $display("MEPC = 0x%h (Expected 0x10000000)", read_data);
        read_csr(CSR_MCAUSE, read_data);
        $display("MCAUSE = 0x%h (Expected 0x80000007)", read_data);
        read_csr(CSR_MSTATUS, read_data);
        $display("MSTATUS = 0x%h (Expected 0x00000080)", read_data); // MIE=0, MPIE=1
        
        // Clear interrupt
        timer_int = 0;
        repeat(5) @(posedge clk);
        
        // Execute MRET to return from interrupt
        mret_exec = 1;
        @(posedge clk);
        mret_exec = 0;
        
        // Check return address
        $display("MRET PC = 0x%h (Expected 0x10000000)", mret_pc);
        
        // Read back MSTATUS after MRET
        read_csr(CSR_MSTATUS, read_data);
        $display("MSTATUS after MRET = 0x%h (Expected 0x00000088)", read_data); // MIE=1, MPIE=1
        
        // Additional test: Vectored mode interrupt handling
        write_csr(CSR_MTVEC, 32'h3000_0001, CSR_WRITE); // Set trap vector to 0x30000000 (vectored mode)
        
        // Wait a few cycles
        repeat(5) @(posedge clk);
        
        // Trigger timer interrupt again
        timer_int = 1;
        @(posedge clk);
        
        // Check vectored trap PC calculation
        $display("Vectored Trap PC = 0x%h (Expected 0x3000001C)", trap_pc); // Base + 7*4
        
        // Finish simulation
        #100 $finish;
    end
    
//    // Optional: Add waveform dumping
//    initial begin
//        $dumpfile("csr_file_tb.vcd");
//        $dumpvars(0, csr_file_tb);
//    end
    
endmodule