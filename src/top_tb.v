`timescale 1ns/100ps

// 50Mhz -> 20ns
module top_tb;
  
reg CLK_UART_tb;                 
reg serial_rx_tb, start_tx_tb;
reg [7:0] serial_write_tb;
reg addr_tb, we_tb, i_tb;

top U00 (
   .CLK_UART_i (CLK_UART_tb),
   .serial_rx_i (serial_rx_tb), 
   .start_tx_i (start_tx_tb),
   .serial_write_i (serial_write_tb),
   .busy_rx_o (busy_rx_o_tb), 
   .busy_tx_o (busy_tx_o_tb),
   .valid_rx_o (valid_rx_o_tb),           
   .serial_tx_o (serial_tx_o_tb),             
   .serial_read_o (serial_read_o_tb),
   .addr_i (addr_tb),
   .we_i (we_tb),
   .q_o (q_tb),
   .data (data_tb),
   .i (i_tb)
);

initial begin
  i_tb = 0;
  addr_tb = 1;
  #1;
  i_tb = 1;
  addr_tb = 2;
  #2;
  i_tb = 2;
  addr_tb = 3;
end

  
endmodule
