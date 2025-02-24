`timescale 1ns / 1ps

module soc_test;

    // Testbench signals
    logic clk;
    logic reset_n;
    wire [31:0] io_data;
    logic tx, rx;
    
    
//    // Instantiate the DUT (Device Under Test)
//    rv32i_soc dut (
//        .clk(clk),
//        .reset_n(reset_n),
//        .io_data(io_data),
//        .srx_pad_i(rx),
//        .stx_pad_o(tx)
//    );
        logic [15:0] SW;
     logic [15:0] LED;
 rv32i_soc_fpag_top  dut(
    .CLK100MHZ(clk), 
    .CPU_RESETN(reset_n),
    .UART_TXD_IN(tx),
    .io_data(io_data),
.SW(SW), .LED(LED)
 );
    
    
////        wire [31:0]   io_data;
//    assign io_data[31:16] = SW;
//    assign LED = io_data[15:0];

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

////    // Task to test GPIO functionality
//    task test_gpio;
//        logic [31:0] gpio_input;
//        begin
//            $display("Testing GPIO functionality...");
//            gpio_input = 32'hA5A5A5A5;
//            force dut.soc_inst.io_data = gpio_input; // Force GPIO input value
//            #10;
//            release dut.soc_inst.io_data; // Release control of GPIO
            
//            if (dut.soc_inst.i_gpio !== gpio_input) 
//                $display("ERROR: GPIO input mismatch!");
//            else 
//                $display("GPIO input test PASSED!");

//            // Test output functionality
//            force dut.soc_inst.o_gpio = 32'h5A5A5A5A;
//            force dut.soc_inst.en_gpio = 32'hFFFFFFFF;
//            #10;
            
//            if (dut.soc_inst.io_data !== 32'h5A5A5A5A)
//                $display("ERROR: GPIO output mismatch!");
//            else
//                $display("GPIO output test PASSED!");

//            release dut.soc_inst.o_gpio;
//            release dut.soc_inst.en_gpio;
//        end
//    endtask
    // Main test sequence
//    assign dut.uart.srx_pad_i=dut.uart.stx_pad_o;
assign    io_data[31:16] = 16'b0001111;

    initial begin
        // Initialize signals
        clk = 0;
        reset_n = 0;
        
        // Apply reset
        reset_system();
   #10;
   
        // Test GPIO
//        test_gpio();
        // Finish simulation
    end
endmodule