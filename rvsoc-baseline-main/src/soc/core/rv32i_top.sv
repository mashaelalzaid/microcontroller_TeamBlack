module rv32i_top #(
    parameter DMEM_DEPTH = 1024, 
    parameter IMEM_DEPTH = 1024
)(
    input logic clk, 
    input logic reset_n,

    // memory bus
    output logic [31:0] mem_addr_mem, 
    output logic [31:0] mem_wdata_mem, 
    output logic mem_write_mem, 
    output logic [2:0] mem_op_mem,
    input logic [31:0] mem_rdata_mem,
    output logic mem_read_mem,

    // inst mem access 
    output logic [31:0] current_pc,
    input logic [31:0] inst,

    // stall signal from wishbone 
    input logic stall_pipl,
    output logic if_id_reg_en,

       // START =============================== CSR signals
    input logic timer_int // timer interrup
   // END ===============================  CSR signals
);
    // CSR control signals
    logic csr_write_id;
    logic csr_data_sel_id;
    logic csr_to_reg_id;
    logic is_csr_instr_id;
    logic is_mret_instr_id;

// Add CSR file instance
logic [11:0] csr_addr;
logic [31:0] csr_wdata, csr_rdata;
logic csr_wen;
logic [2:0] csr_op;
logic trap_taken;
logic [31:0] trap_pc;
logic mret_exec;
logic [31:0] mret_pc;

   // Instantiate the CSR file
    csr_file csr_file_inst (
        .clk(clk),
        .reset_n(reset_n),
        // CSR access interface - connect to data path memory stage
        .csr_addr(csr_addr),
        .csr_wdata(csr_wdata),
        .csr_wen(csr_wen),
        .csr_op(csr_op),
        .csr_rdata(csr_rdata),
        // External interrupts
        .timer_int(timer_int),
        // Current PC for exception handling (from memory stage)
        .current_pc(data_path_inst.current_pc_mem),
        // Trap handling signals
        .trap_taken(trap_taken),
        .trap_pc(trap_pc),
        .mret_exec(mret_exec),
        .mret_pc(mret_pc)
    );

//// Connect trap signals to data_path
//assign data_path_inst.trap_taken = trap_taken;
//assign data_path_inst.trap_pc = trap_pc;
//assign data_path_inst.mret_pc = mret_pc;
//assign mret_exec = data_path_inst.mret_exec;//1'b0;  // Temporarily disable MRET until we implement it
    
      // END ===============================  CSR signals
 
    // controller to the data path 
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

    // data path to the controller 
    logic [6:0] opcode_id;
    logic fun7_5_exe;
    logic [2:0] fun3_exe, fun3_mem;
    logic zero_mem;
    logic [1:0] alu_op_exe;
    logic jump_mem; 
    logic branch_mem;


    // data path to the controller (forwarding unit)
    wire [4:0] rs1_id;
    wire [4:0] rs2_id;
    wire [4:0] rs1_exe;
    wire [4:0] rs2_exe;
    wire [4:0] rs2_mem;
    wire [4:0] rd_mem;
    wire [4:0] rd_wb;
    wire reg_write_mem;
    wire reg_write_wb;

    // controller(forwarding unit) to the data path 
    wire forward_rd1_id;
    wire forward_rd2_id;
    wire [1:0] forward_rd1_exe;
    wire [1:0] forward_rd2_exe;
    wire forward_rd2_mem;


    // data path to the controller (hazard handler)
    wire mem_to_reg_exe;
    wire [4:0] rd_exe;

    // signals to control the flow of the pipeline (handling hazards, stalls ... )
    logic if_id_reg_clr;
    logic id_exe_reg_clr;
    logic exe_mem_reg_clr;
    logic mem_wb_reg_clr;

    logic id_exe_reg_en;
    logic exe_mem_reg_en;
    logic mem_wb_reg_en;
    logic pc_reg_en;

    // inst mem access
    logic [31:0] current_pc_if;
    logic [31:0] inst_if;

    logic mem_to_reg_mem;

    assign current_pc = current_pc_if;
    assign inst_if = inst;

    data_path #(
        .DMEM_DEPTH(DMEM_DEPTH),
        .IMEM_DEPTH(IMEM_DEPTH)
    ) data_path_inst (
        .*,
        
        // CSR control signals
        .csr_write_id(csr_write_id),
        .csr_data_sel_id(csr_data_sel_id),
        .csr_to_reg_id(csr_to_reg_id),
        .is_csr_instr_id(is_csr_instr_id),
        .is_mret_instr_id(is_mret_instr_id),
        
        // CSR connections
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

    control_unit controller_inst(
        .*
        
        // CSR control signals
//        .csr_write_id(csr_write_id),
//        .csr_data_sel_id(csr_data_sel_id),
//        .csr_to_reg_id(csr_to_reg_id),
//        .is_csr_instr_id(is_csr_instr_id),
//        .is_mret_instr_id(is_mret_instr_id),
//        .trap_taken(trap_taken),     // From CSR file to control pipeline
//        .mret_exec(mret_exec)       // From data path to control pipeline
        
        
    );

        // Additional logic needed in your data_path module to:
    // 1. Decode CSR instructions in ID stage
    // 2. Forward CSR operations through pipeline (ID->EXE->MEM)
    // 3. Connect current PC to CSR file (from appropriate pipeline stage)
    // 4. Execute CSR operations in MEM stage


    assign mem_read_mem = mem_to_reg_mem;

endmodule 