module rv32i_tb();
    // Parameters
    parameter CLK_PERIOD = 10;
    
    // Clock and reset
    logic clk;
    logic reset_n;
    
    // Memory bus signals
    logic [31:0] mem_addr_mem;
    logic [31:0] mem_wdata_mem;
    logic mem_write_mem;
    logic [2:0] mem_op_mem;
    logic [31:0] mem_rdata_mem;
    logic mem_read_mem;
    
    // Instruction memory signals
    logic [31:0] current_pc;
    logic [31:0] inst;
    
    // Stall signal
    logic stall_pipl;
    logic if_id_reg_en;
    
    // Timer interrupt
    logic timer_int;
    
    // Instruction memory (small for test)
    logic [31:0] imem [0:255];
    
    // Data memory (small for test)
    logic [31:0] dmem [0:255];
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // DUT instantiation
    rv32i_top dut (
        .clk(clk),
        .reset_n(reset_n),
        .mem_addr_mem(mem_addr_mem),
        .mem_wdata_mem(mem_wdata_mem),
        .mem_write_mem(mem_write_mem),
        .mem_op_mem(mem_op_mem),
        .mem_rdata_mem(mem_rdata_mem),
        .mem_read_mem(mem_read_mem),
        .current_pc(current_pc),
        .inst(inst),
        .stall_pipl(stall_pipl),
        .if_id_reg_en(if_id_reg_en),
        .timer_int(timer_int)
    );
    
    // Instruction fetch simulation
    assign inst = imem[current_pc[31:2]];
    
    // Memory simulation
    always_ff @(posedge clk) begin
        if (mem_write_mem)
            dmem[mem_addr_mem[31:2]] <= mem_wdata_mem;
            
        mem_rdata_mem <= dmem[mem_addr_mem[31:2]];
    end
    
    // Test sequence
    initial begin
        // Initialize
        reset_n = 0;
        stall_pipl = 0;
        timer_int = 0;
        
        // Setup test program
        // 1. CSRRW x1, mstatus, x2   (Write x2 to mstatus)
        imem[0] = 32'h3002A173;
        
        // 2. CSRRS x3, mie, x4       (Set bits in mie)
        imem[1] = 32'h304221F3;
        
        // 3. CSRRWI x5, mscratch, 10 (Write immediate to mscratch)
        imem[2] = 32'h34052573;
        
        // 4. MRET                    (Return from trap)
        imem[3] = 32'h30200073;
        
        // Set trap handler at 0x200
        imem[128] = 32'h30200073;  // MRET at 0x200
        
        // Initialize registers
        for (int i = 0; i < 32; i++)
            dut.data_path_inst.reg_file_inst.reg_file[i] = 32'h0;
            
        // Set up test values
        dut.data_path_inst.reg_file_inst.reg_file[2] = 32'h8;    // x2 = 8 (MIE bit)
        dut.data_path_inst.reg_file_inst.reg_file[4] = 32'h80;   // x4 = 128 (MTIE bit)
        
        // Set trap handler address
        dut.csr_file_inst.mtvec = 32'h200;
        
        // Run simulation
        $display("=== Starting CSR Tests ===");
        repeat (2) @(posedge clk);
        reset_n = 1;
        
        // Wait for CSR instructions to execute
        repeat (20) @(posedge clk);
        
        // Check CSR values
        $display("mstatus = 0x%h (Expected: 0x8)", dut.csr_file_inst.mstatus);
        $display("mie = 0x%h (Expected: 0x88)", dut.csr_file_inst.mie);
        $display("mscratch = 0x%h (Expected: 0xA)", dut.csr_file_inst.mscratch);
        
        // Test timer interrupt
        $display("\n=== Testing Timer Interrupt ===");
        timer_int = 1;
        repeat (10) @(posedge clk);
        
        // Check if trap was taken
        $display("Trap taken: %b", dut.trap_taken);
        $display("Current PC: 0x%h", current_pc);
        
        // Finish simulation
        $display("\n=== Test Complete ===");
        $finish;
    end
    // Add this monitoring to your testbench
always @(posedge clk) begin
    $display("CSR Signals: write_id=%b, data_sel_id=%b, to_reg_id=%b, is_csr_instr_id=%b",
        dut.csr_write_id, dut.csr_data_sel_id, dut.csr_to_reg_id, dut.is_csr_instr_id);
    $display("CSR Memory: addr=%h, wdata=%h, wen=%b, op=%b",
        dut.csr_addr, dut.csr_wdata, dut.csr_wen, dut.csr_op);
    $display("Current PC: %h", dut.current_pc);
end
    
    // Monitor CSR operations
    initial begin
        forever begin
            @(posedge clk);
            if (dut.csr_wen)
                $display("CSR Write: addr=0x%h, data=0x%h", dut.csr_addr, dut.csr_wdata);
            if (dut.mret_exec)
                $display("MRET executed");
            if (dut.trap_taken)
                $display("Trap taken to 0x%h", dut.trap_pc);
        end
    end
    
endmodule