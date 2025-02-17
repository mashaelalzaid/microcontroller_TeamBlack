module rv32i_soc #(
    parameter DMEM_DEPTH = 128,
    parameter IMEM_DEPTH = 128
) (
    input logic clk, 
    input logic reset_n,

    // spi signals to the spi-flash

    // uart signals

    // gpio signals
    inout wire [31:0]   io_data
);


    // Memory bus signals
    logic [31:0] mem_addr_mem;
    logic [31:0] mem_wdata_mem; 
    logic        mem_write_mem;
    logic [2:0]  mem_op_mem;
    logic [31:0] mem_rdata_mem;
    logic        mem_read_mem;
    

    // ============================================
    //          Processor Core Instantiation
    // ============================================
    logic stall_pipl;
    logic [31:0] current_pc;
    logic [31:0] inst; 
      logic        if_id_reg_en;
    // Instantiate the processor core here 
    rv32i_top rv32i_top (
        .clk(clk),
        .reset_n(reset_n),
    // memory bus
    .mem_op_mem(mem_op_mem),
    .mem_rdata_mem(mem_rdata_mem),

    // inst mem access 
    .current_pc(current_pc), 
    .inst(inst), //Q: should this be inst or data mem inst?

    // stall signal from wishbone 
    .stall_pipl(stall_pipl),
    .if_id_reg_en(if_id_reg_en),
    .mem_addr_mem   (mem_addr_mem),
    .mem_wdata_mem      (mem_wdata_mem),
    .mem_write_mem      (mem_write_mem),
    .mem_read_mem       (mem_read_mem)
    );


    // ============================================
    //                 Wishbone Master 
    // ============================================
  logic [31:0] wb_io_adr_i; 
  logic [31:0] wb_io_dat_i; 
  logic [ 3:0] wb_io_sel_i; 
  logic        wb_io_we_i;  
  logic        wb_io_cyc_i; 
  logic        wb_io_stb_i; 
  logic [ 2:0] wb_io_cti_i; 
  logic [ 1:0] wb_io_bte_i; 
  logic [31:0] wb_io_dat_o; 
  logic        wb_io_ack_o; 
  logic        wb_io_err_o;
  logic        wb_io_rty_o;
  
    wishbone_controller wishbone_master (
        .clk        (clk),
        .rst        (~reset_n),
        .proc_addr  (mem_addr_mem),
        .proc_wdata (mem_wdata_mem),
        .proc_write (mem_write_mem),
        .proc_read  (mem_read_mem),
        .proc_op    (mem_op_mem),
        .proc_rdata (mem_rdata_mem),
        .proc_stall_pipl(stall_pipl), // Stall pipeline if needed
        .wb_adr_o   (wb_io_adr_i),     // Connect to the external Wishbone bus as required
        .wb_dat_o   (wb_io_dat_i),
        .wb_sel_o   (wb_io_sel_i),
        .wb_we_o    (wb_io_we_i),
        .wb_cyc_o   (wb_io_cyc_i),
        .wb_stb_o   (wb_io_stb_i),
        .wb_dat_i   (wb_io_dat_o), // For simplicity, no data input
        .wb_ack_i   (wb_io_ack_o)   
    );
    assign wb_m2s_io_cti = 0;
    assign wb_m2s_io_bte  = 0;

    
    // ============================================
    //             Wishbone Interconnect 
    // ============================================
    // SPI FLASH SIGNALS 
  logic [31:0] wb_spi_flash_adr_o;
  logic [31:0] wb_spi_flash_dat_o;
  logic [ 3:0] wb_spi_flash_sel_o;
  logic        wb_spi_flash_we_o;
  logic        wb_spi_flash_cyc_o;
  logic        wb_spi_flash_stb_o;
  logic [ 2:0] wb_spi_flash_cti_o;
  logic [ 1:0] wb_spi_flash_bte_o;
  logic [31:0] wb_spi_flash_dat_i;
  logic        wb_spi_flash_ack_i;
  logic        wb_spi_flash_err_i;
  logic        wb_spi_flash_rty_i;

  // DMEM (Data Mem)
  logic [31:0] wb_dmem_adr_o;
  logic [31:0] wb_dmem_dat_o;
  logic [ 3:0] wb_dmem_sel_o;
  logic        wb_dmem_we_o;
  logic        wb_dmem_cyc_o;
  logic        wb_dmem_stb_o;
  logic [ 2:0] wb_dmem_cti_o;
  logic [ 1:0] wb_dmem_bte_o;
  logic [31:0] wb_dmem_dat_i;
  logic        wb_dmem_ack_i;
  logic        wb_dmem_err_i;
  logic        wb_dmem_rty_i;

  // IMEM (inst. mem)
  logic [31:0] wb_imem_adr_o;
  logic [31:0] wb_imem_dat_o;
  logic [ 3:0] wb_imem_sel_o;
  logic        wb_imem_we_o;
  logic        wb_imem_cyc_o;
  logic        wb_imem_stb_o;
  logic [ 2:0] wb_imem_cti_o;
  logic [ 1:0] wb_imem_bte_o;
  logic [31:0] wb_imem_dat_i;
  logic        wb_imem_ack_i;
  logic        wb_imem_err_i;
  logic        wb_imem_rty_i;

  // UART
  logic [31:0] wb_uart_adr_o;
  logic [31:0] wb_uart_dat_o;
  logic [ 3:0] wb_uart_sel_o;
  logic        wb_uart_we_o;
  logic        wb_uart_cyc_o;
  logic        wb_uart_stb_o;
  logic [ 2:0] wb_uart_cti_o;
  logic [ 1:0] wb_uart_bte_o;
  logic [31:0] wb_uart_dat_i;
  logic        wb_uart_ack_i;
  logic        wb_uart_err_i;
  logic        wb_uart_rty_i;

  // GPIO
  logic [31:0] wb_gpio_adr_o;
  logic [31:0] wb_gpio_dat_o;
  logic [ 3:0] wb_gpio_sel_o;
  logic        wb_gpio_we_o;
  logic        wb_gpio_cyc_o;
  logic        wb_gpio_stb_o;
  logic [ 2:0] wb_gpio_cti_o;
  logic [ 1:0] wb_gpio_bte_o;
  logic [31:0] wb_gpio_dat_i;
  logic        wb_gpio_ack_i;
  logic        wb_gpio_err_i;
  logic        wb_gpio_rty_i;

