`timescale 1ns / 1ps

module soc_test;

    // Testbench signals
    logic CLK100MHZ;
    logic CPU_RESETN;
    
    // UART signals
    logic UART_TXD_IN;
    logic UART_RXD_OUT;
    logic UART_CTS;
    logic UART_RTS;
    
    // Switch and LED signals
    logic [15:0] SW;
    logic [15:0] LED;
    
    // Monitoring signals
    logic [31:0] current_pc;
    logic [31:0] current_inst;
    
    // Memory will be loaded from machine.mem via TEST_MODE=1
    
    // Instantiate the DUT (Device Under Test)
    rv32i_soc_fpag_top DUT (
        .CLK100MHZ(CLK100MHZ),
        .CPU_RESETN(CPU_RESETN),
        .UART_TXD_IN(UART_TXD_IN),
        .UART_RXD_OUT(UART_RXD_OUT),
        .UART_CTS(UART_CTS),
        .UART_RTS(UART_RTS),
        .SW(SW),
        .LED(LED)
    );
    
    // Get access to internal signals for monitoring
    assign current_pc = DUT.current_pc_OUT;
    assign current_inst = DUT.inst_OUT;
    
    // Clock generation (100MHz)
    always #5 CLK100MHZ = ~CLK100MHZ;
    
    // Task to reset the system
    task reset_system;
        begin
            $display("Resetting system...");
            CPU_RESETN = 0;
            #100;
            CPU_RESETN = 1;
            $display("Reset complete");
        end
    endtask
    
    // Note: Program loading is controlled by TEST_MODE parameter
    // The test will use the memory file specified by TEST_MODE=1 (machine.mem)
    // We'll create this file separately
    
    // Task to monitor LED changes
    task monitor_leds;
        input int duration_ns;
        logic [15:0] last_led_value;
        int led_changes;
        begin
            last_led_value = LED;
            led_changes = 0;
            
            $display("Starting LED monitoring for %0d ns", duration_ns);
            fork
                begin
                    // Monitor thread
                    forever begin
                        @(LED);
                        if (LED != last_led_value) begin
                            led_changes++;
                            $display("Time: %0t - LED changed from 0x%h to 0x%h", $time, last_led_value, LED);
                            last_led_value = LED;
                        end
                    end
                end
                
                begin
                    // Timer thread
                    #(duration_ns);
                    $display("LED monitoring complete - Observed %0d changes", led_changes);
                    disable fork;
                end
            join
        end
    endtask
    
    // Task to test switch input
    task test_switches;
        begin
            $display("Testing switch input...");
            
            // Try different switch combinations
            SW = 16'h0000;
            #1000;
            $display("Set SW=0x0000, LED=0x%h", LED);
            
            SW = 16'hFFFF;
            #1000;
            $display("Set SW=0xFFFF, LED=0x%h", LED);
            
            SW = 16'hA5A5;
            #1000;
            $display("Set SW=0xA5A5, LED=0x%h", LED);
            
            SW = 16'h5A5A;
            #1000;
            $display("Set SW=0x5A5A, LED=0x%h", LED);
            
            // Reset switches
            SW = 16'h0000;
        end
    endtask
    
    // Task to monitor program execution
    task monitor_execution;
        input int duration_ns;
        begin
            $display("Starting execution monitoring for %0d ns", duration_ns);
            fork
                begin
                    // Monitor thread
                    forever begin
                        @(current_pc);
                        $display("Time: %0t - PC: 0x%h, Instruction: 0x%h", 
                                $time, current_pc, current_inst);
                    end
                end
                
                begin
                    // Timer thread
                    #(duration_ns);
                    $display("Execution monitoring complete");
                    disable fork;
                end
            join
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize signals
        CLK100MHZ = 0;
        CPU_RESETN = 1;
        UART_TXD_IN = 1;  // Idle high for UART
        UART_CTS = 1;     // Clear to send
        SW = 16'h0000;
        
        // Note: Program is loaded via TEST_MODE=1 parameter
        // which loads from machine.mem
        
        // Apply reset
        reset_system();
        
        // Monitor program execution for a short time
        monitor_execution(5000);
        
        // Test switch inputs
        test_switches();
        
        // Monitor LED changes for a longer period to observe timer interrupts
        monitor_leds(50000);
        
        // Finish simulation
        $display("Simulation complete at time %0t", $time);
        $finish;
    end

    
    // Timeout to prevent infinite simulation
    initial begin
        #1000000; // 1ms timeout
        $display("Simulation timeout reached at time %0t", $time);
        $finish;
    end
    
endmodule