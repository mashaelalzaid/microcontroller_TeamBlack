module control_unit(
    input logic [6:0] opcode_id,
    input logic fun7_5_exe,
    input logic [2:0] fun3_id,fun3_exe, fun3_mem,
    input logic [11:0] funct12,
    input logic zero_mem,
    input logic [1:0] alu_op_exe,
    input logic jump_mem, 
    input logic branch_mem,
    
    // outputs from the decode controller
    output logic reg_write_id, 
    output logic mem_write_id, 
    output logic mem_to_reg_id, 
    output logic branch_id, 
    output logic alu_src_id,
    output logic jump_id, 
    output logic lui_id,
    output logic auipc_id, 
    output logic jal_id,
    output logic [1:0] alu_op_id,
     //CSR
    output logic csr_write, //mashael csr write enable
    output logic csr_data_sel_id, // Whether to use immediate or register for CSR op
    output logic csr_to_reg,      // Whether to write CSR value to register
    output logic is_csr_instr,    // Whether instruction is CSR
    output logic is_mret_instr,    // Whether instruction is MRET
    input logic trap_taken,     // New: Signal when trap is requested
    input logic mret_exec,        // New: Signal when MRET is executed

    // alu_controller output
    output [3:0] alu_ctrl_exe,

    // branch controller output 
    output wire pc_sel_mem,

    // forwarding unit stuff
    input wire [4:0] rs1_id,
    input wire [4:0] rs2_id,
    input wire [4:0] rs1_exe,
    input wire [4:0] rs2_exe,
    input wire [4:0] rs2_mem,
    input wire [4:0] rd_mem,
    input wire [4:0] rd_wb,
    input wire reg_write_mem,
    input wire reg_write_wb,

    output wire forward_rd1_id,
    output wire forward_rd2_id,
    output wire [1:0] forward_rd1_exe,
    output wire [1:0] forward_rd2_exe,
    output wire forward_rd2_mem,


    // hazard handler data required from the data path
    input wire mem_to_reg_exe,
    input wire [4:0] rd_exe,

    // signals to control the flow of the pipeline
    output logic if_id_reg_clr, 
    output logic id_exe_reg_clr,
    output logic exe_mem_reg_clr,
    output logic mem_wb_reg_clr,

    output logic if_id_reg_en, 
    output logic id_exe_reg_en,
    output logic exe_mem_reg_en,
    output logic mem_wb_reg_en,
    output logic pc_reg_en,

    input logic stall_pipl
);

    logic csr_write_wire; //mashael csr write enable
    logic csr_data_sel_wire; // Whether to use immediate or register for CSR op
    logic csr_to_reg_wire;      // Whether to write CSR value to register
    logic is_csr_instr_wire;    // Whether instruction is CSR
    logic is_mret_instr_wire;   // Whether instruction is MRET    
    
    decode_control dec_ctrl_inst (
        .opcode(opcode_id),
        .func3(fun3_id),
        .funct12(funct12),
        .reg_write(reg_write_id),
        .mem_write(mem_write_id),
        .mem_to_reg(mem_to_reg_id),
        .branch(branch_id),
        .alu_src(alu_src_id),
        .jump(jump_id),
        .alu_op(alu_op_id),
        .lui(lui_id),
        .auipc(auipc_id),
        .jal(jal_id),
        .r_type(r_type_id),
        //CSR
        .csr_write(csr_write_wire), //mashael csr write enable
        .csr_data_sel(csr_data_sel_wire), // Whether to use immediate or register for CSR op
        .csr_to_reg(csr_to_reg_wire),      // Whether to write CSR value to register
        .is_csr_instr(is_csr_instr_wire),   // Whether instruction is CSR
        .is_mret_instr(is_mret_instr_wire)    // Whether instruction is MRET

    );
    
    assign csr_write=csr_write_wire; //mashael csr write enable
    assign csr_data_sel_id=csr_data_sel_wire;// Whether to use immediate or register for CSR op
    assign csr_to_reg=csr_to_reg_wire;     // Whether to write CSR value to register
    assign is_csr_instr=is_csr_instr_wire;   // Whether instruction is CSR
    assign is_mret_instr=is_mret_instr_wire;   // Whether instruction is MRET    


    wire exe_use_rs1_id;
    wire exe_use_rs2_id;

    assign exe_use_rs1_id = ~(auipc_id | lui_id);
    assign exe_use_rs2_id = r_type_id | branch_id;

    alu_control alu_controller_inst (
        .fun3(fun3_exe),
        .fun7_5(fun7_5_exe),
        .alu_op(alu_op_exe),
        .alu_ctrl(alu_ctrl_exe)
    );

    branch_controller branch_controller_inst (
        .fun3(branch_t'(fun3_mem)),
        .branch(branch_mem),
        .jump(jump_mem),
        .zero(zero_mem),
        .pc_sel(pc_sel_mem)
    );

    // 
    forwarding_unit forwarding_unit_inst(
        .*
    );

    // detect if there is load hazard
    wire load_hazard;
    wire branch_hazard;
    logic mem_read_exe;
    assign mem_read_exe = mem_to_reg_exe;
    
    hazard_handler hazard_handler_inst (
        .*
    );

    pipeline_controller pipeline_controller_inst(
        .load_hazard(load_hazard),
        .branch_hazard(branch_hazard),
        .stall_pipl(stall_pipl),
        .*,        
        .trap_taken(trap_taken),     
        .mret_exec(mret_exec)

    );

endmodule