wb_intercon interconnect_inst (
    .*,
    .wb_clk_i(clk),
    .wb_rst_i(reset_n),
    // IO (wb master signals)
    .wb_io_cti_i(3'b000), // Q: what is the different values i have? 
    .wb_io_bte_i(2'b00) // Q: what is the different values i have? 
);


    // ============================================
    //                   Peripherals 
    // ============================================
    // Instantate the peripherals here

    // Here is the tri state buffer logic for setting iopin as input or output based
    // on the bits stored in the en_gpio register
    wire [31:0] en_gpio;
    wire        gpio_irq;

    wire [31:0] i_gpio;
    wire [31:0] o_gpio;

    genvar i;
    generate
            for( i = 0; i<32; i = i+1) 
            begin:gpio_gen_loop
                bidirec gpio1  (.oe(en_gpio[i] ), .inp(o_gpio[i] ), .outp(i_gpio[i] ), .bidir(io_data[i] ));
            end    
    endgenerate

    // ============================================
    //                 GPIO Instantiation
    // ============================================
    // Instantiate the GPIO peripheral here 

logic [31:0] gpio_wb_dat_o;
logic        gpio_wb_ack_o, gpio_wb_err_o, gpio_wb_inta_o;

gpio_top gpio(
.wb_clk_i(clk),	// Clock
.wb_rst_i(reset_n),	// Reset
.wb_cyc_i(wb_gpio_cyc_o),	// cycle valid input
.wb_adr_i(wb_gpio_adr_o),	// address bus inputs
.wb_dat_i(wb_gpio_dat_o),	// input data bus
.wb_sel_i(wb_gpio_sel_o),	// byte select inputs
.wb_we_i(wb_gpio_we_o ),	// indicates write transfer 
.wb_stb_i(wb_gpio_stb_o),	// strobe input
.wb_dat_o(gpio_wb_dat_o),	// output data bus // Q new new: where should the ouptut signals go? 
.wb_ack_o(gpio_wb_ack_o),	// normal termination
.wb_err_o(gpio_wb_err_o),	// termination w/ error
.wb_inta_o(gpio_wb_inta_o),	// Interrupt request output
.i_gpio(i_gpio   ),
.o_gpio(o_gpio),
.en_gpio(en_gpio)

);


    // ============================================
    //             Data Memory Instance
    // ============================================
    
    // Instantiate data memory here 
    data_mem #(
        .DEPTH(DMEM_DEPTH)
    ) data_mem (
        .clk_i       (clk            ),
        .rst_i       (~reset_n         ),
        .cyc_i       (wb_dmem_cyc_o), 
        .stb_i       (wb_dmem_stb_o),
        .adr_i       (wb_dmem_adr_o), 
        .we_i        (wb_dmem_we_o ),
        .sel_i       (wb_dmem_sel_o),
        .dat_i       (wb_dmem_dat_o), // Q new new: or wb_io_dat_o? or wb_dmem_dat_i?
        .dat_o       (wb_dmem_dat_i),// Q new new: or wb_dmem_dat_o?
        .ack_o       (wb_dmem_ack_i) // Q new new: should I pass wb_dmem_ack_i or wb_ack_o?
    );
 
    // ============================================
    //          Instruction Memory Instance
    // ============================================

    logic [31:0] imem_inst;

    logic [31:0] imem_addr;
  
  
    logic wb_s2m_imem_ack;
    logic [31:0] imem_dat_o;
        logic sel_boot_rom;

    assign imem_addr = sel_boot_rom ? wb_dmem_adr_o: current_pc;
    data_mem #(
        .DEPTH(IMEM_DEPTH)
    ) inst_mem_inst (
        .clk_i       (clk            ),
        .rst_i       (~reset_n         ),
        .cyc_i       (wb_imem_cyc_o), 
        .stb_i       (wb_imem_stb_o), 
        .adr_i       (imem_addr      ), 
        .we_i        (wb_imem_we_o ), 
        .sel_i       (wb_imem_sel_o),
        .dat_i       (wb_imem_dat_o), //Q new new: the dataout of wishbone is the input here right? 
        .dat_o       (imem_dat_o), //Q new new: where should this signal be sent back to?
        .ack_o       (wb_s2m_imem_ack)  //Q new new: where should this signal be sent back to?  
    );
    
    assign imem_inst = wb_imem_adr_o; //Q new new: why was this overwritten again? why didn't we use the mux like the first delaration?


    // BOOT ROM 
    logic [31:0] rom_inst, rom_inst_ff;
    rom rom_instance(
        .addr     (current_pc[11:0]),
        .inst     (rom_inst  )
    );

    // register after boot rom (to syncronize with the pipeline and inst mem)
    n_bit_reg #(
        .n(32)
    ) rom_inst_reg (
        .clk(clk),
        .reset_n(reset_n),
        .data_i(rom_inst),
        .data_o(rom_inst_ff),
        .wen(if_id_reg_en)
    );


    logic sel_boot_rom_ff;
    // Inst selection mux
    assign sel_boot_rom = &current_pc[31:12]; // 0xfffff000 - to - 0xffffffff 
    always @(posedge clk) 
    sel_boot_rom_ff <= sel_boot_rom; //Q new new: where should sel_boot_rom_ff come from ? it is not declared anywhere?
   
    mux2x1 #(
        .n(32)
    ) rom_imem_inst_sel_mux (
        .in0    (imem_inst      ),
        .in1    (rom_inst_ff    ),
        .sel    (sel_boot_rom_ff),
        .out    (inst           )
    );



    // ============================================
    //          SPI Instance
    // ============================================


