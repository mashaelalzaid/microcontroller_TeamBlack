`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/22/2025 02:46:18 AM
// Design Name: 
// Module Name: instruction_decompressor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module instruction_decompressor(
    input  logic         decompressor_en,
    input  logic [31:0]  compressed_inst,
    output logic [31:0]  decompressed_inst
);

    logic [15:0] compressed_instr;
    
    // Extract the compressed instruction
    assign compressed_instr = compressed_inst[15:0];
    
    // Decompression logic
    always_comb begin
        if (!decompressor_en)
            decompressed_inst = compressed_inst;
        else begin
            case ({compressed_instr[15:13], compressed_instr[1:0]})
                //c.addi4spn
                5'b00000: decompressed_inst = {2'b00, compressed_instr[10:7], compressed_instr[12:11],
                                compressed_instr[5], compressed_instr[6], 2'b00,
                                5'd2, 3'b000, 2'b01, compressed_instr[4:2], 7'b0010011};
                //c.lw 
                5'b01000: decompressed_inst = {5'b00000, compressed_instr[5], compressed_instr[12:10],
                                compressed_instr[6], 2'b00, 2'b01, compressed_instr[9:7],
                                3'b010, 2'b01, compressed_instr[4:2], 7'b0000011};
                //c.sw 
                5'b11000: decompressed_inst = {5'b00000, compressed_instr[5], compressed_instr[12],
                                2'b01, compressed_instr[4:2], 2'b01, compressed_instr[9:7],
                                3'b010, compressed_instr[11:10], compressed_instr[6], 2'b00,
                                7'b0100011};
                5'b00001: begin
                    //c.nop 
                    if (compressed_instr[12:2] == 11'b0)
                        decompressed_inst = {25'b0, 7'b0010011};
                    //c.addi
                    else
                        decompressed_inst = {{7{compressed_instr[12]}}, compressed_instr[6:2],
                                compressed_instr[11:7], 3'b000, compressed_instr[11:7],
                                7'b0010011};
                end
                //c.jal 
                5'b00101: decompressed_inst = {compressed_instr[12], compressed_instr[8],
                                compressed_instr[10:9], compressed_instr[6],
                                compressed_instr[7], compressed_instr[2],
                                compressed_instr[11], compressed_instr[5:3],
                                compressed_instr[12], {8{compressed_instr[12]}},
                                5'd1, 7'b1101111};
                //c.li 
                5'b01001: decompressed_inst = {{7{compressed_instr[12]}}, compressed_instr[6:2],
                                5'd0, 3'b000, compressed_instr[11:7],
                                7'b0010011};
                5'b01101: begin
                    //c.addi16sp 
                    if (compressed_instr[11:7] == 5'd2)
                        decompressed_inst = {{3{compressed_instr[12]}}, compressed_instr[4],
                                compressed_instr[3], compressed_instr[5],
                                compressed_instr[2], compressed_instr[6], 4'b0000,
                                5'd2, 3'b000, 5'd2, 7'b0010011};
                    // c.lui 
                    else
                        decompressed_inst = {{15{compressed_instr[12]}}, compressed_instr[6:2],
                                compressed_instr[11:7], 7'b0110111};
                end
                5'b10001: begin
                    //c.sub
                    if ((compressed_instr[12:10] == 3'b011) && (compressed_instr[6:5] == 2'b00))
                        decompressed_inst = {7'b0100000, 2'b01, compressed_instr[4:2],
                                2'b01, compressed_instr[9:7], 3'b000,
                                2'b01, compressed_instr[9:7], 7'b0110011};
                    //c.xor 
                    else if ((compressed_instr[12:10] == 3'b011) && (compressed_instr[6:5] == 2'b01))
                        decompressed_inst = {7'b0000000, 2'b01, compressed_instr[4:2],
                                2'b01, compressed_instr[9:7], 3'b100,
                                2'b01, compressed_instr[9:7], 7'b0110011};
                    //c.or
                    else if ((compressed_instr[12:10] == 3'b011) && (compressed_instr[6:5] == 2'b10))
                        decompressed_inst = {7'b0000000, 2'b01, compressed_instr[4:2],
                                2'b01, compressed_instr[9:7], 3'b110,
                                2'b01, compressed_instr[9:7], 7'b0110011};
                    //c.and
                    else if ((compressed_instr[12:10] == 3'b011) && (compressed_instr[6:5] == 2'b11))
                        decompressed_inst = {7'b0000000, 2'b01, compressed_instr[4:2],
                                2'b01, compressed_instr[9:7], 3'b111,
                                2'b01, compressed_instr[9:7], 7'b0110011};
                    //c.andi
                    else if (compressed_instr[11:10] == 2'b10)
                        decompressed_inst = {{7{compressed_instr[12]}}, compressed_instr[6:2],
                                2'b01, compressed_instr[9:7], 3'b111,
                                2'b01, compressed_instr[9:7], 7'b0010011};
                    //Skip instruction
                    else if ((compressed_instr[12] == 1'b0) && (compressed_instr[6:2] == 5'b0))
                        decompressed_inst = 32'b0;
                    //c.srli
                    else if (compressed_instr[11:10] == 2'b00)
                        decompressed_inst = {7'b0000000, compressed_instr[6:2],
                                2'b01, compressed_instr[9:7], 3'b101,
                                2'b01, compressed_instr[9:7], 7'b0010011};
                    //c.srai
                    else
                        decompressed_inst = {7'b0100000, compressed_instr[6:2],
                                2'b01, compressed_instr[9:7], 3'b101,
                                2'b01, compressed_instr[9:7], 7'b0010011};
                end
                //c.j
                5'b10101: decompressed_inst = {compressed_instr[12], compressed_instr[8],
                                compressed_instr[10:9], compressed_instr[6],
                                compressed_instr[7], compressed_instr[2],
                                compressed_instr[11], compressed_instr[5:3],
                                compressed_instr[12], {8{compressed_instr[12]}},
                                5'd0, 7'b1101111};
                //c.beqz
                5'b11001: decompressed_inst = {{4{compressed_instr[12]}}, compressed_instr[6],
                                compressed_instr[5], compressed_instr[2], 5'd0,
                                2'b01, compressed_instr[9:7], 3'b000,
                                compressed_instr[11], compressed_instr[10],
                                compressed_instr[4], compressed_instr[3],
                                compressed_instr[12], 7'b1100011};
                //c.bnez
                5'b11101: decompressed_inst = {{4{compressed_instr[12]}}, compressed_instr[6],
                                compressed_instr[5], compressed_instr[2], 5'd0,
                                2'b01, compressed_instr[9:7], 3'b001,
                                compressed_instr[11], compressed_instr[10],
                                compressed_instr[4], compressed_instr[3],
                                compressed_instr[12], 7'b1100011};
                //c.slli 
                5'b00010: decompressed_inst = {7'b0000000, compressed_instr[6:2],
                                compressed_instr[11:7], 3'b001,
                                compressed_instr[11:7], 7'b0010011};
                //c.lwsp
                5'b01010: decompressed_inst = {4'b0000, compressed_instr[3:2],
                                compressed_instr[12], compressed_instr[6:4],
                                2'b0, 5'd2, 3'b010,
                                compressed_instr[11:7], 7'b0000011};
                //c.swsp 
                5'b11010: decompressed_inst = {4'b0000, compressed_instr[8:7],
                                compressed_instr[12], compressed_instr[6:2],
                                5'd2, 3'b010, compressed_instr[11:9],
                                2'b00, 7'b0100011};
                5'b10010: begin
                    if (compressed_instr[6:2] == 5'd0) begin
                        //c.jalr
                        if (compressed_instr[12] && (compressed_instr[11:7] != 5'b0))
                            decompressed_inst = {12'b0, compressed_instr[11:7], 3'b000,
                                   5'd1, 7'b1100111};
                        //c.jr 
                        else
                            decompressed_inst = {12'b0, compressed_instr[11:7], 3'b000,
                                   5'd0, 7'b1100111};
                    end else if (compressed_instr[11:7] != 5'b0) begin
                        //c.mv 
                        if (compressed_instr[12] == 1'b0)
                            decompressed_inst = {7'b0000000, compressed_instr[6:2],
                                   5'd0, 3'b000, compressed_instr[11:7],
                                   7'b0110011};
                        //c.add 
                        else
                            decompressed_inst = {7'b0000000, compressed_instr[6:2],
                                   compressed_instr[11:7], 3'b000,
                                   compressed_instr[11:7], 7'b0110011};
                    end else begin
                        decompressed_inst = 32'b0;
                    end
                end
                default: decompressed_inst = compressed_inst;
            endcase
        end
    end

endmodule