`timescale 1ns / 1ps
module soc_test;
    // Testbench signals
    logic clk;
    logic reset_n;
    
    // GPIO signals
    logic  [31:0] io_data;  // Bidirectional 32-bit GPIO data bus
    
    // UART signals
    logic srx_pad_i;  // UART Serial Receive
    logic stx_pad_o;  // UART Serial Transmit
    logic rts_pad_o;  // UART Ready to Send
    logic cts_pad_i;  // UART Clear to Send
    
    rv32i_soc #(
        512, 
        512
    ) dut (
        .clk(clk), 
        .reset_n(reset_n), // Input reset signal
        // UART signals
        .srx_pad_i(srx_pad_i),
        .stx_pad_o(stx_pad_o),
        .rts_pad_o(rts_pad_o),
        .cts_pad_i(cts_pad_i),
        // GPIO signals
        .io_data()
    );
    
    logic [15:0] SW;
    logic [15:0] LED;
     
//    rv32i_soc_fpag_top #(1024,1024) uut (
//        .CLK100MHZ(clk),
//        .CPU_RESETN(reset_n),
//        .UART_TXD_IN(1'b1),  // Idle state for UART RX
//        .UART_RXD_OUT(),
//        .UART_CTS(1'b0),
//        .UART_RTS(),
//        .SW(SW),
//        .LED(LED)
//    );
    
    // Clock generation
    always #5 clk = ~clk; // 10ns period (100MHz)
    
    // Task to reset the system
    task reset_system;
        begin
            reset_n = 0;
            #20;
            reset_n = 1;
        end
    endtask
    
    // Monitor ECALL-related signals
    initial begin
        $monitor("Time=%0t, PC=%h, a0=%h, mcause=%h, mepc=%h, mstatus=%h, trap_taken=%b", 
                 $time,
                 dut.rv32i_top.current_pc,
                 dut.rv32i_top.data_path_inst.reg_file_inst.reg_file[10], // a0 is x10
                 dut.rv32i_top.csr_file_inst.mcause,
                 dut.rv32i_top.csr_file_inst.mepc,
                 dut.rv32i_top.csr_file_inst.mstatus,
                 dut.rv32i_top.trap_taken);
    end
    
    // For debugging: print when ECALL is detected and when trap handler is entered
    always @(posedge clk) begin
        if (dut.rv32i_top.is_ecall_instr_mem)
            $display("Time=%0t: ECALL detected in memory stage", $time);
//            force dut.rv32i_top.mtvec = 32'
  
            
        if (dut.rv32i_top.trap_taken)
            $display("Time=%0t: Trap taken, jumping to address %h", $time, dut.rv32i_top.trap_pc);
    end
    
    
    // Main test sequence
    initial begin
        // Initialize signals
        clk = 0;
        reset_n = 0;
        srx_pad_i = 1'b1;  // UART idle
        cts_pad_i = 1'b0;  // Clear to Send active
        SW = 16'h0000;
        
        // Make sure test program is loaded in ROM
        // Note: We're assuming machine.mem is already loaded by rom.sv
        // If needed, uncomment and modify the following line:
        // $readmemh("machine.mem", dut.rom_instance.rom);
        
        // Apply reset
        reset_system();
        
        // Run simulation for enough time to observe ECALL and trap handler
        // Adjust this time based on your clock frequency and program length
//        #5000;
//                        force dut.rv32i_top.csr_file_inst.mtvec = 32'hABCD0000;
//  #50;
//  release dut.rv32i_top.csr_file_inst.mtvec;
        // Check if a0 contains 43 (initial 42 + 1 from trap handler)
        if (dut.rv32i_top.data_path_inst.reg_file_inst.reg_file[10] == 43)
            $display("ECALL Test PASSED! a0 = %d", dut.rv32i_top.data_path_inst.reg_file_inst.reg_file[10]);
        else
            $display("ECALL Test FAILED! a0 = %d", dut.rv32i_top.data_path_inst.reg_file_inst.reg_file[10]);
        
        // Run a bit longer to see if anything unexpected happens
        #1000;
        
        $finish;
    end
    
    // Optional: Dump waveforms for viewing in a waveform viewer
    initial begin
        $dumpfile("soc_test_ecall.vcd");
        $dumpvars(0, soc_test);
    end
endmodule


//`timescale 1ns / 1ps

//module soc_test;

//    // Testbench signals
//    logic clk;
//    logic reset_n;
//    // GPIO signals
//    logic [31:0] io_data;  // Bidirectional 32-bit GPIO data bus
    
//    // UART signals
//    logic srx_pad_i;  // UART Serial Receive
//    logic stx_pad_o;  // UART Serial Transmit
//    logic rts_pad_o;  // UART Ready to Send
//    logic cts_pad_i;  // UART Clear to Send
    

//rv32i_soc #(
//    512, 
//    512
//) dut (
//    .clk(clk), 
//    .reset_n(reset_n), // Input reset signal

//    // SPI signals to the SPI-Flash (not provided in your description)

//    // UART signals
//    .srx_pad_i(srx_pad_i),
//    .stx_pad_o(stx_pad_o),
//    .rts_pad_o(rts_pad_o),
//    .cts_pad_i(cts_pad_i),

//    // GPIO signals
//    .io_data()
//);

//     logic [15:0] SW;
//     logic [15:0] LED;
     
//    rv32i_soc_fpag_top #(1024,1024) uut (
//        .CLK100MHZ (clk),
//        .CPU_RESETN (reset_n),
//        .UART_TXD_IN (),
//        .UART_RXD_OUT (),
//        .UART_CTS (),
//        .UART_RTS (),
//        .SW (SW),
//        .LED (LED)
//    );


//    // Clock generation
//    always #5 clk = ~clk; // 10ns period
    
//    // Task to reset the system
//    task reset_system;
//        begin
//            reset_n = 0;
//            #20;
//            reset_n = 1;
//        end
//    endtask
//    initial begin
////    for(int i=0 ; i < 128; i++)
////        dut.rom_instance.rom[i]=0;
////       $readmemh("machine.mem", dut.rom_instance.rom);
//   end // wait

////    // Task to test GPIO functionality
////    task test_gpio;
////        logic [31:0] gpio_input;
////        begin
////            $display("Testing GPIO functionality...");
////            gpio_input = 32'hA5A5A5A5;
////            force dut.io_data = gpio_input; // Force GPIO input value
////            #10;
////            release dut.io_data; // Release control of GPIO
            
////            if (dut.i_gpio !== gpio_input) 
////                $display("ERROR: GPIO input mismatch!");
////            else 
////                $display("GPIO input test PASSED!");

////            // Test output functionality
////            force dut.o_gpio = 32'h5A5A5A5A;
////            force dut.en_gpio = 32'hFFFFFFFF;
////            #10;
            
////            if (dut.io_data !== 32'h5A5A5A5A)
////                $display("ERROR: GPIO output mismatch!");
////            else
////                $display("GPIO output test PASSED!");

////            release dut.o_gpio;
////            release dut.en_gpio;
////        end
////    endtask
//    // Main test sequence
////    assign dut.uart.srx_pad_i=dut.uart.stx_pad_o;
//    initial begin
//        // Initialize signals
//        clk = 0;
//        reset_n = 0;
        
//        // Apply reset
//        reset_system();

//        // Test GPIO
////        test_gpio();
//        // Finish simulation
//    end
//endmodule