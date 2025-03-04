typedef enum logic [6:0] {
    R_TYPE = 7'b0110011, 
    I_TYPE = 7'b0010011, 
    B_TYPE = 7'b1100011, 
    JAL    = 7'b1101111, 
    JALR   = 7'b1100111, 
    LOAD   = 7'b0000011, 
    STORE  = 7'b0100011, 
    LUI    = 7'b0110111, 
    AUIPC = 7'b0010111,    
    SYSTEM  = 7'b1110011 
} inst_type;

module decode_control (
    input logic [6:0] opcode,
    input logic [2:0] func3,
        input logic [11:0] funct12,   //mashael Added for MRET detection (instruction bits [31:20])
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
    output logic r_type,
    output logic csr_write, //mashael csr write enable
    output logic csr_data_sel, // Whether to use immediate or register for CSR op
    output logic csr_to_reg,      // Whether to write CSR value to register
    output logic is_csr_instr,    // Whether instruction is CSR
    output logic is_mret_instr    // Whether instruction is MRET
);

    logic invalid_inst;
    assign  invalid_inst = ~|opcode[1:0]; // all valid instructions start with 2'b11
    parameter LOAD_STORE = 2'b00, R_TYPE = 2'b11, I_TYPE = 2'b01, B_TYPE = 2'b10;
    // new signals for csr
