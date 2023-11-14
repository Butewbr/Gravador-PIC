module picwriter(
	registrador,
	clk_i,
	assyn_rst_i,
	sync_rst_i,
	a,
	b,
	sum,
	load_i
);

reg wire [3:0] registrador; // Registrador que armazena o valor
input wire [3:0] a,b;
input wire clk_i,assyn_rst_i,sync_rst_i,load_i;
output wire sum;
always @(posedge clk_i or posedge assyn_rst_i) 
begin
	if (assyn_rst_i) begin // Reset assíncrono 
		registrador<= 4'b0000; 
		end
	else
		if (sync_rst_i) begin // Reset síncrono
			registrador <= 4'b0000; 
			end 
		else
			registrador <= registrador; // mantêm valor anterior
			if (load_i) begin // Carrega o valor 
				registrador <= a^b; 
			end // Nenhum outro caso é necessário; 
end

assign sum = registrador; // Saída é o valor do registrador

endmodule
