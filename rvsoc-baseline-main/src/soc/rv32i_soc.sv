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
    
    // Instantiate the processor core here 
    rv32i_top processor (
        .clk(clk),
        .reset_n(~reset_n),
    // memory bus
    .mem_op_mem(mem_op_mem),
    .mem_rdata_mem(mem_rdata_mem),

    // inst mem access 
    .current_pc(current_pc), //Q: should it be current_pc[11:0]? or just current_pc
    .inst(inst), //Q: should this be inst or data mem inst?

    // stall signal from wishbone 
    .stall_pipl(stall_pipl),
    .if_id_reg_en(if_id_reg_en),
    .mem_addr_mem   (mem_addr_mem),
    .mem_wdata_mem      (mem_wdata_mem),
    .mem_write_mem      (mem_write_mem),
    .mem_write_mem         (mem_write_mem),
    .mem_write_mem      (mem_write_mem),
    .mem_read_mem       (mem_read_mem)
    );


    // ============================================
    //                 Wishbone Master 
    // ============================================
   logic [31:0] wb_adr_o,      // Wishbone address output
   logic [31:0] wb_dat_o,      // Wishbone data output
   logic [3:0]  wb_sel_o,      // Wishbone byte enable
   logic        wb_we_o,       // Wishbone write enable
   logic        wb_cyc_o,      // Wishbone cycle valid
   logic        wb_stb_o,      // Wishbone strobe
 

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
        .wb_adr_o   (wb_adr_o),     // Connect to the external Wishbone bus as required
        .wb_dat_o   (wb_dat_o),
        .wb_sel_o   (wb_sel_o),
        .wb_we_o    (wb_we_o),
        .wb_cyc_o   (wb_cyc_o),
        .wb_stb_o   (wb_stb_o),
        .wb_dat_i   (), // For simplicity, no data input
        .wb_ack_i   ()   // For simplicity, no acknowledgment signal
    );
    assign wb_m2s_io_cti = 0;
    assign wb_m2s_io_bte  = 0;

    
    // ============================================
    //             Wishbone Interconnect 
    // ============================================
    
    // Instantiate the wishbone interconnect here 
    logic [31:0] wb_io_dat_o;
    logic        wb_io_ack_o;
    logic        wb_io_err_o;
    logic        wb_io_rty_o;    
    // DATA MEM
    logic [31:0] wb_dmem_adr_o,
    logic [31:0] wb_dmem_dat_o,
    logic  [3:0] wb_dmem_sel_o,
    logic        wb_dmem_we_o, 
    logic        wb_dmem_cyc_o,
    logic        wb_dmem_stb_o,
    logic  [2:0] wb_dmem_cti_o,
    logic  [1:0] wb_dmem_bte_o,
    // IMEM
    logic [31:0] wb_imem_adr_o,
    logic [31:0] wb_imem_dat_o,
    logic  [3:0] wb_imem_sel_o,
    logic        wb_imem_we_o, 
    logic        wb_imem_cyc_o,
    logic        wb_imem_stb_o,
    logic  [2:0] wb_imem_cti_o,
    logic  [1:0] wb_imem_bte_o,
    //GPIO
    logic [31:0] wb_gpio_adr_o,
    logic [31:0] wb_gpio_dat_o,
    logic  [3:0] wb_gpio_sel_o,
    logic        wb_gpio_we_o,
    logic        wb_gpio_cyc_o,
    logic        wb_gpio_stb_o,
    logic  [2:0] wb_gpio_cti_o,
    logic  [1:0] wb_gpio_bte_o,

