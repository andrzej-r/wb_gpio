/*
 * Simple GPIO module with configurable bus width
 *
 * First 32 bit word is the GPIO I/O reg
 * Second 32 bit word is the direction register
 * If the bus width is less than 32 bits MSB registers are undefined.
 *
 * Set direction bit to '1' to output corresponding data bit.
 *
 * Register mapping:
 *
 * adr 0-3:
 *        gpio data
 * adr 4-7:
 *        gpio dir
 */

module wb_gpio
  #(
    parameter        n_bits = 32 // bus width, range 1:32
    )
  (
   input                   wb_clk,
   input                   wb_rst,

   input [2:2]             wb_adr_i,
   input [n_bits-1:0]      wb_dat_i,
   input                   wb_we_i,
   input                   wb_cyc_i,
   input                   wb_stb_i,
   input [2:0]             wb_cti_i,
   input [1:0]             wb_bte_i,
   output reg [n_bits-1:0] wb_dat_o,
   output reg              wb_ack_o,
   output                  wb_err_o,
   output                  wb_rty_o,

   input [n_bits-1:0]      gpio_i,
   output reg [n_bits-1:0] gpio_o,
   output reg [n_bits-1:0] gpio_dir_o
   );

   // GPIO dir register
   always @(posedge wb_clk)
     if (wb_rst)
       gpio_dir_o <= 0; // All set to in at reset
     else if (wb_cyc_i & wb_stb_i & wb_we_i) begin
	if (wb_adr_i[2] == 1)
	  gpio_dir_o <= wb_dat_i[n_bits-1:0];
     end


   // GPIO data out register
   always @(posedge wb_clk)
     if (wb_rst)
       gpio_o <= 0;
     else if (wb_cyc_i & wb_stb_i & wb_we_i) begin
	if (wb_adr_i[2] == 0)
	  gpio_o <= wb_dat_i[n_bits-1:0];
     end


   // Register the gpio in signal
   reg [n_bits-1:0] gpio_i_ff;
   always @(posedge wb_clk) begin
      // Synchronize gpio_i
      // single ff because the second ff only adds enable logic and clk freq is low
      gpio_i_ff <= gpio_i;

      // Data regs
      if (wb_adr_i[2] == 0)
	wb_dat_o <= gpio_i_ff;

      // Direction regs
      if (wb_adr_i[2] == 1)
	wb_dat_o <= gpio_dir_o;
   end

   // Ack generation
   always @(posedge wb_clk)
     if (wb_rst)
       wb_ack_o <= 0;
     else if (wb_ack_o)
       wb_ack_o <= 0;
     else if (wb_cyc_i & wb_stb_i & !wb_ack_o)
       wb_ack_o <= 1;

   assign wb_err_o = 0;
   assign wb_rty_o = 0;

endmodule
