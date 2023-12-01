library verilog;
use verilog.vl_types.all;
entity top is
    port(
        CLK_UART_i      : in     vl_logic;
        serial_rx_i     : in     vl_logic;
        start_tx_i      : in     vl_logic;
        serial_write_i  : in     vl_logic_vector(7 downto 0);
        busy_rx_o       : out    vl_logic;
        busy_tx_o       : out    vl_logic;
        valid_rx_o      : out    vl_logic;
        serial_tx_o     : out    vl_logic;
        serial_read_o   : out    vl_logic_vector(7 downto 0)
    );
end top;