wb_intercon interconnect_inst (
    .wb_clk_i(clk),
    .wb_rst_i(~reset_n),

    // IO (wb master signals)
    .wb_io_adr_i(mem_addr_mem),
    .wb_io_dat_i(mem_wdata_mem),
    .wb_io_sel_i(wb_sel_o), //// Q: double check, if this is the write thing?
    .wb_io_we_i(mem_write_mem),
    .wb_io_cyc_i(mem_read_mem | mem_write_mem),
    .wb_io_stb_i(mem_read_mem | mem_write_mem),
    .wb_io_cti_i(3'b000), // Q: what is the difference values i have? 
    .wb_io_bte_i(2'b00), // Q: what is the difference values i have? 
    .wb_io_dat_o(wb_io_dat_o),
    .wb_io_ack_o(wb_io_ack_o),
    .wb_io_err_o(wb_io_err_o),
    .wb_io_rty_o(wb_io_rty_o),

    // DATA MEM
    .wb_dmem_adr_o(wb_dmem_adr_o),
    .wb_dmem_dat_o(wb_dmem_dat_o),
    .wb_dmem_sel_o(wb_dmem_sel_o),
    .wb_dmem_we_o (wb_dmem_we_o ),
    .wb_dmem_cyc_o(wb_dmem_cyc_o),
    .wb_dmem_stb_o(wb_dmem_stb_o),
    .wb_dmem_cti_o(wb_dmem_cti_o),
    .wb_dmem_bte_o(wb_dmem_bte_o),
    .wb_dmem_dat_i(wb_io_dat_o), //Q: is the slave input signal exactly the same as the master output signal for all the peripherals? 
    .wb_dmem_ack_i(wb_io_ack_o),
    .wb_dmem_err_i(wb_io_err_o),
    .wb_dmem_rty_i(wb_io_rty_o),

    // IMEM
    .wb_imem_adr_o(wb_imem_adr_o),
    .wb_imem_dat_o(wb_imem_dat_o),
    .wb_imem_sel_o(wb_imem_sel_o),
    .wb_imem_we_o (wb_imem_we_o ),
    .wb_imem_cyc_o(wb_imem_cyc_o),
    .wb_imem_stb_o(wb_imem_stb_o),
    .wb_imem_cti_o(wb_imem_cti_o),
    .wb_imem_bte_o(wb_imem_bte_o),
    .wb_imem_dat_i(wb_io_dat_o),
    .wb_imem_ack_i(wb_io_ack_o),
    .wb_imem_err_i(wb_io_err_o),
    .wb_imem_rty_i(wb_io_rty_o),
    // GPIO
    .wb_gpio_adr_o(wb_gpio_adr_o),
    .wb_gpio_dat_o(wb_gpio_dat_o), //Q: should this be used in GPIO instantiation and linked to o_gpio?
    .wb_gpio_sel_o(wb_gpio_sel_o),
    .wb_gpio_we_o (wb_gpio_we_o ),
    .wb_gpio_cyc_o(wb_gpio_cyc_o),
    .wb_gpio_stb_o(wb_gpio_stb_o),
    .wb_gpio_cti_o(wb_gpio_cti_o),
    .wb_gpio_bte_o(wb_gpio_bte_o),
    .wb_gpio_dat_i(wb_io_dat_o),
    .wb_gpio_ack_i(wb_io_ack_o),
    .wb_gpio_err_i(wb_io_err_o),
    .wb_gpio_rty_i(wb_io_rty_o)
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

logic  [dw-1:0]  wb_dat_o;	// output data bus
logic            wb_ack_o;	// normal termination
logic            wb_err_o;	// termination w/ error
logic            wb_inta_o;	// Interrupt request output
logic  [31:0]    o_gpio;
logic  [31:0]    en_gpio;

//Q: what does i_gpio represent vs wb_dat_i?

gpio_top gpio(
.wb_clk_i(clk),	// Clock
.wb_rst_i(~reset_n),	// Reset
.wb_cyc_i(wb_gpio_cyc_o),	// cycle valid input
.wb_adr_i(wb_gpio_adr_o),	// address bus inputs
.wb_dat_i(wb_gpio_dat_o),	// input data bus //Q: what should be linked here io_data or wb_gpio_dat_o or something else?
.wb_sel_i(wb_gpio_sel_o),	// byte select inputs
.wb_we_i (wb_gpio_we_o ),	// indicates write transfer //Q: should this be active high or low? 
.wb_stb_i(wb_gpio_stb_o),	// strobe input
.wb_dat_o(wb_dat_o),	// output data bus
.wb_ack_o(wb_ack_o),	// normal termination
.wb_err_o(wb_err_o),	// termination w/ error
.wb_inta_o(wb_inta_o),	// Interrupt request output
.i_gpio   (io_data   ), //Q: what should be linked here io_data or wb_gpio_dat_o or something else
.o_gpio   (o_gpio),
.en_gpio  (en_gpio),


);
   


    // ============================================
    //             Data Memory Instance
    // ============================================

    // Instantiate data memory here 


    // ============================================
    //          Instruction Memory Instance
    // ============================================

    logic [31:0] imem_inst;

    logic [31:0] imem_addr;
    

    assign imem_addr = sel_boot_rom ? wb_m2s_dmem_adr: current_pc;

    data_mem #(
        .DEPTH(IMEM_DEPTH)
    ) inst_mem_inst (
        .clk_i       (clk            ),
        .rst_i       (wb_rst         ),
        .cyc_i       (wb_m2s_imem_cyc), 
        .stb_i       (wb_m2s_imem_stb),
        .adr_i       (imem_addr      ),
        .we_i        (wb_m2s_imem_we ),
        .sel_i       (wb_m2s_imem_sel),
        .dat_i       (wb_m2s_imem_dat),
        .dat_o       (wb_s2m_imem_dat),
        .ack_o       (wb_s2m_imem_ack)
    );

    assign imem_inst = wb_s2m_imem_dat;


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



    // Inst selection mux
    assign sel_boot_rom = &current_pc[31:12]; // 0xfffff000 - to - 0xffffffff 
    always @(posedge clk) sel_boot_rom_ff <= sel_boot_rom;
    mux2x1 #(
        .n(32)
    ) rom_imem_inst_sel_mux (
        .in0    (imem_inst      ),
        .in1    (rom_inst_ff    ),
        .sel    (sel_boot_rom_ff),
        .out    (inst           )
    );


    
endmodule : rv32i_soc