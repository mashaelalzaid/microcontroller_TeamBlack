module pipeline_controller (
    input logic load_hazard,
    input logic branch_hazard,
    input logic stall_pipl,

    output logic if_id_reg_clr, 
    output logic id_exe_reg_clr,
    output logic exe_mem_reg_clr,
    output logic mem_wb_reg_clr,
    input logic trap_taken,     // New: Signal when trap is requested
    input logic mret_exec,        // New: Signal when MRET is executed

    output logic if_id_reg_en, 
    output logic id_exe_reg_en,
    output logic exe_mem_reg_en,
    output logic mem_wb_reg_en,
    output logic pc_reg_en
);


    logic base_if_id_reg_clr, base_id_exe_reg_clr, base_exe_mem_reg_clr;
    logic base_if_id_reg_en, base_id_exe_reg_en, base_exe_mem_reg_en, base_mem_wb_reg_en, base_pc_reg_en;
    
    assign base_if_id_reg_clr = branch_hazard;
    assign base_id_exe_reg_clr = branch_hazard | load_hazard;
    assign base_exe_mem_reg_clr = branch_hazard;

    assign base_if_id_reg_en = ~(stall_pipl | load_hazard);
    assign base_id_exe_reg_en = ~stall_pipl;
    assign base_exe_mem_reg_en = ~stall_pipl;
    assign base_mem_wb_reg_en = ~stall_pipl;
    assign base_pc_reg_en = ~(stall_pipl | load_hazard);
    

 //    trap_taken and mret_exec  override other hazards
    assign if_id_reg_clr = base_if_id_reg_clr | trap_taken | mret_exec;
    assign id_exe_reg_clr = base_id_exe_reg_clr | trap_taken | mret_exec;
    assign exe_mem_reg_clr = base_exe_mem_reg_clr | trap_taken | mret_exec;
    assign mem_wb_reg_clr = 1'b0; // never clear
 
 

    assign if_id_reg_en = base_if_id_reg_en;
    assign id_exe_reg_en = base_id_exe_reg_en;
    assign exe_mem_reg_en = base_exe_mem_reg_en;
    assign mem_wb_reg_en = base_mem_wb_reg_en;
    
    assign pc_reg_en = base_pc_reg_en | trap_taken | mret_exec;


endmodule


