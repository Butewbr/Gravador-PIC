module top (
   CLK_UART_i,
   serial_rx_i, 
   start_tx_i,
   serial_write_i,
   busy_rx_o, 
   busy_tx_o,
   valid_rx_o,                 
   serial_tx_o,                
   serial_read_o,
   addr_i,
	we_i,
	q_o,
	i,
	data
);

input CLK_UART_i;                 
input serial_rx_i, start_tx_i;
input [7:0] serial_write_i;
input addr_i,we_i,i; 

output busy_rx_o, busy_tx_o;       
output valid_rx_o;                 
output serial_tx_o;                
output [7:0] serial_read_o;
output [55:0] q_o;
input [55:0] data;

reg [7:0] buffer;

//integer counter, i, flag;

(*ramstyle = "M9K"*) reg [55:0] data_memory [4:0];

initial begin
	$readmemh("C:\\Users\\heiit\\Documents\\GitHub\\Gravador-PIC\\docs\\arquivo.hex", data_memory);
   $display("Line %d of data_memory: %h", i, data_memory[i]);
	//data = data_memory[i];
end
/*
always @(start_tx_i) begin
   for (counter=0; counter<=999; counter=counter+1)
      buffer = data_memory[counter];
      if(buffer == 10'h00000001FF) begin
         counter = 999;
         flag = 0;
      end
end
*/

/*
uart U00
(
   .CLK_UART_i(CLK_UART_i),
   .serial_rx_i(serial_rx_i), 
   .start_tx_i(~start_tx_i),
   .serial_write_i(buffer),
   .busy_rx_o(busy_rx_o), 
   .busy_tx_o(busy_tx_o),
   .valid_rx_o(valid_rx_o),                 
   .serial_tx_o(serial_tx_o),                
   .serial_read_o(serial_read_o)
);
*/
single_port_ram U01

(
	.data(data),
	.addr({4'b0000, i}),
	.we(we_i), 
	.clk(CLK_UART_i),
	.q(q_o)
);


    
endmodule
