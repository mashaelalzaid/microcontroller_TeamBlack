`timescale 1ns / 1ps

module soc_test;

    // Testbench signals
    logic clk;
    logic reset_n;
    wire [31:0] io_data;
    logic tx, rx;
    // Instantiate the DUT (Device Under Test)
    rv32i_soc dut (
        .clk(clk),
        .reset_n(reset_n),
        .io_data(io_data)
//        .rx(rx),
//        .tx(tx)
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
    for(int i=0 ; i < 128; i++)
        dut.rom_instance.rom[i]=0;
       $readmemh("machine.mem", dut.rom_instance.rom);
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
    assign dut.uart.srx_pad_i=dut.uart.stx_pad_o;
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