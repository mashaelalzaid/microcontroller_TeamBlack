module csr_file (
    input logic clk,
    input logic reset_n,
    

    input  logic [11:0] csr_addr,      
    input  logic [31:0] csr_wdata,
    input  logic        csr_wen,
    input  logic [2:0]  csr_op,    
    output logic [31:0] csr_rdata,

    input  logic timer_int,            
    
    input  logic [31:0] current_pc,   
    output logic trap_taken,
    output logic [31:0] trap_pc, //   trap_pc, mret_pc should be muxed with next pc in rv32i
    // MRET handling
    input  logic        mret_exec,     // q: where does this come from? is is pipelined from the csr decoding stage or somewhere else?
    output logic [31:0] mret_pc        // this should be mux-ed with pc in rv32i_top
);


// machine trap setup

    localparam CSR_MSTATUS     = 12'h300;
    localparam CSR_MIE         = 12'h304;
    localparam CSR_MTVEC       = 12'h305;
    
    // machine trap handling
    localparam CSR_MSCRATCH    = 12'h340;
    localparam CSR_MEPC        = 12'h341;
    localparam CSR_MCAUSE      = 12'h342;
    localparam CSR_MIP         = 12'h344;
    
    // CSR operation types
    localparam CSR_WRITE = 3'b001;  // CSRRW
    localparam CSR_SET   = 3'b010;  // CSRRS
    localparam CSR_CLEAR = 3'b011;  // CSRRC
    
    logic [31:0] mstatus;   
    logic [31:0] mie;       
    logic [31:0] mtvec;     
    logic [31:0] mscratch;  
    logic [31:0] mepc;      
    logic [31:0] mcause;    
    logic [31:0] mip;       
    
    
        // Timer interrupt cause value
    localparam TIMER_INT_CAUSE = 7;
    
    //  read 
    always_comb begin
        case(csr_addr)
            CSR_MSTATUS:     csr_rdata = mstatus;
            CSR_MIE:         csr_rdata = mie;
            CSR_MTVEC:       csr_rdata = mtvec;
            CSR_MSCRATCH:    csr_rdata = mscratch;
            CSR_MEPC:        csr_rdata = mepc;
            CSR_MCAUSE:      csr_rdata = mcause;
            CSR_MIP:         csr_rdata = mip;
            default:         csr_rdata = 32'h0;
        endcase
    end
    
    
   
   
