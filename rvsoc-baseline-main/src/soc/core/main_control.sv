typedef enum logic [6:0] {
    R_TYPE = 7'b0110011, 
    I_TYPE = 7'b0010011, 
    B_TYPE = 7'b1100011, 
    JAL    = 7'b1101111, 
    JALR   = 7'b1100111, 
    LOAD   = 7'b0000011, 
    STORE  = 7'b0100011, 
    LUI    = 7'b0110111, 
    AUIPC = 7'b0010111
} inst_type;

module decode_control (
    input logic [6:0] opcode,
    output logic reg_write, 
    output logic mem_write, 
    output logic mem_to_reg, 
    output logic branch, 
    output logic alu_src, 
    output logic jump, 
    output logic [1:0] alu_op,
    output logic lui, 
    output logic auipc,
    output logic jal,
    output logic r_type
);


    
    logic jump_or_upper_immediate;
    assign jump_or_upper_immediate = opcode[2];

    logic invalid_inst;
    assign  invalid_inst = ~|opcode[1:0];


    logic jalr;

    logic br_or_jump;
    assign br_or_jump = opcode[6];

    logic [3:0] decoder_o;
    n_bit_dec_with_en #(
            .n(2)
    ) type_decoder (
            .en(~jump_or_upper_immediate & ~br_or_jump),
            .in(opcode[5:4]),
            .out(decoder_o)
        );

    logic i_type, load, store, b_type, u_type;

    assign b_type = br_or_jump & ~jump;
    assign i_type =  decoder_o[1];
    assign r_type =  decoder_o[3];
    assign load   =  decoder_o[0];
    assign store =  decoder_o[2];
    assign u_type = jump_or_upper_immediate & opcode[4];


    assign jump     = jump_or_upper_immediate & ~opcode[4]; 
    assign jal   = jump_or_upper_immediate & ~opcode[4] & opcode[3]; 
    assign lui   = u_type & opcode[5]; 
    assign auipc = u_type & ~opcode[5];

    
    assign mem_write = store;
    assign branch    = b_type;
    assign alu_src   = ~(r_type | b_type);
    assign alu_op = opcode[5:4] & {2{~(store | jump_or_upper_immediate)}};
    assign mem_to_reg = load & ~invalid_inst;

    assign reg_write = ~ (b_type | store);

endmodule : decode_control
