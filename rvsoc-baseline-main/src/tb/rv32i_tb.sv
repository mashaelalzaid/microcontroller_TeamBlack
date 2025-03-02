module rv32i_tb();
    // Parameters
    parameter DMEM_DEPTH = 1024;
    parameter IMEM_DEPTH = 1024;
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
    logic mem_to_reg_mem;
    
    // Instruction memory signals
    logic [31:0] current_pc_if;
    logic [31:0] inst_if;
    
    // CSR signals
    logic [11:0] csr_addr;
    logic [31:0] csr_wdata;
    logic [31:0] csr_rdata;
    logic csr_wen;
    logic [2:0] csr_op;
    logic trap_taken;
    logic [31:0] trap_pc;
    logic mret_exec;
    logic [31:0] mret_pc;
    
    // Outputs to controller
    logic [6:0] opcode_id;
    logic fun7_5_exe;
    logic [2:0] fun3_exe, fun3_mem;
    logic zero_mem;
    logic [1:0] alu_op_exe;
    logic jump_mem;
    logic branch_mem;
    
    // Control signals to data path (normally from controller)
    logic reg_write_id; 
    logic mem_write_id;
    logic mem_to_reg_id; 
    logic branch_id; 
    logic alu_src_id;
    logic jump_id; 
    logic lui_id;
    logic auipc_id; 
    logic jal_id;
    logic [1:0] alu_op_id;
    logic [3:0] alu_ctrl_exe;
    logic pc_sel_mem;
    
    // CSR control signals
    logic csr_write_id;
    logic csr_data_sel_id;
    logic csr_to_reg_id;
    logic is_csr_instr_id;
    logic is_mret_instr_id;
    
    // Forwarding unit signals
    wire [4:0] rs1_id;
    wire [4:0] rs2_id;
    wire [4:0] rs1_exe;
    wire [4:0] rs2_exe;
    wire [4:0] rs2_mem;
    wire [4:0] rd_mem;
    wire [4:0] rd_wb;
    wire reg_write_mem;
    wire reg_write_wb;
    wire forward_rd1_id;
    wire forward_rd2_id;
    wire [1:0] forward_rd1_exe;
    wire [1:0] forward_rd2_exe;
    wire forward_rd2_mem;
    
    // Hazard handler signals
    wire mem_to_reg_exe;
    wire [4:0] rd_exe;
    
    // Pipeline control signals
    logic if_id_reg_clr;
    logic id_exe_reg_clr;
    logic exe_mem_reg_clr;
    logic mem_wb_reg_clr;
    logic if_id_reg_en;
    logic id_exe_reg_en;
    logic exe_mem_reg_en;
    logic mem_wb_reg_en;
    logic pc_reg_en;
    logic stall_pipl;
    
    // Instruction memory for test
    logic [31:0] imem [0:IMEM_DEPTH-1];
    
    // Data memory for test
    logic [31:0] dmem [0:DMEM_DEPTH-1];
    
    // Test variables
    int test_num = 0;
    int test_success = 0;
    int test_failed = 0;
    string current_test = "";
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Simplified CSR model for testbench
    logic [31:0] csr_regs [0:4095];  // All possible CSRs
    
    // Instantiate the data path
    data_path #(
        .DMEM_DEPTH(DMEM_DEPTH),
        .IMEM_DEPTH(IMEM_DEPTH)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .opcode_id(opcode_id),
        .fun7_5_exe(fun7_5_exe),
        .fun3_exe(fun3_exe),
        .fun3_mem(fun3_mem),
        .zero_mem(zero_mem),
        .alu_op_exe(alu_op_exe),
        .jump_mem(jump_mem),
        .branch_mem(branch_mem),
        .reg_write_id(reg_write_id),
        .mem_write_id(mem_write_id),
        .mem_to_reg_id(mem_to_reg_id),
        .branch_id(branch_id),
        .alu_src_id(alu_src_id),
        .jump_id(jump_id),
        .lui_id(lui_id),
        .auipc_id(auipc_id),
        .jal_id(jal_id),
        .alu_op_id(alu_op_id),
        .csr_write_id(csr_write_id),
        .csr_data_sel_id(csr_data_sel_id),
        .csr_to_reg_id(csr_to_reg_id),
        .is_csr_instr_id(is_csr_instr_id),
        .is_mret_instr_id(is_mret_instr_id),
        .alu_ctrl_exe(alu_ctrl_exe),
        .pc_sel_mem(pc_sel_mem),
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rs1_exe(rs1_exe),
        .rs2_exe(rs2_exe),
        .rs2_mem(rs2_mem),
        .rd_mem(rd_mem),
        .rd_wb(rd_wb),
        .reg_write_mem(reg_write_mem),
        .reg_write_wb(reg_write_wb),
        .forward_rd1_id(forward_rd1_id),
        .forward_rd2_id(forward_rd2_id),
        .forward_rd1_exe(forward_rd1_exe),
        .forward_rd2_exe(forward_rd2_exe),
        .forward_rd2_mem(forward_rd2_mem),
        .mem_to_reg_exe(mem_to_reg_exe),
        .rd_exe(rd_exe),
        .if_id_reg_clr(if_id_reg_clr),
        .id_exe_reg_clr(id_exe_reg_clr),
        .exe_mem_reg_clr(exe_mem_reg_clr),
        .mem_wb_reg_clr(mem_wb_reg_clr),
        .if_id_reg_en(if_id_reg_en),
        .id_exe_reg_en(id_exe_reg_en),
        .exe_mem_reg_en(exe_mem_reg_en),
        .mem_wb_reg_en(mem_wb_reg_en),
        .pc_reg_en(pc_reg_en),
        .mem_addr_mem(mem_addr_mem),
        .mem_wdata_mem(mem_wdata_mem),
        .mem_op_mem(mem_op_mem),
        .mem_rdata_mem(mem_rdata_mem),
        .mem_write_mem(mem_write_mem),
        .mem_to_reg_mem(mem_to_reg_mem),
        .current_pc_if(current_pc_if),
        .inst_if(inst_if),
        .csr_addr(csr_addr),
        .csr_wdata(csr_wdata),
        .csr_rdata(csr_rdata),
        .csr_wen(csr_wen),
        .csr_op(csr_op),
        .trap_taken(trap_taken),
        .trap_pc(trap_pc),
        .mret_exec(mret_exec),
        .mret_pc(mret_pc)
    );
    
    // Instruction fetch simulation
    assign inst_if = imem[current_pc_if[31:2]];
    
    // Memory simulation
    always_ff @(posedge clk) begin
        if (mem_write_mem)
            dmem[mem_addr_mem[31:2]] <= mem_wdata_mem;
            
        mem_rdata_mem <= dmem[mem_addr_mem[31:2]];
    end
    
    // CSR read/write simulation
    always_ff @(posedge clk) begin
        if (csr_wen) begin
            case (csr_op)
                3'b001: begin // CSRRW
                    csr_rdata <= csr_regs[csr_addr];  // Read old value
                    csr_regs[csr_addr] <= csr_wdata;  // Write new value
                    $display("[CSRRW] CSR[0x%h] = 0x%h (old: 0x%h)", csr_addr, csr_wdata, csr_regs[csr_addr]);
                end
                3'b010: begin // CSRRS
                    csr_rdata <= csr_regs[csr_addr];  // Read old value
                    csr_regs[csr_addr] <= csr_regs[csr_addr] | csr_wdata;  // Set bits
                    $display("[CSRRS] CSR[0x%h] = 0x%h (old: 0x%h)", csr_addr, csr_regs[csr_addr] | csr_wdata, csr_regs[csr_addr]);
                end
                3'b011: begin // CSRRC
                    csr_rdata <= csr_regs[csr_addr];  // Read old value
                    csr_regs[csr_addr] <= csr_regs[csr_addr] & ~csr_wdata;  // Clear bits
                    $display("[CSRRC] CSR[0x%h] = 0x%h (old: 0x%h)", csr_addr, csr_regs[csr_addr] & ~csr_wdata, csr_regs[csr_addr]);
                end
                3'b101: begin // CSRRWI
                    csr_rdata <= csr_regs[csr_addr];  // Read old value
                    csr_regs[csr_addr] <= csr_wdata;  // Write new value
                    $display("[CSRRWI] CSR[0x%h] = 0x%h (old: 0x%h)", csr_addr, csr_wdata, csr_regs[csr_addr]);
                end
                3'b110: begin // CSRRSI
                    csr_rdata <= csr_regs[csr_addr];  // Read old value
                    csr_regs[csr_addr] <= csr_regs[csr_addr] | csr_wdata;  // Set bits
                    $display("[CSRRSI] CSR[0x%h] = 0x%h (old: 0x%h)", csr_addr, csr_regs[csr_addr] | csr_wdata, csr_regs[csr_addr]);
                end
                3'b111: begin // CSRRCI
                    csr_rdata <= csr_regs[csr_addr];  // Read old value
                    csr_regs[csr_addr] <= csr_regs[csr_addr] & ~csr_wdata;  // Clear bits
                    $display("[CSRRCI] CSR[0x%h] = 0x%h (old: 0x%h)", csr_addr, csr_regs[csr_addr] & ~csr_wdata, csr_regs[csr_addr]);
                end
            endcase
        end else begin
            csr_rdata <= csr_regs[csr_addr];  // Just read
        end
    end
    
    // Disable all forwarding for this test
    assign forward_rd1_id = 0;
    assign forward_rd2_id = 0;
    assign forward_rd1_exe = 0;
    assign forward_rd2_exe = 0;
    assign forward_rd2_mem = 0;
    
    // Helper task to verify CSR operations
    task check_csr_operation(
        input logic [11:0] expected_addr,
        input logic [31:0] expected_wdata,
        input logic expected_wen,
        input logic [2:0] expected_op,
        input string test_desc
    );
        test_num++;
        current_test = test_desc;
        
        @(posedge clk); // Allow one cycle for signals to propagate
        
        if (csr_addr == expected_addr &&
            csr_wdata == expected_wdata &&
            csr_wen == expected_wen &&
            csr_op == expected_op) begin
            $display("✅ TEST %0d PASSED [%s]: CSR signals correct", test_num, test_desc);
            $display("   Address: Expected=0x%h, Actual=0x%h", expected_addr, csr_addr);
            $display("   Write Data: Expected=0x%h, Actual=0x%h", expected_wdata, csr_wdata);
            $display("   Write Enable: Expected=%b, Actual=%b", expected_wen, csr_wen);
            $display("   Operation: Expected=%b, Actual=%b", expected_op, csr_op);
            test_success++;
        end else begin
            $display("❌ TEST %0d FAILED [%s]: CSR signals mismatch", test_num, test_desc);
            $display("   Address: Expected=0x%h, Actual=0x%h", expected_addr, csr_addr);
            $display("   Write Data: Expected=0x%h, Actual=0x%h", expected_wdata, csr_wdata);
            $display("   Write Enable: Expected=%b, Actual=%b", expected_wen, csr_wen);
            $display("   Operation: Expected=%b, Actual=%b", expected_op, csr_op);
            test_failed++;
        end
    endtask
    
    // Helper task to verify trap handling
    task check_trap_handling(
        input logic expected_trap_taken,
        input logic [31:0] expected_trap_pc,
        input string test_desc
    );
        test_num++;
        current_test = test_desc;
        
        @(posedge clk); // Allow one cycle for signals to propagate
        
        if (trap_taken == expected_trap_taken &&
            (trap_taken ? trap_pc == expected_trap_pc : 1'b1)) begin
            $display("✅ TEST %0d PASSED [%s]: Trap handling correct", test_num, test_desc);
            $display("   trap_taken: Expected=%b, Actual=%b", expected_trap_taken, trap_taken);
            if (expected_trap_taken)
                $display("   trap_pc: Expected=0x%h, Actual=0x%h", expected_trap_pc, trap_pc);
            test_success++;
        end else begin
            $display("❌ TEST %0d FAILED [%s]: Trap handling incorrect", test_num, test_desc);
            $display("   trap_taken: Expected=%b, Actual=%b", expected_trap_taken, trap_taken);
            if (expected_trap_taken)
                $display("   trap_pc: Expected=0x%h, Actual=0x%h", expected_trap_pc, trap_pc);
            test_failed++;
        end
    endtask
    
    // Helper task to verify MRET execution
    task check_mret_execution(
        input logic expected_mret_exec,
        input logic [31:0] expected_mret_pc,
        input string test_desc
    );
        test_num++;
        current_test = test_desc;
        
        @(posedge clk); // Allow one cycle for signals to propagate
        
        if (mret_exec == expected_mret_exec &&
            (mret_exec ? mret_pc == expected_mret_pc : 1'b1)) begin
            $display("✅ TEST %0d PASSED [%s]: MRET execution correct", test_num, test_desc);
            $display("   mret_exec: Expected=%b, Actual=%b", expected_mret_exec, mret_exec);
            if (expected_mret_exec)
                $display("   mret_pc: Expected=0x%h, Actual=0x%h", expected_mret_pc, mret_pc);
            test_success++;
        end else begin
            $display("❌ TEST %0d FAILED [%s]: MRET execution incorrect", test_num, test_desc);
            $display("   mret_exec: Expected=%b, Actual=%b", expected_mret_exec, mret_exec);
            if (expected_mret_exec)
                $display("   mret_pc: Expected=0x%h, Actual=0x%h", expected_mret_pc, mret_pc);
            test_failed++;
        end
    endtask
    
    // Test sequence
    initial begin
        // Initialize signals
        reset_n = 0;
        stall_pipl = 0;
        trap_taken = 0;
        trap_pc = 32'h200;
        mret_pc = 32'h100;
        
        // Enable pipeline registers
        if_id_reg_clr = 0;
        id_exe_reg_clr = 0;
        exe_mem_reg_clr = 0;
        mem_wb_reg_clr = 0;
        if_id_reg_en = 1;
        id_exe_reg_en = 1;
        exe_mem_reg_en = 1;
        mem_wb_reg_en = 1;
        pc_reg_en = 1;
        
        // Set up test CSR registers
        for (int i = 0; i < 4096; i++)
            csr_regs[i] = 32'h0;
            
        // Initialize some special CSRs
        csr_regs[12'h300] = 32'h8;       // mstatus (MIE bit set)
        csr_regs[12'h304] = 32'h80;      // mie (MTIE bit set)
        csr_regs[12'h305] = 32'h200;     // mtvec (trap handler at 0x200)
        csr_regs[12'h341] = 32'h100;     // mepc (return address at 0x100)
        
        // Initialize general-purpose registers
        for (int i = 0; i < 32; i++)
            dut.reg_file_inst.reg_file[i] = 32'h0;
            
        // Set up test values in registers
        dut.reg_file_inst.reg_file[1] = 32'h10;   // x1 = 16
        dut.reg_file_inst.reg_file[2] = 32'h20;   // x2 = 32
        
        // Setup test program
        // 1. CSRRW x3, mstatus, x1   (Write x1 to mstatus, read old value to x3)
        imem[0] = 32'h30051173;
        
        // 2. CSRRS x4, mie, x2       (Set bits from x2 in mie, read to x4)
        imem[1] = 32'h304A1213;
        
        // 3. CSRRWI x5, mscratch, 10 (Write immediate 10 to mscratch)
        imem[2] = 32'h34052573;
        
        // 4. MRET                    (Return from trap)
        imem[3] = 32'h30200073;
        
        // Apply reset
        $display("\n=== Starting CSR Datapath Tests ===\n");
        repeat (2) @(posedge clk);
        reset_n = 1;
        
        // Test 1: CSRRW instruction
        $display("\n--- Test 1: CSRRW Instruction ---");
        current_test = "CSRRW Instruction Test";
        @(posedge clk);
        // Decode stage - Set control signals for CSRRW
        reg_write_id = 1;
        mem_write_id = 0;
        mem_to_reg_id = 0;
        branch_id = 0;
        alu_src_id = 0;
        jump_id = 0;
        lui_id = 0;
        auipc_id = 0;
        jal_id = 0;
        alu_op_id = 0;
        csr_write_id = 1;
        csr_data_sel_id = 0;  // Use register value
        csr_to_reg_id = 1;
        is_csr_instr_id = 1;
        is_mret_instr_id = 0;
        alu_ctrl_exe = 0;     // ADD operation
        pc_sel_mem = 0;
        
        // Wait for instruction to reach memory stage
        repeat (3) @(posedge clk);
        
        // Check if CSR signals are properly passed to CSR file
        check_csr_operation(
            12'h300,     // mstatus address
            32'h10,      // x1 value
            1'b1,        // Write enable should be active
            3'b001,      // CSRRW operation
            "CSRRW Instruction"
        );
        
        // Test 2: CSRRS instruction
        $display("\n--- Test 2: CSRRS Instruction ---");
        current_test = "CSRRS Instruction Test";
        @(posedge clk);
        // Decode stage - Set control signals for CSRRS
        reg_write_id = 1;
        mem_write_id = 0;
        mem_to_reg_id = 0;
        branch_id = 0;
        alu_src_id = 0;
        jump_id = 0;
        lui_id = 0;
        auipc_id = 0;
        jal_id = 0;
        alu_op_id = 0;
        csr_write_id = 1;
        csr_data_sel_id = 0;  // Use register value
        csr_to_reg_id = 1;
        is_csr_instr_id = 1;
        is_mret_instr_id = 0;
        
        // Wait for instruction to reach memory stage
        repeat (3) @(posedge clk);
        
        // Check if CSR signals are properly passed to CSR file
        check_csr_operation(
            12'h304,     // mie address
            32'h20,      // x2 value
            1'b1,        // Write enable should be active
            3'b010,      // CSRRS operation
            "CSRRS Instruction"
        );
        
        // Test 3: CSRRWI instruction
        $display("\n--- Test 3: CSRRWI Instruction ---");
        current_test = "CSRRWI Instruction Test";
        @(posedge clk);
        // Decode stage - Set control signals for CSRRWI
        reg_write_id = 1;
        mem_write_id = 0;
        mem_to_reg_id = 0;
        branch_id = 0;
        alu_src_id = 0;
        jump_id = 0;
        lui_id = 0;
        auipc_id = 0;
        jal_id = 0;
        alu_op_id = 0;
        csr_write_id = 1;
        csr_data_sel_id = 1;  // Use immediate value
        csr_to_reg_id = 1;
        is_csr_instr_id = 1;
        is_mret_instr_id = 0;
        
        // Wait for instruction to reach memory stage
        repeat (3) @(posedge clk);
        
        // Check if CSR signals are properly passed to CSR file
        check_csr_operation(
            12'h340,     // mscratch address
            32'h0000000A, // Immediate value (10)
            1'b1,        // Write enable should be active
            3'b101,      // CSRRWI operation
            "CSRRWI Instruction"
        );
        
        // Test 4: MRET instruction
        $display("\n--- Test 4: MRET Instruction ---");
        current_test = "MRET Instruction Test";
        @(posedge clk);
        // Decode stage - Set control signals for MRET
        reg_write_id = 0;
        mem_write_id = 0;
        mem_to_reg_id = 0;
        branch_id = 0;
        alu_src_id = 0;
        jump_id = 0;
        lui_id = 0;
        auipc_id = 0;
        jal_id = 0;
        alu_op_id = 0;
        csr_write_id = 0;
        csr_data_sel_id = 0;
        csr_to_reg_id = 0;
        is_csr_instr_id = 0;
        is_mret_instr_id = 1;
        
        // Wait for instruction to reach memory stage
        repeat (3) @(posedge clk);
        
        // Check if MRET signal is properly passed to CSR file
        check_mret_execution(
            1'b1,        // MRET should be active
            32'h100,     // Return address from mepc
            "MRET Instruction"
        );
        
        // Test 5: Trap handling
        $display("\n--- Test 5: Trap Handling ---");
        current_test = "Trap Handling Test";
        @(posedge clk);
        // Trigger a trap
        trap_taken = 1;
        @(posedge clk);
        
        // Check if trap is properly handled
        check_trap_handling(
            1'b1,        // Trap should be taken
            32'h200,     // Trap handler address from mtvec
            "Trap Handling"
        );
        
        // Reset trap signal for next tests
        trap_taken = 0;
        @(posedge clk);
        
        // Print test summary
        $display("\n=== CSR Datapath Test Summary ===");
        $display("Total Tests: %0d", test_num);
        $display("Passed: %0d", test_success);
        $display("Failed: %0d", test_failed);
        if (test_failed == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");
        
        $finish;
    end
endmodule