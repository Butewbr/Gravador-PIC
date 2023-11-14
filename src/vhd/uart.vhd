library ieee;
use ieee.std_logic_1164.all;

entity uart is
generic
(
   CLOCK_FREQUENCY   : integer := 50000000;
   BAUDRATE_RX       : integer := 115200;
   BAUDRATE_TX       : integer := 115200;
	CLOCK_DIVIDER		: integer := 50
);
port
(
   CLK_UART_i                 : in std_logic;
   serial_rx_i, start_tx_i    : in std_logic;
   serial_write_i             : in std_logic_vector (7 downto 0);
   busy_rx_o, busy_tx_o       : out std_logic;
   valid_rx_o                 : out std_logic;
   serial_tx_o                : out std_logic;
   serial_read_o              : out std_logic_vector (7 downto 0)
);
end uart;

architecture behavior of uart is

	constant BAUD_RX     		: integer := CLOCK_FREQUENCY/(BAUDRATE_RX);
	constant BAUD_TX     		: integer := CLOCK_FREQUENCY/(2*BAUDRATE_TX);
	signal serial_rx_int 		: std_logic := '0';
	signal serial_rx_ff  		: std_logic := '0';
	signal new_byte      		: std_logic := '0';
	signal tx_busy       		: std_logic := '0';
	signal rx_busy       		: std_logic := '0';
	signal rx_valid_start		: std_logic := '0';
	signal rx_valid_stop 		: std_logic := '0';
	signal rx_valid		 		: std_logic := '0';
	signal pin_tx					: std_logic := '1';
	signal data_read				: std_logic_vector(7 downto 0):= x"00";
	signal buffer_rx     		: std_logic_vector(7 downto 0):= x"00";
	signal buffer_tx     		: std_logic_vector(7 downto 0):= x"00";
	signal count_bit_rx  		: integer range 0 to 10 := 0; 
   signal count_bit_tx  		: integer range 0 to 10 := 0; 
   signal count_baud_rx 		: integer range 0 to BAUD_RX := 0; 
   signal count_baud_tx 		: integer range 0 to BAUD_RX := 0; 
   signal clock_baud_rx			: std_logic := '0';
   signal clock_baud_tx			: std_logic := '0';
	signal rising_new_byte		: std_logic := '0';
   signal falling_serial_rx 	: std_logic := '0';
	signal falling_clock_tx 	: std_logic := '0';
   signal enable_1mhz         : std_logic := '0';
   signal div_clock		      : integer range 1 to (CLOCK_DIVIDER) := 1;
   begin
   
   -- Divisão do clock para 1MHz - sinal de enable
	Clock_div_1MHz:
	process (CLK_UART_i)
	begin
	if rising_edge(CLK_UART_i) then
		if div_clock = (CLOCK_DIVIDER/2) then
			div_clock <= 1;
			enable_1mhz <= '1';
		else
			div_clock <= div_clock + 1;
         enable_1mhz <= '0';
		end if;
	end if;
	end process;
   
   FF_rx:
   process(CLK_UART_i)
   begin
   if rising_edge(CLK_UART_i) then
      serial_rx_int <= serial_rx_i;
      serial_rx_ff <= serial_rx_int;
   end if;
   end process;
   
   Detect_start_bit:
   process (CLK_UART_i) 
   begin
   if rising_edge(CLK_UART_i) then
      if (enable_1mhz='1') then
         if rx_busy = '0' and serial_rx_i = '1' then
            falling_serial_rx <= '1';
         end if;
         if falling_serial_rx = '1' and serial_rx_i = '0' and (rx_busy = '0') then
            new_byte <= '1';
            falling_serial_rx <= '0';
         else
            new_byte <= '0';
         end if;
      end if;
   end if;
   end process;
   
   Sync:    -- sincronização com o clock interno
   process (CLK_UART_i) 
   begin
   if rising_edge(CLK_UART_i) then
		if (count_bit_rx=0 and serial_rx_ff='1') then
			rising_new_byte <= '1';
      else
         rising_new_byte <= '0';
		end if;
      if new_byte = '1' then
         rx_busy <= '1';
         --clock_baud_rx <= '0';
      elsif rx_busy = '1' then
            if count_bit_rx = 10 then
               rx_busy <= '0';
            end if;
      end if;
		if (count_baud_rx = BAUD_RX or rising_new_byte='1') then
        count_baud_rx <= 1;
        --clock_baud_rx <= '1';
      else        
        count_baud_rx <= count_baud_rx + 1;
        --clock_baud_rx <= '0';
		end if;
      if count_baud_rx = BAUD_RX/2 then
         clock_baud_rx <= '1';
      else
         clock_baud_rx <= '0';        
		end if;
   end if;
   end process;

Reading_data:
   process(CLK_UART_i)    
   begin
   if rising_edge(CLK_UART_i) then
      if (clock_baud_rx='1') then
         if rx_busy = '0' then
            buffer_rx <= (others => '0');
            count_bit_rx <= 0;
            rx_valid_start <= '0';
            rx_valid_stop <= '0';
         else
            -- start bit
            if count_bit_rx = 0 then
               --rx_valid_start <= not serial_rx_ff;
               if (serial_rx_ff='0') then
                  rx_valid_start <= '1';
               else 
                  rx_valid_start <= '0';
               end if;
            -- stop bit
            elsif count_bit_rx = 9 then
               rx_valid_stop  <= serial_rx_ff;
               if (serial_rx_ff = '1' and rx_valid_start = '1') then
                  data_read <= buffer_rx;
               end if;
            -- Data reception         
            else
               buffer_rx (6 downto 0) <= buffer_rx (7 downto 1);
               buffer_rx (7) <= serial_rx_ff;
            end if;
            count_bit_rx <= count_bit_rx + 1;
         end if;
      end if;
   end if;
   end process;
   
	Transmitting_data:
	process(CLK_UART_i)
	begin
	if rising_edge(CLK_UART_i) then
		if tx_busy = '0' then
			pin_tx <= '1';
		end if;
		if start_tx_i = '1' and tx_busy = '0' then
			pin_tx <= '0';
			tx_busy <= '1';
			buffer_tx <= serial_write_i;
		end if;
		if tx_busy = '1' then
			if count_baud_tx >= BAUD_TX then
				count_baud_tx <= 0;
				clock_baud_tx <= not clock_baud_tx;
			else
				count_baud_tx <= count_baud_tx + 1;
			end if;
			if clock_baud_tx = '1' then
				falling_clock_tx <= '1';
			end if;
			if clock_baud_tx = '0' and falling_clock_tx = '1' then
				falling_clock_tx <= '0';
				if count_bit_tx = 8 then
					pin_tx <= '1';
				elsif count_bit_tx = 9 then
					tx_busy <= '0';
					count_bit_tx <= 0;
				else
					pin_tx <= buffer_tx(0);
					buffer_tx (6 downto 0) <= buffer_tx (7 downto 1);
					buffer_tx (7) <= '0';
				end if;
				count_bit_tx <= count_bit_tx +1;
			end if;
		else
			count_bit_tx <= 0;
		end if;		
	end if;
	end process;
	serial_read_o <= data_read when rx_valid = '1' else
					 (others => '0');
	busy_rx_o <= rx_busy;
	busy_tx_o <= tx_busy;
	rx_valid	 <= rx_valid_start and rx_valid_stop;
	valid_rx_o <= rx_valid;
	serial_tx_o <= pin_tx;
end behavior;  
