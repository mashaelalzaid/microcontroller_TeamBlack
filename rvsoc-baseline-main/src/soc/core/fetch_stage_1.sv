
module fetch_stage_1(
    input logic         clk, 
    input logic         reset_n, 
    input logic         pc_reg_en, 
    input logic [31:0]  current_pc, 
    input logic [31:0]  instruction, 
    input logic         is_jump_instr, 
    input logic [31:0]  jump_address, 
    input logic         trap_taken, 
    input logic [31:0]  trap_pc, 
    input logic         mret_exec, 
    input logic [31:0]  mret_pc, 
    
    output logic [31:0] next_pc, 
    output logic        pc_word_aligned,
    output logic [31:0] fetch1_instruciton, 
    output logic        is_compressed, 
    output logic        is_second_half_needed
); 

    logic valid_inst, pc_halfword_aligned, is_compressed_reg;

    assign pc_word_aligned = (current_pc[1:0] == 2'b00 && valid_inst);
    assign pc_halfword_aligned = (current_pc[1:0] == 2'b10 && valid_inst);
    
    always_ff @(posedge clk or negedge reset_n) begin 
        if (!reset_n) begin 
            valid_inst <= 1'b0;
            fetch1_instruciton <= 32'b0;   
            is_compressed_reg <= 1'b0; // Initialize correctly
        end else if (pc_reg_en) begin
            valid_inst <= 1'b1;
            fetch1_instruciton <= instruction;
            
            // Delay setting `is_compressed` to the next cycle
            if (instruction[1:0] != 2'b11) begin
                is_compressed_reg <= 1'b1; // Set if compressed
            end else begin
                is_compressed_reg <= 1'b0; // Standard 32-bit instruction
            end
        end 
    end 

    assign is_compressed = is_compressed_reg; // Use registered value
    
    always_comb begin
        next_pc = current_pc;
        is_second_half_needed = 1'b0;
        
        // PC alignment checks
        if (pc_word_aligned) begin 
            if (is_compressed_reg) begin 
                next_pc = current_pc + 32'd2;
            end else begin
                next_pc = current_pc + 32'd4;
            end
        end else begin 
            if (is_compressed_reg) begin 
                next_pc = current_pc + 32'd2;
            end else begin 
                next_pc = current_pc + 32'd2;
                is_second_half_needed = 1'b1;
            end
        end
        
        // Handle special control flow
        if (trap_taken) begin
            next_pc = trap_pc;
        end else if (mret_exec) begin
            next_pc = mret_pc;
        end else if (is_jump_instr) begin
            if (is_compressed_reg) begin
                if (jump_address[1:0] == 2'b00 || jump_address[1:0] == 2'b10) begin
                    next_pc = jump_address;
                end else begin
                    next_pc = jump_address & ~32'h1;
                end
            end else begin
                if (jump_address[1:0] == 2'b00) begin
                    next_pc = jump_address;
                end else begin
                    next_pc = jump_address & ~32'h3;
                end
            end
        end
    end

endmodule
