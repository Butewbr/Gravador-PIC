`timescale 1ns/100ps

// 50Mhz -> 20ns
module top_tb;
  
reg CLK_UART_tb;                 
reg serial_rx_tb, start_tx_tb;
reg [7:0] serial_write_tb;
reg addr_tb, we_tb, i_tb;
reg [55:0] data_tb;
wire [55:0] q_tb;

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

(*ramstyle = "M9K"*) reg [55:0] data_memory [4:0];

initial begin
	$readmemh("C:\\Users\\heiit\\Documents\\GitHub\\Gravador-PIC\\docs\\arquivo.hex", data_memory);
	$display("Line %d of data_memory: %h", 0, data_memory[0]);
	//data = data_memory[i];
end

initial begin
  CLK_UART_tb = 0;
  data_tb = data_memory[0];
  i_tb = 0;
  we_tb = 1;
  #6
  i_tb = 1;
  data_tb = data_memory[1];
  we_tb = 1;
  #12;
  we_tb = 0;
  i_tb = 0;
  #10;
end

always begin
  #5 CLK_UART_tb = ~CLK_UART_tb;
end
  
endmodule
