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
 input  CLK_UART_i;                 
 input  serial_rx_i, start_tx_i;    
input [7:0]   serial_write_i;             
 output  busy_rx_o, busy_tx_o;       
output   valid_rx_o;                 
output   serial_tx_o;                
output [7:0]   serial_read_o;


(*ramstyle = "M9K"*) reg [15:0] data_memory [255:0];
()



initial begin
    $readmemh("path\\arquivo.txt",data_memory);
end


uart U00
(
   .CLK_UART_i(CLK_UART_i),
   .serial_rx_i(serial_rx_i), 
   .start_tx_i(start_tx_i),
   .serial_write_i(serial_write_i),
   .busy_rx_o(busy_rx_o), 
   .busy_tx_o(busy_tx_o),
   .valid_rx_o(valid_rx_o),                 
   .serial_tx_o(serial_tx_o),                
   .serial_read_o(serial_read_o)
);


    
endmodule
