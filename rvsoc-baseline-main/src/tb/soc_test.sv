`timescale 1ns / 1ps

module soc_test;

    // Testbench signals
    logic clk;
    logic reset_n;
    // GPIO signals
    logic [31:0] io_data;  // Bidirectional 32-bit GPIO data bus
    
    // UART signals
    logic srx_pad_i;  // UART Serial Receive
    logic stx_pad_o;  // UART Serial Transmit
    logic rts_pad_o;  // UART Ready to Send
    logic cts_pad_i;  // UART Clear to Send
    

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

     logic [15:0] SW;
     logic [15:0] LED;
     
    rv32i_soc_fpag_top #(1024,1024) uut (
        .CLK100MHZ (clk),
        .CPU_RESETN (reset_n),
        .UART_TXD_IN (),
        .UART_RXD_OUT (),
        .UART_CTS (),
        .UART_RTS (),
        .SW (SW),
        .LED (LED)
    );


    // Clock generation
    always #5 clk = ~clk; // 10ns period
    
    // Task to reset the system
    task reset_system;
        begin
            reset_n = 0;
            #20;
            reset_n = 1;
        end
    endtask
    initial begin
//    for(int i=0 ; i < 128; i++)
//        dut.rom_instance.rom[i]=0;
//       $readmemh("machine.mem", dut.rom_instance.rom);
   end // wait

//    // Task to test GPIO functionality
//    task test_gpio;
//        logic [31:0] gpio_input;
//        begin
//            $display("Testing GPIO functionality...");
//            gpio_input = 32'hA5A5A5A5;
//            force dut.io_data = gpio_input; // Force GPIO input value
//            #10;
//            release dut.io_data; // Release control of GPIO
            
//            if (dut.i_gpio !== gpio_input) 
//                $display("ERROR: GPIO input mismatch!");
//            else 
//                $display("GPIO input test PASSED!");

//            // Test output functionality
//            force dut.o_gpio = 32'h5A5A5A5A;
//            force dut.en_gpio = 32'hFFFFFFFF;
//            #10;
            
//            if (dut.io_data !== 32'h5A5A5A5A)
//                $display("ERROR: GPIO output mismatch!");
//            else
//                $display("GPIO output test PASSED!");

//            release dut.o_gpio;
//            release dut.en_gpio;
//        end
//    endtask
    // Main test sequence
//    assign dut.uart.srx_pad_i=dut.uart.stx_pad_o;
    initial begin
        // Initialize signals
        clk = 0;
        reset_n = 0;
        
        // Apply reset
        reset_system();

        // Test GPIO
//        test_gpio();
        // Finish simulation
    end
endmodule