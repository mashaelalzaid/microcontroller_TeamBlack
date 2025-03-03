`timescale 1ns / 1ps

module rv32i_tb;
    // Parameters
    parameter CLK_PERIOD = 10; // 10ns = 100MHz
    parameter IMEM_DEPTH = 4096;
    parameter DMEM_DEPTH = 1024;
    
    // Clock and reset
    logic clk;
    logic reset_n;
    
    // Memory bus
    logic [31:0] mem_addr_mem;
    logic [31:0] mem_wdata_mem;
    logic mem_write_mem;
    logic [2:0] mem_op_mem;
    logic [31:0] mem_rdata_mem;
    logic mem_read_mem;
    
    // Instruction memory access
    logic [31:0] current_pc;
    logic [31:0] inst;
    
    // Stall signal
    logic stall_pipl;
    logic if_id_reg_en;
    
    // CSR signals
    logic timer_int;
    
    // Data memory
    logic [31:0] dmem [0:DMEM_DEPTH-1];
    
    // DUT instantiation
    rv32i_top #(
        .DMEM_DEPTH(DMEM_DEPTH),
        .IMEM_DEPTH(IMEM_DEPTH)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        
        // Memory bus
        .mem_addr_mem(mem_addr_mem),
        .mem_wdata_mem(mem_wdata_mem),
        .mem_write_mem(mem_write_mem),
        .mem_op_mem(mem_op_mem),
        .mem_rdata_mem(mem_rdata_mem),
        .mem_read_mem(mem_read_mem),
        
        // Instruction memory access
        .current_pc(current_pc),
        .inst(inst),
        
        // Stall signal
        .stall_pipl(stall_pipl),
        .if_id_reg_en(if_id_reg_en),
        
        // CSR signals
        .timer_int(timer_int)
    );
    
    // Clock generation
    always begin
        clk = 0; #(CLK_PERIOD/2);
        clk = 1; #(CLK_PERIOD/2);
    end
    
    // Instruction memory directly decoded from PC
    always_comb begin
        case (current_pc)
        
            // Simple register operations
    32'hfffff000: inst = 32'h00100093; // addi x1, x0, 1
    32'hfffff004: inst = 32'h00200113; // addi x2, x0, 2
    32'hfffff008: inst = 32'h00300193; // addi x3, x0, 3
    32'hfffff00C: inst = 32'h00118213; // addi x4, x3, 1  # x4 = 4
    32'hfffff010: inst = 32'h00320233; // add x4, x4, x3  # x4 = 7
    
    // More register operations
    32'hfffff014: inst = 32'h00500293; // addi x5, x0, 5
    32'hfffff018: inst = 32'h00600313; // addi x6, x0, 6
    32'hfffff01C: inst = 32'h00700393; // addi x7, x0, 7
    32'hfffff020: inst = 32'h00800413; // addi x8, x0, 8
    
    // Default for all other addresses
    default: inst = 32'h00000013; // NOP instruction
//            // Basic register operations
//            32'hfffff000: inst = 32'h00100093; // addi x1, x0, 1
//            32'hfffff004: inst = 32'h00200113; // addi x2, x0, 2
//            32'hfffff008: inst = 32'h00300193; // addi x3, x0, 3
//            32'hfffff00C: inst = 32'h00118213; // addi x4, x3, 1  # x4 = 4
//            32'hfffff010: inst = 32'h00320233; // add x4, x4, x3  # x4 = 7
            
//            // CSR operations
//            32'hfffff014: inst = 32'h0ABCD0B7; // lui x1, 0xABCD0     # x1 = 0xABCD0000
//            32'hfffff018: inst = 32'h00108093; // addi x1, x1, 1      # x1 = 0xABCD0001
//            32'hfffff01C: inst = 32'h30109173; // csrrw x2, mstatus, x1   # Write to mstatus
//            32'hfffff020: inst = 32'h300021F3; // csrrs x3, mstatus, x0   # Read mstatus
//            32'hfffff024: inst = 32'h30125273; // csrrsi x4, mstatus, 5   # Set bits 0 and 2
//            32'hfffff028: inst = 32'h300022F3; // csrrs x5, mstatus, x0   # Read final value
            
            // Default for all other addresses
//            default: inst = 32'h00000013; // NOP instruction
        endcase
    end
    
    // Data memory read/write
    always_comb begin
        if (mem_read_mem) begin
            if (mem_addr_mem < DMEM_DEPTH*4) begin
                mem_rdata_mem = dmem[mem_addr_mem[31:2]];
            end else begin
                mem_rdata_mem = 32'h00000000;
            end
        end else begin
            mem_rdata_mem = 32'h00000000;
        end
    end
    
    // Data memory write
    always_ff @(posedge clk) begin
        if (mem_write_mem) begin
            if (mem_addr_mem < DMEM_DEPTH*4) begin
                case (mem_op_mem)
                    3'b000: begin // SB
                        case (mem_addr_mem[1:0])
                            2'b00: dmem[mem_addr_mem[31:2]][7:0] <= mem_wdata_mem[7:0];
                            2'b01: dmem[mem_addr_mem[31:2]][15:8] <= mem_wdata_mem[7:0];
                            2'b10: dmem[mem_addr_mem[31:2]][23:16] <= mem_wdata_mem[7:0];
                            2'b11: dmem[mem_addr_mem[31:2]][31:24] <= mem_wdata_mem[7:0];
                        endcase
                    end
                    3'b001: begin // SH
                        if (mem_addr_mem[1:0] == 2'b00)
                            dmem[mem_addr_mem[31:2]][15:0] <= mem_wdata_mem[15:0];
                        else if (mem_addr_mem[1:0] == 2'b10)
                            dmem[mem_addr_mem[31:2]][31:16] <= mem_wdata_mem[15:0];
                    end
                    3'b010: begin // SW
                        dmem[mem_addr_mem[31:2]] <= mem_wdata_mem;
                    end
                endcase
            end
        end
    end
    
    // Test sequence
    initial begin
        // Initialize
        stall_pipl = 0;
        timer_int = 0;
        
        // Clear data memory
        for (int i = 0; i < DMEM_DEPTH; i++) begin
            dmem[i] = 32'h00000000;
        end
        
        // Reset processor
        reset_n = 0;
        repeat (5) @(posedge clk);
        reset_n = 1;
        
        // Wait for first instruction fetch
        @(posedge clk);
        $display("Starting PC after reset: 0x%h", current_pc);
        
        
             // Wait for register operations to execute
        repeat (25) @(posedge clk);
        
        // Print register values after register operations
        $display("\n=== Register Operations Results ===");
        print_register_values(5);
        $display("Pipeline Regs - ID/EXE:%b, EXE/MEM:%b, MEM/WB:%b",
                 dut.data_path_inst.id_exe_bus_o.reg_write, 
                 dut.data_path_inst.exe_mem_bus_o.reg_write, 
                 dut.data_path_inst.mem_wb_bus_o.reg_write);        
        if (dut.trap_taken) begin
        $display("Trap taken at time %0t, PC: %h", $time, dut.current_pc_mem);
        end else  $display("Trap was not taken  %0t, PC: %h ", $time, dut.current_pc_mem);
        
        
        $display("Pipeline Regs - ID/EXE:%b, EXE/MEM:%b, MEM/WB:%b",
                 id_exe_bus_o.reg_write, exe_mem_bus_o.reg_write, mem_wb_bus_o.reg_write);

        // Print pipeline control signals to debug
        $display("\n=== Pipeline Control Signals ===");
        debug_pipeline_signals();
                $display("Pipeline Regs - ID/EXE:%b, EXE/MEM:%b, MEM/WB:%b",
                 id_exe_bus_o.reg_write, exe_mem_bus_o.reg_write, mem_wb_bus_o.reg_write);
        
        // Wait for CSR operations to execute
        repeat (25) @(posedge clk);
        
        // Print register values after CSR operations
        $display("\n=== CSR Operations Results ===");
        print_register_values(6);
        
        // Print CSR debug info
        $display("\n=== CSR Debug Info ===");
        debug_csr_signals();
        
        $display("\nTest completed");
        $finish;
    end
    
    // Task to print register values
    task print_register_values(int num_regs);
        $display("Register values:");
        for (int i = 0; i < num_regs; i++) begin
            automatic logic [31:0] reg_val;
            
            // Based on your register file implementation
            reg_val = dut.data_path_inst.reg_file_inst.reg_file[i];
            
            $display("  x%0d = 0x%08h", i, reg_val);
        end
    endtask
    
    // Task to debug pipeline signals
    task debug_pipeline_signals();
        $display("Control signals:");
        $display("  PC select (pc_sel_mem): %b", dut.pc_sel_mem);
        $display("  RegWrite ID stage (reg_write_id): %b", dut.reg_write_id);
        $display("  RegWrite WB stage (reg_write_wb): %b", dut.reg_write_wb);
        $display("  ALU source (alu_src_id): %b", dut.alu_src_id);
        
        $display("\nPipeline enables:");
        $display("  if_id_reg_en: %b", dut.if_id_reg_en);
        $display("  id_exe_reg_en: %b", dut.id_exe_reg_en);
        $display("  exe_mem_reg_en: %b", dut.exe_mem_reg_en);
        $display("  mem_wb_reg_en: %b", dut.mem_wb_reg_en);
        $display("  pc_reg_en: %b", dut.pc_reg_en);
        
        $display("\nDecode stage:");
        $display("  opcode_id: 0x%h", dut.opcode_id);
        $display("  fun3_id: 0x%h", dut.fun3_id);
        
        $display("\nWriteback stage:");
        $display("  rd_wb: %d", dut.rd_wb);
        $display("  reg_wdata_wb: 0x%h", dut.data_path_inst.reg_wdata_wb);
    endtask
    
    // Task to debug CSR signals
    task debug_csr_signals();
        $display("CSR control signals:");
        $display("  csr_write_id: %b", dut.csr_write_id);
        $display("  csr_data_sel_id: %b", dut.csr_data_sel_id);
        $display("  csr_to_reg_id: %b", dut.csr_to_reg_id);
        $display("  is_csr_instr_id: %b", dut.is_csr_instr_id);
        
        $display("\nCSR interface signals:");
        $display("  csr_addr: 0x%h", dut.csr_addr);
        $display("  csr_wdata: 0x%h", dut.csr_wdata);
        $display("  csr_rdata: 0x%h", dut.csr_rdata);
        $display("  csr_wen: %b", dut.csr_wen);
        $display("  csr_op: %b", dut.csr_op);
    endtask
    
    // Monitoring
    int cycle_count = 0;
    always @(posedge clk) begin
        if (reset_n) begin
            cycle_count++;
            $display("Cycle: %0d, PC: 0x%h, Inst: 0x%h", cycle_count, current_pc, inst);
        end
    end
    
endmodule