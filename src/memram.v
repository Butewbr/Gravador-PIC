// Quartus II Verilog Template
// Single port RAM with single read/write address and initial contents 
// specified with an initial block

module single_port_ram_with_init
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=6)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH-1):0] addr,
	input we, clk,
	output [(DATA_WIDTH-1):0] q
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	// Variable to hold the registered read address
	reg [ADDR_WIDTH-1:0] addr_reg;

	integer counter, i, flag;

(*ramstyle = "M9K"*) reg [9:0] data_memory [999:0];
	
	// Specify the initial contents.  You can also use the $readmemb
	// system task to initialize the RAM variable from a text file.
	// See the $readmemb template page for details.
	initial 
	begin : INIT
		integer i;
		$readmemh("D:\\coding\\hdl\\PIC\\docs\\arquivo.hex", data_memory);
		for(i = 0; i < 2**ADDR_WIDTH; i = i + 1)
				ram[i] = data_memory[0];
			
	end 

	always @ (posedge clk)
	begin
		// Write
		if (we)
			ram[addr] <= data;

		addr_reg <= addr;
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	assign q = ram[addr_reg];

endmodule
