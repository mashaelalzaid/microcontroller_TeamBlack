
    module fetch_stage_2(
    input  logic        clk,
    input  logic        reset_n,
    input  logic        if_id_reg_en,       // Enable pipeline register
    input  logic        if_id_reg_clr,      // Clear pipeline register
    input  logic [31:0] fetch1_instruction, // Instruction from fetch_1
    input  logic        is_second_half_needed, // Need second half of instruction
    input  logic        is_compressed,      // Compressed instruction flag from fetch_1
    input  logic        pc_word_aligned,    // PC is word-aligned
    
    output logic [31:0] fetch2_instruction, // Instruction for decompression
    output logic        decompressor_en,    // Enable decompressor
    output logic        instr_valid         // Valid instruction ready
);

    // Internal registers for instruction parts
    logic [31:0] saved_first_half;
    logic        waiting_for_second_half;
    logic        decompressor_en_next; // Pipeline register for correct timing

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            fetch2_instruction     <= 32'h0;
            saved_first_half       <= 32'h0;
            waiting_for_second_half <= 1'b0;
            decompressor_en        <= 1'b0;
            instr_valid            <= 1'b0;
        end else if (if_id_reg_clr) begin
            waiting_for_second_half <= 1'b0;
            instr_valid             <= 1'b0;
            decompressor_en         <= 1'b0;
        end else if (if_id_reg_en) begin
            instr_valid <= 1'b1;
            decompressor_en <= 1'b0; // Default to 0, only asserted when needed
            
            if (waiting_for_second_half) begin
                // Now we have the second half, assemble full instruction
                fetch2_instruction <= {fetch1_instruction[15:0], saved_first_half[31:16]};
                waiting_for_second_half <= 1'b0;
                decompressor_en <= 1'b1; // Assert enable exactly when instruction is ready
            end else if (is_second_half_needed) begin
                // First half received, waiting for second half
                saved_first_half <= fetch1_instruction;
                waiting_for_second_half <= 1'b1;
                instr_valid <= 1'b0; // Not valid yet, need second half
            end else begin
                // Normal instruction processing
                if (is_compressed) begin
                    decompressor_en <= 1'b1; // Assert enable correctly
                    // Extract the proper half based on PC alignment
                    if (pc_word_aligned) begin
                        fetch2_instruction <= {16'b0, fetch1_instruction[15:0]};
                    end else begin
                        fetch2_instruction <= {16'b0, fetch1_instruction[31:16]};
                    end
                end else begin
                    // Standard 32-bit instruction
                    fetch2_instruction <= fetch1_instruction;
                end 
            end
        end
    end
endmodule

