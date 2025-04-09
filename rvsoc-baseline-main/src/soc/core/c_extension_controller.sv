module c_extension_controller (
    input  logic        clk,
    input  logic        reset_n,
    
    // Interface with program counter
    input  logic [31:0] current_pc,     // Current PC from PC register
    output logic [31:0] next_pc,        // Next PC value for fetch
    output logic        hold_pc,        // Signal to hold PC (PC+0)
    
    // Interface with instruction memory
    input  logic [31:0] raw_inst,       // Raw instruction from memory
    
    // Interface with pipeline
    output logic [31:0] decompressed_inst, // Decompressed instruction
    output logic [31:0] corrected_pc,      // Corrected PC for instruction
    output logic        inst_valid         // Valid instruction signal
);

    // FSM states
    typedef enum logic [2:0] {
        STATE_NORMAL,   // Normal 32-bit execution
        STATE_SECOND16, // Processing second 16-bit instruction in a 32-bit word
        STATE_SPLIT32,  // Processing a 32-bit instruction split across fetches
        STATE_ERROR     // Error recovery
    } state_t;
    
    // Internal registers
    state_t current_state, next_state;
    logic [15:0] saved_half;        // Stores half of an instruction
    logic [31:0] saved_pc;          // PC of the saved half
    logic [31:0] raw_inst_saved;    // Save the full instruction for reference
    logic is_compressed;            // Flag for compressed instruction
    
    // Instruction detection
    // Critical fix: More precise detection of compressed instructions
    // Compressed instructions have the two LSBs != 2'b11
    logic is_lower_compressed;    // Lower 16 bits are compressed
    logic is_upper_compressed;    // Upper 16 bits are compressed
    logic v_inst, second_comp;    // Valid instruction indicator
    
    assign is_lower_compressed = v_inst && (raw_inst[1:0] != 2'b11);
    assign is_upper_compressed = v_inst && (raw_inst[17:16] != 2'b11);
    
    // Compressed instruction input to decompressor
    logic [31:0] compressed_input;
   
    // State register
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_state <= STATE_NORMAL;
            saved_half <= 16'h0;
            saved_pc <= 32'h0;
            raw_inst_saved <= 32'h0;
            v_inst <= 0;
        end else begin
            v_inst <= 1;
            current_state <= next_state;
            
            // Always save the full instruction for reference
            raw_inst_saved <= raw_inst;
            
// Update saved_half and saved_pc based on state transitions
case (current_state)
    STATE_NORMAL: begin
        // In normal state, save the upper half when lower is compressed but upper is not
        if (is_lower_compressed && !is_upper_compressed) begin
            saved_half <= raw_inst[31:16];  // Save upper half for split
            saved_pc <= current_pc;         // Save PC of this word
        end
    end
    
    STATE_SECOND16: begin
    end 
    
    STATE_SPLIT32:begin 
    end 
     default: begin
        // Keep previous values for other states
    end
endcase
        end
    end
    
    // State machine logic
    always_comb begin
        // Default values
        next_state = current_state;
        next_pc = current_pc + 4;    // Default: advance by 4
        hold_pc = 1'b0;              // Default: don't hold PC
        compressed_input = raw_inst; // Default: pass through
        corrected_pc = current_pc;   // Default: use current PC
        inst_valid = 1'b1;           // Default: instruction is valid
        is_compressed = 1'b0;        // Default: not compressed
        
        case (current_state)
            STATE_NORMAL: begin 
                if (is_lower_compressed) begin
                    // Lower 16 bits are compressed (00, 01, or 10)
                    is_compressed = 1'b1;
                    corrected_pc = current_pc;
                    
                    if (is_upper_compressed) begin
                        // Two consecutive 16-bit compressed instructions
                        second_comp = 1'b1; 
                        next_state = STATE_SECOND16;
                        next_pc = current_pc;     // Hold PC for second instruction
                        compressed_input = {16'b0, raw_inst[15:0]};
                        hold_pc = 1'b1;           // Hold PC until second half is executed
                    end else begin
                        // 16-bit instruction followed by first half of 32-bit
                        next_state = STATE_SPLIT32;
                        second_comp = 1'b0;
                        next_pc = current_pc + 4; // Need to fetch next word for second half
                        compressed_input = {16'b0, raw_inst[15:0]};
                        hold_pc = 1'b0;           // Allow PC to advance to get second half
                    end
                end else begin
                    // Lower 16 bits are not compressed (11)
                    is_compressed = 1'b0;
                    corrected_pc = current_pc;
                    compressed_input = raw_inst;
                    
                    // Standard 32-bit handling
                    next_state = STATE_NORMAL;
                    next_pc = current_pc + 4;
                    hold_pc = 1'b0;
                end
            end

            STATE_SECOND16: begin
                // Processing the second 16-bit instruction from the previous fetch
                is_compressed = 1'b1;
                compressed_input = {16'b0, raw_inst_saved[31:16]};
                corrected_pc = current_pc + 2; // PC for the upper half instruction
                
                // After this instruction, proceed to normal state
                next_state = STATE_NORMAL;
                next_pc = current_pc + 4;  // Move to next word
                hold_pc = 1'b0;            // Allow PC to advance
            end
            
            STATE_SPLIT32: begin
                // Now processing second half of a split 32-bit instruction
                
                // Critical Fix: Check all possible bit patterns for the second half
                // When in SPLIT32, we are reconstructing a split 32-bit instruction
                // where the first half was in the upper bits of previous word
                
                // We need to handle this regardless of the bit pattern in lower 16 bits
                // as we're expecting this to be the second half of a 32-bit instruction
                
                // Reconstruct the 32-bit instruction
                // saved_half = first half (0x0093), raw_inst[15:0] = second half (0x0200)
                compressed_input = {raw_inst[15:0], saved_half};
                is_compressed = 1'b0;         // This is a standard 32-bit instruction
                corrected_pc = saved_pc;      // PC points to start of first half
                
                // Determine next state based on upper half content
                if (is_upper_compressed) begin
                    // There's a compressed instruction in the upper half
                    next_state = STATE_SECOND16;
                    next_pc = current_pc;     // Stay at current word
                    hold_pc = 1'b1;           // Hold PC to process upper half
                end else begin
                    // Regular flow - no compressed in upper
                    next_state = STATE_NORMAL;
                    next_pc = current_pc + 4; // Move to next word
                    hold_pc = 1'b0;           // Allow PC to advance
                end
                
                // Always valid - we're processing what we expect
                inst_valid = 1'b1;
            end

            STATE_ERROR: begin
                inst_valid = 1'b0;
                next_state = STATE_NORMAL;
                next_pc = current_pc + 4;  // Skip to next word boundary
                hold_pc = 1'b0;            // Allow PC to continue
            end
            
            default: begin
                next_state = STATE_NORMAL;
                inst_valid = 1'b0;
                next_pc = current_pc + 4;
            end
        endcase
    end

    // Instantiate the decompressor
    instruction_decompressor decomp (
        .decompressor_en(is_compressed),
        .compressed_inst(compressed_input),  // Input
        .decompressed_inst(decompressed_inst) // Output to pipeline
    );

endmodule