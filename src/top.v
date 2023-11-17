module top (
   CLK_UART_i,
   serial_rx_i, 
   start_tx_i,
   serial_write_i,
   busy_rx_o, 
   busy_tx_o,
   valid_rx_o,                 
   serial_tx_o,                
   serial_read_o              
);

input CLK_UART_i;                 
input serial_rx_i, start_tx_i;
input [7:0] serial_write_i;             

output busy_rx_o, busy_tx_o;       
output valid_rx_o;                 
output serial_tx_o;                
output [7:0] serial_read_o;

reg [7:0] buffer;

//integer counter, i, flag;

//(*ramstyle = "M9K"*) reg [9:0] data_memory [999:0];
/*
initial begin
	$readmemh("D:\\coding\\hdl\\PIC\\docs\\arquivo.hex", data_memory);
   for (i=0; i<=5; i=i+1)
      $display("Line %d of data_memory: %h", i, data_memory[i]);
   
   flag = 1;
end

always @(start_tx_i) begin
   for (counter=0; counter<=999; counter=counter+1)
      buffer = data_memory[counter];
      if(buffer == 10'h00000001FF) begin
         counter = 999;
         flag = 0;
      end

end
*/


uart U00
(
   .CLK_UART_i(CLK_UART_i),
   .serial_rx_i(serial_rx_i), 
   .start_tx_i(~start_tx_i && flag),
   .serial_write_i(buffer),
   .busy_rx_o(busy_rx_o), 
   .busy_tx_o(busy_tx_o),
   .valid_rx_o(valid_rx_o),                 
   .serial_tx_o(serial_tx_o),                
   .serial_read_o(serial_read_o)
);

single_port_ram_with_init U01

(
	.data(),
	.addr(),
	.we(), 
	.clk(CLK_UART_i),
	.q()
);


    
endmodule
