`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/25/2025 03:05:33 PM
// Design Name: 
// Module Name: clint_wishbone
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
module clint_wishbone (
    input logic wb_clk_i,       
    input logic wb_rst_i,       
    input logic wb_cyc_i,       
    input logic wb_stb_i,       
    input logic wb_we_i,        
    input logic [31:0] wb_adr_i, 
    input logic [31:0] wb_dat_i, 
    output logic [31:0] wb_dat_o, 
    output logic wb_ack_o,       
    output logic mtip_o         
);
    logic wb_acc;
    assign wb_acc = wb_stb_i & wb_cyc_i;
    assign wb_ack_o = wb_acc;
    
    // memory mapped registers
    logic [63:0] mtime;
    logic [63:0] mtimecmp;

    //mmapped address
    localparam logic [31:0] MTIMECMP_ADDR = 32'h20000C00;
    localparam logic [31:0] MTIME_ADDR    = 32'h20000C08;

    // 64-bit Machine Time Counter 
    always_ff @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            mtime <= 64'b0;
            mtimecmp <= 64'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
 //           mtimecmp <= 64'h64;//100
            end
        else
            mtime <= mtime + 1; 
    end

    always_ff @(posedge wb_clk_i) begin
        if (wb_cyc_i && wb_stb_i) begin
            if (wb_we_i) begin
                case (wb_adr_i)
                    MTIMECMP_ADDR + 0: mtimecmp[31:0]  <= wb_dat_i; // Write lower 32 bits
                    MTIMECMP_ADDR + 4: mtimecmp[63:32] <= wb_dat_i; // Write upper 32 bits
                endcase
            end else begin
                case (wb_adr_i)
                    MTIME_ADDR + 0:    wb_dat_o <= mtime[31:0];  // Read lower 32 bits
                    MTIME_ADDR + 4:    wb_dat_o <= mtime[63:32]; // Read upper 32 bits
                    MTIMECMP_ADDR + 0: wb_dat_o <= mtimecmp[31:0]; // Read lower 32 bits of mtimecmp
                    MTIMECMP_ADDR + 4: wb_dat_o <= mtimecmp[63:32]; // Read upper 32 bits of mtimecmp
                    default:           wb_dat_o <= 32'h00000000; // Default read value
                endcase
            end
        end
    end
    //generate interrupt
    
       assign mtip_o = (mtime >= mtimecmp);

endmodule
