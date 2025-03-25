`timescale 1ns / 1ps

module atomic_fsm (
    input  logic clk,
    input  logic reset_n,
    

    input  logic mem_is_lr,
    input  logic mem_is_sc,
    input logic is_atomic, 
    input logic [4:0] amo_op, 

    input  logic [31:0] mem_address,
    input  logic [31:0] mem_rdata, 
    input  logic [31:0] rs2_value, 
    output logic [31:0] mem_wdata,
    output logic mem_read_enable,
    output logic mem_write_enable,
    
    output logic atomic_success,
    

    output logic release_stall            // this should be connected back with control unit to release stall
);

    // FSM states definition
    typedef enum logic [1:0] {
        IDLE      = 2'b00,
        LR_EXECUTE = 2'b01,
        SC_WRITE   = 2'b11
    } atomic_state_t;

    // Internal state registers
    atomic_state_t state, next_state;
    
    // Internal signals for reservation register
    logic [31:0] reservation_addr;
    logic reservation_valid;
        // Registered version of the release_stall signal
    logic release_stall_r;
    logic [1:0] release_counter;
    // State register
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            reservation_valid <= 1'b0;
            reservation_addr <= 32'b0;
             release_stall_r <= 1'b0;
             release_counter <= 2'b00;
        end else begin
            // State transition
            state <= next_state;
//            release_stall_r <= (state != IDLE) && (next_state == IDLE);
            
            if ((state != IDLE) && (next_state == IDLE)) begin
            
            release_stall_r <= 1'b1;
            release_counter <= 2'b01; // Will keep release_stall high for 1 more cycle
            
            end else if (release_counter > 0) begin
            release_counter <= release_counter - 1;
            release_stall_r <= 1'b1;
        end else begin
            release_stall_r <= 1'b0;
        end

            // Data capture in specific states
            if (state == LR_EXECUTE) begin
                // LR sets up reservation
                reservation_addr <= mem_address;
                reservation_valid <= 1'b1;
            end
            
            // Clear reservation after SC instruction (always)
            if (state == SC_WRITE) begin
                reservation_valid <= 1'b0;
            end
        end
    end
    
    // Next state logic
    always_comb begin
        // Default: stay in current state
        next_state = state;
        
        case (state)
            IDLE: begin
                if (mem_is_lr)
                    next_state = LR_EXECUTE;
                else if (mem_is_sc)
                    next_state = SC_WRITE;
            end
            
            LR_EXECUTE: begin
                next_state = IDLE; // LR takes just one cycle (read + reservation setup)
            end
            
            SC_WRITE: begin
                next_state = IDLE; // SC takes one cycle (check reservation + conditional write)
            end
        endcase
    end
    
    // Output logic
    always_comb begin
        // Default values
        mem_read_enable = 1'b0;
        mem_write_enable = 1'b0;
        atomic_success = 1'b0;
        release_stall = 1'b0;
        mem_wdata = 32'b0;
                // Use the registered version of release_stall
        release_stall = release_stall_r;
        // Signal completion when returning to IDLE from any other state
//        if ((state != IDLE) && (next_state == IDLE))
//            release_stall = 1'b1;
        
        case (state)
            IDLE: begin
                // When transitioning to LR, start with a read
                if (mem_is_lr)
                    mem_read_enable = 1'b1;
            end
            
            LR_EXECUTE: begin
                // LR already read in IDLE state, no additional memory access needed
                mem_read_enable = 1'b1;
                atomic_success = 1'b1; // LR always succeeds
            end
            
            SC_WRITE: begin
                // SC conditionally writes based on reservation validity
                if (reservation_valid && (reservation_addr == mem_address)) begin
                    mem_write_enable = 1'b1;
                    mem_wdata = rs2_value;
                    atomic_success = 1'b1; // SC succeeded
                    // Note: reservation will be cleared in the next cycle
                end else begin
                    atomic_success = 1'b0; // SC failed
                end
            end
        endcase
    end
    
        // Debug logic - add this before the endmodule
    //`ifdef SIMULATION
    always @(posedge clk) begin
        if (release_stall)
            $display("Time %0t: release_stall asserted", $time);
        
        if (state != next_state)
            $display("Time %0t: FSM State change: %s -> %s", $time,
                     (state == IDLE) ? "IDLE" : 
                     (state == LR_EXECUTE) ? "LR_EXECUTE" : "SC_WRITE",
                     (next_state == IDLE) ? "IDLE" : 
                     (next_state == LR_EXECUTE) ? "LR_EXECUTE" : "SC_WRITE");
    end
   // `endif
    
    
endmodule