//   ======================================= START
   
         assign  trap_taken = mstatus[3] && mip[7] && mie[7] && !mret_exec; // Q: should i explicitly exclude && !mret_exec;

      // Trap detection logic 
    always_comb begin

        if (trap_taken) begin
            if (mtvec[0] == 1'b0) begin
                trap_pc = {mtvec[31:2], 2'b00};
            end
            else begin
                trap_pc = {mtvec[31:2], 2'b00} + 32'd28;  // 7 * 4 = 28 and it should be generaliable 
          //      trap_pc = {mtvec[31:2], 2'b00} + (TIMER_INT_CAUSE << 2);
            end
        end
        else begin
            trap_pc = 32'h0;  
        end
    end
    
    
    //xRET sets the pc to the value stored in the xepc register
    //pc should be = mret_pc
    assign mret_pc = mepc;
   
   
//   ======================================= END
   
    
    
//3.4. Reset Upon reset, a hart's privilege mode is set to M. The mstatus fields MIE and MPRV are reset to 0.
//The pc is set to an implementation-defined reset vector. 
//The mcause register is set to a value indicating the cause of the reset.
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mstatus     <= 32'h0;
            mie         <= 32'h0;
            mtvec       <= 32'h0;
            mscratch    <= 32'h0;
            mepc        <= 32'h0;
            mcause      <= 32'h0;
            mip         <= 32'h0;
        end
        else begin
            // Update timer interrupt pending bit

            mip[7] <= timer_int; 
            
//            =============================================== START =============================================== 
             //             assign trap_taken = mstatus[3] && mip[7] && mie[7];
  
            // MRET instruction handler
            
            ///An MRET  instruction is used to return from a trap in M-mode. When
            //executing an xRET instruction, xIE is set to xPIE;
            // xPIE is set to 1; and xPP is set to the least-privileged supported mode (U if U-mode is
            //implemented, else M). If y≠M, xRET also sets MPRV=0
            if (mret_exec) begin
                mstatus[3] <= mstatus[7];
                mstatus[7] <= 1'b1;       
              //  trap_taken=1'b0; /// Q: should i explicitly disable trap taken here?

            end
            
            // Timer interrupt handling
            else if (trap_taken) begin
                mepc <= current_pc & 32'hFFFF_FFFE;; //the two low bits (mepc[1:0]) are always zero. //q: should i account for that here ?
                
                mcause <= {1'b1, 27'b0, 4'd7}; //this should be modified when we start having more interrupt types
                // Update status register for trap entry
                mstatus[7] <= mstatus[3];   
                mstatus[3] <= 1'b0;     
                mip[7] <= 1'b0;  // : Clear mip[7] after servicing interrupt   //Q: should i do this?
            end

            
            
            
//            =============================================== END =============================================== 

            // CSR write operations
            if (csr_wen) begin
                case(csr_addr) 
                    CSR_MSTATUS: begin
                        case(csr_op)
                            CSR_WRITE: mstatus <= csr_wdata; //    t = CSRs[csr]; CSRs[csr] = x[rs1]; x[rd] = t

                            CSR_SET:   mstatus <= mstatus | csr_wdata; //  t = CSRs[csr]; CSRs[csr] = t | x[rs1]; x[rd] = t

                            CSR_CLEAR: mstatus <= mstatus & ~csr_wdata; //t = CSRs[csr]; CSRs[csr] = t &∼x[rs1]; x[rd] = t

                        endcase
                    end
                    
                    CSR_MIE: begin
                        case(csr_op)
                            CSR_WRITE: mie <= csr_wdata; 
                            CSR_SET:   mie <= mie | csr_wdata;
                            CSR_CLEAR: mie <= mie & ~csr_wdata;
                        endcase
                    end
                    
                    CSR_MTVEC: begin
                        case(csr_op) 
                            CSR_WRITE: mtvec <= csr_wdata; //& 32'hFFFF_FFFC; // 4-byte aligned 
                            CSR_SET:   mtvec <= (mtvec | csr_wdata); //& 32'hFFFF_FFFC;
                            CSR_CLEAR: mtvec <= (mtvec & ~csr_wdata);// & 32'hFFFF_FFFC;
                        endcase
                    end
                    
                    CSR_MSCRATCH: begin
                        case(csr_op)
                            CSR_WRITE: mscratch <= csr_wdata;
                            CSR_SET:   mscratch <= mscratch | csr_wdata;
                            CSR_CLEAR: mscratch <= mscratch & ~csr_wdata;
                        endcase
                    end
                    
                    CSR_MEPC: begin
                        case(csr_op) 
                            CSR_WRITE: mepc <= csr_wdata & 32'hFFFF_FFFE; // 2-byte aligned
                            CSR_SET:   mepc <= (mepc | csr_wdata) & 32'hFFFF_FFFE;
                            CSR_CLEAR: mepc <= (mepc & ~csr_wdata) & 32'hFFFF_FFFE;
                        endcase
                    end
                    
                    CSR_MCAUSE: begin
                        case(csr_op)
                            CSR_WRITE: mcause <= csr_wdata;
                            CSR_SET:   mcause <= mcause | csr_wdata;
                            CSR_CLEAR: mcause <= mcause & ~csr_wdata;
                        endcase
                    end
                endcase
            end
          
          
          
       end
    end
    


endmodule



////////////////////////////////////////////// =================== SECOND MODULE


//module csr_file (
//    input logic clk,
//    input logic reset_n,
    

//    input  logic [11:0] csr_addr,      
//    input  logic [31:0] csr_wdata,
//    input  logic        csr_wen,
//    input  logic [2:0]  csr_op,    
//    output logic [31:0] csr_rdata,

//    input  logic timer_int,            
    
//    input  logic [31:0] current_pc,   
//    output logic trap_taken,
//    output logic [31:0] trap_pc, //   trap_pc, mret_pc should be muxed with next pc in rv32i
//    // MRET handling
//    input  logic        mret_exec,     // q: where does this come from? is is pipelined from the csr decoding stage or somewhere else?
//    output logic [31:0] mret_pc        // this should be mux-ed with pc in rv32i_top
//);


//// machine trap setup

//    localparam CSR_MSTATUS     = 12'h300;
//    localparam CSR_MIE         = 12'h304;
//    localparam CSR_MTVEC       = 12'h305;
    
//    // machine trap handling
//    localparam CSR_MSCRATCH    = 12'h340;
//    localparam CSR_MEPC        = 12'h341;
//    localparam CSR_MCAUSE      = 12'h342;
//    localparam CSR_MIP         = 12'h344;
    
//    // CSR operation types
//    localparam CSR_WRITE = 3'b001;  // CSRRW
//    localparam CSR_SET   = 3'b010;  // CSRRS
//    localparam CSR_CLEAR = 3'b011;  // CSRRC
    
//    logic [31:0] mstatus;   
//    logic [31:0] mie;       
//    logic [31:0] mtvec;     
//    logic [31:0] mscratch;  
//    logic [31:0] mepc;      
//    logic [31:0] mcause;    
//    logic [31:0] mip;       
    
//    //  read 
//    always_comb begin
//        case(csr_addr)
//            CSR_MSTATUS:     csr_rdata = mstatus;
//            CSR_MIE:         csr_rdata = mie;
//            CSR_MTVEC:       csr_rdata = mtvec;
//            CSR_MSCRATCH:    csr_rdata = mscratch;
//            CSR_MEPC:        csr_rdata = mepc;
//            CSR_MCAUSE:      csr_rdata = mcause;
//            CSR_MIP:         csr_rdata = mip;
//            default:         csr_rdata = 32'h0;
//        endcase
//    end
    
////3.4. Reset Upon reset, a hart's privilege mode is set to M. The mstatus fields MIE and MPRV are reset to 0.
////The pc is set to an implementation-defined reset vector. 
////The mcause register is set to a value indicating the cause of the reset.
//    always_ff @(posedge clk or negedge reset_n) begin
//        if (!reset_n) begin
//            mstatus     <= 32'h0;
//            mie         <= 32'h0;
//            mtvec       <= 32'h0;
//            mscratch    <= 32'h0;
//            mepc        <= 32'h0;
//            mcause      <= 32'h0;
//            mip         <= 32'h0;
//        end
//        else begin
//            // Update timer interrupt pending bit

//            mip[7] <= timer_int; 
            
//            // CSR write operations
//            if (csr_wen) begin
//                case(csr_addr) 
//                    CSR_MSTATUS: begin
//                        case(csr_op)
//                            CSR_WRITE: mstatus <= csr_wdata; //    t = CSRs[csr]; CSRs[csr] = x[rs1]; x[rd] = t

//                            CSR_SET:   mstatus <= mstatus | csr_wdata; //  t = CSRs[csr]; CSRs[csr] = t | x[rs1]; x[rd] = t

//                            CSR_CLEAR: mstatus <= mstatus & ~csr_wdata; //t = CSRs[csr]; CSRs[csr] = t &∼x[rs1]; x[rd] = t

//                        endcase
//                    end
                    
//                    CSR_MIE: begin
//                        case(csr_op)
//                            CSR_WRITE: mie <= csr_wdata; 
//                            CSR_SET:   mie <= mie | csr_wdata;
//                            CSR_CLEAR: mie <= mie & ~csr_wdata;
//                        endcase
//                    end
                    
//                    CSR_MTVEC: begin
//                        case(csr_op) 
//                            CSR_WRITE: mtvec <= csr_wdata & 32'hFFFF_FFFC; // 4-byte aligned 
//                            CSR_SET:   mtvec <= (mtvec | csr_wdata) & 32'hFFFF_FFFC;
//                            CSR_CLEAR: mtvec <= (mtvec & ~csr_wdata) & 32'hFFFF_FFFC;
//                        endcase
//                    end
                    
//                    CSR_MSCRATCH: begin
//                        case(csr_op)
//                            CSR_WRITE: mscratch <= csr_wdata;
//                            CSR_SET:   mscratch <= mscratch | csr_wdata;
//                            CSR_CLEAR: mscratch <= mscratch & ~csr_wdata;
//                        endcase
//                    end
                    
//                    CSR_MEPC: begin
//                        case(csr_op) 
//                            CSR_WRITE: mepc <= csr_wdata & 32'hFFFF_FFFE; // 2-byte aligned
//                            CSR_SET:   mepc <= (mepc | csr_wdata) & 32'hFFFF_FFFE;
//                            CSR_CLEAR: mepc <= (mepc & ~csr_wdata) & 32'hFFFF_FFFE;
//                        endcase
//                    end
                    
//                    CSR_MCAUSE: begin
//                        case(csr_op)
//                            CSR_WRITE: mcause <= csr_wdata;
//                            CSR_SET:   mcause <= mcause | csr_wdata;
//                            CSR_CLEAR: mcause <= mcause & ~csr_wdata;
//                        endcase
//                    end
//                endcase
//            end
          
          
          
//              assign trap_taken = mstatus[3] && mip[7] && mie[7] && !mret_exec;
  
//            // MRET instruction handler
            
//            ///An MRET  instruction is used to return from a trap in M-mode. When
//            //executing an xRET instruction, xIE is set to xPIE;
//            // xPIE is set to 1; and xPP is set to the least-privileged supported mode (U if U-mode is
//            //implemented, else M). If y≠M, xRET also sets MPRV=0
//            if (mret_exec) begin
//           //     trap_taken<=1'b0;
//                mstatus[3] <= mstatus[7];
//                mstatus[7] <= 1'b0;       
//            end
            
//            // Timer interrupt handling
//            if (trap_taken) begin
//                mepc <= current_pc & 32'hFFFF_FFFE;; //the two low bits (mepc[1:0]) are always zero. //q: should i account for that here ?
                
//                mcause <= {1'b1, 27'b0, 4'd7}; //this should be modified when we start having more interrupt types
//                // Update status register for trap entry
//                mstatus[7] <= mstatus[3];   
//                mstatus[3] <= 1'b0;     
//                mip[7] <= 1'b0;  // : Clear mip[7] after servicing interrupt   
//            end
//        end
//    end
    
//    // Detect if a timer interrupt should be taken
//  //  logic        trap_taken;
//  //  logic [31:0] trap_pc;

////    assign trap_taken = mstatus[3] && mip[7] && mie[7];
    

//    always_comb begin
//        if (trap_taken) begin
//            if (mtvec[0] == 1'b0) begin
//                trap_pc = {mtvec[31:2], 2'b00}; 
//                                    end
//            else begin

//                trap_pc = {mtvec[31:2], 2'b00} + 32'd28;  // 7 * 4 = 28 and it should be generaliable 
//               //trap_pc = {mtvec[31:2], 2'b00} + (mcause[4:0] * 4);   

//            end
//        end
//        else begin
//            trap_pc = 32'h0;  
//        end
//    end
    
    
//    //xRET sets the pc to the value stored in the xepc register
//    //pc should be = mret_pc
//    assign mret_pc = mepc;

//endmodule
