`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/11/2025 01:25:37 AM
// Design Name: 
// Module Name: decompressor
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
module decompressor(
    input  logic         decompressor_en,
    input  logic [15:0]  IF_Instr_16,
    output logic [31:0]  IF_Dec_32
);

  always_comb begin
    // enabeled when decompressor_en is high.
    if (!decompressor_en)
      IF_Dec_32 = 32'b0;
    else begin
      case ({IF_Instr_16[15:13], IF_Instr_16[1:0]})
        //c.addi4spn
        5'b00000: IF_Dec_32 = {2'b00, IF_Instr_16[10:7], IF_Instr_16[12:11],
                                IF_Instr_16[5], IF_Instr_16[6], 2'b00,
                                5'd2, 3'b000, 2'b01, IF_Instr_16[4:2], 7'b0010011};
        //c.lw 
        5'b01000: IF_Dec_32 = {5'b00000, IF_Instr_16[5], IF_Instr_16[12:10],
                                IF_Instr_16[6], 2'b00, 2'b01, IF_Instr_16[9:7],
                                3'b010, 2'b01, IF_Instr_16[4:2], 7'b0000011};
        //c.sw 
        5'b11000: IF_Dec_32 = {5'b00000, IF_Instr_16[5], IF_Instr_16[12],
                                2'b01, IF_Instr_16[4:2], 2'b01, IF_Instr_16[9:7],
                                3'b010, IF_Instr_16[11:10], IF_Instr_16[6], 2'b00,
                                7'b0100011};
        5'b00001: begin
          //c.nop 
          if (IF_Instr_16[12:2] == 11'b0)
            IF_Dec_32 = {25'b0, 7'b0010011};
          //c.addi
          else
            IF_Dec_32 = {{7{IF_Instr_16[12]}}, IF_Instr_16[6:2],
                         IF_Instr_16[11:7], 3'b000, IF_Instr_16[11:7],
                         7'b0010011};
        end
        //c.jal 
        5'b00101: IF_Dec_32 = {IF_Instr_16[12], IF_Instr_16[8],
                                IF_Instr_16[10:9], IF_Instr_16[6],
                                IF_Instr_16[7], IF_Instr_16[2],
                                IF_Instr_16[11], IF_Instr_16[5:3],
                                IF_Instr_16[12], {8{IF_Instr_16[12]}},
                                5'd1, 7'b1101111};
        //c.li 
        5'b01001: IF_Dec_32 = {{7{IF_Instr_16[12]}}, IF_Instr_16[6:2],
                                5'd0, 3'b000, IF_Instr_16[11:7],
                                7'b0010011};
        5'b01101: begin
          //c.addi16sp 
          if (IF_Instr_16[11:7] == 5'd2)
            IF_Dec_32 = {{3{IF_Instr_16[12]}}, IF_Instr_16[4],
                         IF_Instr_16[3], IF_Instr_16[5],
                         IF_Instr_16[2], IF_Instr_16[6], 4'b0000,
                         5'd2, 3'b000, 5'd2, 7'b0010011};
          // c.lui 
          else
            IF_Dec_32 = {{15{IF_Instr_16[12]}}, IF_Instr_16[6:2],
                         IF_Instr_16[11:7], 7'b0110111};
        end
        5'b10001: begin
          //c.sub
          if ((IF_Instr_16[12:10] == 3'b011) && (IF_Instr_16[6:5] == 2'b00))
            IF_Dec_32 = {7'b0100000, 2'b01, IF_Instr_16[4:2],
                         2'b01, IF_Instr_16[9:7], 3'b000,
                         2'b01, IF_Instr_16[9:7], 7'b0110011};
          //c.xor 
          else if ((IF_Instr_16[12:10] == 3'b011) && (IF_Instr_16[6:5] == 2'b01))
            IF_Dec_32 = {7'b0000000, 2'b01, IF_Instr_16[4:2],
                         2'b01, IF_Instr_16[9:7], 3'b100,
                         2'b01, IF_Instr_16[9:7], 7'b0110011};
          //c.or
          else if ((IF_Instr_16[12:10] == 3'b011) && (IF_Instr_16[6:5] == 2'b10))
            IF_Dec_32 = {7'b0000000, 2'b01, IF_Instr_16[4:2],
                         2'b01, IF_Instr_16[9:7], 3'b110,
                         2'b01, IF_Instr_16[9:7], 7'b0110011};
          //c.and
          else if ((IF_Instr_16[12:10] == 3'b011) && (IF_Instr_16[6:5] == 2'b11))
            IF_Dec_32 = {7'b0000000, 2'b01, IF_Instr_16[4:2],
                         2'b01, IF_Instr_16[9:7], 3'b111,
                         2'b01, IF_Instr_16[9:7], 7'b0110011};
          //c.andi
          else if (IF_Instr_16[11:10] == 2'b10)
            IF_Dec_32 = {{7{IF_Instr_16[12]}}, IF_Instr_16[6:2],
                         2'b01, IF_Instr_16[9:7], 3'b111,
                         2'b01, IF_Instr_16[9:7], 7'b0010011};
          //Skip instruction
          else if ((IF_Instr_16[12] == 1'b0) && (IF_Instr_16[6:2] == 5'b0))
            IF_Dec_32 = 32'b0;
          //c.srli
          else if (IF_Instr_16[11:10] == 2'b00)
            IF_Dec_32 = {7'b0000000, IF_Instr_16[6:2],
                         2'b01, IF_Instr_16[9:7], 3'b101,
                         2'b01, IF_Instr_16[9:7], 7'b0010011};
          //c.srai
          else
            IF_Dec_32 = {7'b0100000, IF_Instr_16[6:2],
                         2'b01, IF_Instr_16[9:7], 3'b101,
                         2'b01, IF_Instr_16[9:7], 7'b0010011};
        end
        //c.j
        5'b10101: IF_Dec_32 = {IF_Instr_16[12], IF_Instr_16[8],
                                IF_Instr_16[10:9], IF_Instr_16[6],
                                IF_Instr_16[7], IF_Instr_16[2],
                                IF_Instr_16[11], IF_Instr_16[5:3],
                                IF_Instr_16[12], {8{IF_Instr_16[12]}},
                                5'd0, 7'b1101111};
        //c.beqz
        5'b11001: IF_Dec_32 = {{4{IF_Instr_16[12]}}, IF_Instr_16[6],
                                IF_Instr_16[5], IF_Instr_16[2], 5'd0,
                                2'b01, IF_Instr_16[9:7], 3'b000,
                                IF_Instr_16[11], IF_Instr_16[10],
                                IF_Instr_16[4], IF_Instr_16[3],
                                IF_Instr_16[12], 7'b1100011};
        //c.bnez
        5'b11101: IF_Dec_32 = {{4{IF_Instr_16[12]}}, IF_Instr_16[6],
                                IF_Instr_16[5], IF_Instr_16[2], 5'd0,
                                2'b01, IF_Instr_16[9:7], 3'b001,
                                IF_Instr_16[11], IF_Instr_16[10],
                                IF_Instr_16[4], IF_Instr_16[3],
                                IF_Instr_16[12], 7'b1100011};
        //c.slli 
        5'b00010: IF_Dec_32 = {7'b0000000, IF_Instr_16[6:2],
                                IF_Instr_16[11:7], 3'b001,
                                IF_Instr_16[11:7], 7'b0010011};
        //c.lwsp
        5'b01010: IF_Dec_32 = {4'b0000, IF_Instr_16[3:2],
                                IF_Instr_16[12], IF_Instr_16[6:4],
                                2'b0, 5'd2, 3'b010,
                                IF_Instr_16[11:7], 7'b0000011};
        //c.swsp 
        5'b11010: IF_Dec_32 = {4'b0000, IF_Instr_16[8:7],
                                IF_Instr_16[12], IF_Instr_16[6:2],
                                5'd2, 3'b010, IF_Instr_16[11:9],
                                2'b00, 7'b0100011};
        5'b10010: begin
          if (IF_Instr_16[6:2] == 5'd0) begin
            //c.jalr
            if (IF_Instr_16[12] && (IF_Instr_16[11:7] != 5'b0))
              IF_Dec_32 = {12'b0, IF_Instr_16[11:7], 3'b000,
                           5'd1, 7'b1100111};
            //c.jr 
            else
              IF_Dec_32 = {12'b0, IF_Instr_16[11:7], 3'b000,
                           5'd0, 7'b1100111};
          end else if (IF_Instr_16[11:7] != 5'b0) begin
            //c.mv 
            if (IF_Instr_16[12] == 1'b0)
              IF_Dec_32 = {7'b0000000, IF_Instr_16[6:2],
                           5'd0, 3'b000, IF_Instr_16[11:7],
                           7'b0110011};
            //c.add 
            else
              IF_Dec_32 = {7'b0000000, IF_Instr_16[6:2],
                           IF_Instr_16[11:7], 3'b000,
                           IF_Instr_16[11:7], 7'b0110011};
          end
        end
        default: IF_Dec_32 = 32'b0;
      endcase
    end
  end

endmodule