localparam SS_WIDTH = 1;
// signal definition
logic       inta_o;       // interrupt output
logic       sck_o;        // serial clock output
logic [SS_WIDTH-1:0] ss_o;     // [SS_WIDTH-1:0] slave select (active low)
logic      mosi_o;     // MasterOut SlaveIN
assign mosi_o = wb_io_dat_i;

// connection
simple_spi #(SS_WIDTH) spi (

.clk_i(clk),         // clock
.rst_i(reset_n),         // reset (synchronous active high)//Q new new: should this be active high or low?
.cyc_i(wb_spi_flash_cyc_o),         // cycle
.stb_i(wb_spi_flash_stb_o),         // strobe
.adr_i(wb_spi_flash_adr_o),         // [2:0] address
.we_i(wb_spi_flash_we_o),         // write enable
.dat_i(wb_spi_flash_dat_o),         // [7:0]  data input
.dat_o(wb_spi_flash_dat_i),         // [7:0] data output
.ack_o(wb_spi_flash_ack_i),         // normal bus termination
.inta_o(),        // interrupt output // Q new new: what should be passed here? 
.sck_o(sck_o),         // serial clock output
.ss_o(ss_o),      // [SS_WIDTH-1:0] slave select (active low) //Q new new: what should be passed here? 
.mosi_o(mosi_o),        // MasterOut SlaveIN
.miso_i(wb_io_dat_o)         // MasterIn SlaveOut
);

    
endmodule : rv32i_soc