//    logic csr_to_reg;//this has to be logic and not 0 or 1 hard wired
//    logic csr_data_sel;
//    logic csr_write;

    //mashael MRET function code
    localparam MRET_FUNCT12 = 12'h302;
    
    //mashael Detect if we have a MRET instruction (SYSTEM op + func3=0 + funct12=0x302)
    assign is_mret_instr = (opcode == SYSTEM) && (func3 == 3'b000) && (funct12 == MRET_FUNCT12);
    
    //mashael Detect if we have a CSR instruction (SYSTEM op + func3!=0)
    assign is_csr_instr = (opcode == SYSTEM) && (func3 != 3'b000);

    
    always @(opcode) begin
        case(opcode[6:0])
            7'b0110011: begin reg_write=1; mem_write=0; mem_to_reg=0; alu_op=R_TYPE; alu_src=0; branch=0; jump=0; lui=0; auipc=0; jal=0; r_type=1; csr_data_sel=0; csr_to_reg=0; end // R-type
            7'b0010011: begin reg_write=1; mem_write=0; mem_to_reg=0; alu_op=I_TYPE; alu_src=1; branch=0; jump=0; lui=0; auipc=0; jal=0; r_type=0; csr_data_sel=0;  csr_to_reg=0;end // I-type
            7'b1100111: begin reg_write=1; mem_write=0; mem_to_reg=0; alu_op=LOAD_STORE; alu_src=1; branch=0; jump=1; lui=0; auipc=0; jal=0; r_type=0; csr_data_sel=0;  csr_to_reg=0;end // I-type JALR
            7'b0000011: begin reg_write=1; mem_write=0; mem_to_reg=1; alu_op=LOAD_STORE; alu_src=1; branch=0; jump=0; lui=0; auipc=0; jal=0; r_type=0; csr_data_sel=0;  csr_to_reg=0;end // Load
            7'b0100011: begin reg_write=0; mem_write=1; mem_to_reg=0; alu_op=LOAD_STORE; alu_src=1; branch=0; jump=0; lui=0; auipc=0; jal=0; r_type=0; csr_data_sel=0;  csr_to_reg=0;end // Store
            7'b1100011: begin reg_write=0; mem_write=0; mem_to_reg=0; alu_op=B_TYPE; alu_src=0; branch=1; jump=0; lui=0; auipc=0; jal=0; r_type=0; csr_data_sel=0;  csr_to_reg=0;end // B-type
            7'b1101111: begin reg_write=1; mem_write=0; mem_to_reg=0; alu_op=LOAD_STORE; alu_src=1; branch=0; jump=1; lui=0; auipc=0; jal=1; r_type=0; csr_data_sel=0;  csr_to_reg=0;end // J-type
            7'b0110111: begin reg_write=1; mem_write=0; mem_to_reg=0; alu_op=LOAD_STORE; alu_src=1; branch=0; jump=0; lui=1; auipc=0; jal=0; r_type=0; csr_data_sel=0;  csr_to_reg=0;end // LUI
            7'b0010111: begin reg_write=1; mem_write=0; mem_to_reg=0; alu_op=LOAD_STORE; alu_src=1; branch=0; jump=0; lui=0; auipc=1; jal=0; r_type=0; csr_data_sel=0;  csr_to_reg=0;end // AUIPC
//            7'b1110011: begin reg_write='bx; mem_write='bx; mem_to_reg='bx; alu_op='bx; alu_src='bx; branch='bx; jump='bx; lui='bx; auipc='bx; jal='bx; r_type='bx; assign csr_data_sel=func3[2]; end // CSRR // TODO Xs to be replaced with correct signals
//            default: begin reg_write=0; mem_write=0; mem_to_reg=0; alu_op=2'b00; alu_src=0; branch=0; jump=0; lui=0; auipc=0; jal=0; r_type=0; end // NOP
        7'b1110011: begin 
            // SYSTEM instructions (CSR or MRET)
            if (is_mret_instr) begin 
                // MRET or other system instructions with func3=0
                reg_write=0; mem_write=0; mem_to_reg=0; alu_op=2'b00; alu_src=0; 
                branch=0; jump=0; lui=0; auipc=0; jal=0; r_type=0; 
                csr_write=0; csr_data_sel=0; csr_to_reg=0;
            end else if (is_csr_instr) begin
                // CSR instructions (func3 != 000)
                reg_write=1; mem_write=0; mem_to_reg=0; alu_op=2'b00; alu_src=0; //mashael maybe  alu_op = LOAD_STORE; 
                branch=0; jump=0; lui=0; auipc=0; jal=0; r_type=0; 
                csr_write=1; csr_data_sel=func3[2]; csr_to_reg=1;
            end
        end
        
        default: begin reg_write=0; mem_write=0; mem_to_reg=0; alu_op=2'b00; alu_src=0; branch=0; jump=0; lui=0; auipc=0; jal=0; r_type=0; csr_write=0; csr_data_sel=0; csr_to_reg=0; end // NOP
    endcase
    end


 
    
//    logic jump_or_upper_immediate;
//    assign jump_or_upper_immediate = opcode[2];

//    logic jalr;

//    logic br_or_jump;
//    assign br_or_jump = opcode[6];

//    logic [3:0] decoder_o;
//    n_bit_dec_with_en #(
//            .n(2)
//    ) type_decoder (
//            .en(~jump_or_upper_immediate & ~br_or_jump),
//            .in(opcode[5:4]),
//            .out(decoder_o)
//        );

//    logic i_type, load, store, b_type, u_type;

//    assign b_type = br_or_jump & ~jump;
//    assign i_type =  decoder_o[1];
//    assign r_type =  decoder_o[3];
//    assign load   =  decoder_o[0];
//    assign store =  decoder_o[2];
//    assign u_type = jump_or_upper_immediate & opcode[4];


//    assign jump     = jump_or_upper_immediate & ~opcode[4]; 
//    assign jal   = jump_or_upper_immediate & ~opcode[4] & opcode[3]; 
//    assign lui   = u_type & opcode[5]; 
//    assign auipc = u_type & ~opcode[5];

    
//    assign mem_write = store;
//    assign branch    = b_type;
//    assign alu_src   = ~(r_type | b_type);
//    assign alu_op = opcode[5:4] & {2{~(store | jump_or_upper_immediate)}};
//    assign mem_to_reg = load & ~invalid_inst;

//    assign reg_write = ~ (b_type | store);

endmodule : decode_control
