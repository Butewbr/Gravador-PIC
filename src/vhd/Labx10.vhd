-- Testado com simpleterm

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Labx10 is
generic(
	CLOCK_PERIOD : integer := 20;
	CLOCK_FREQUENCY: integer := 50000000;
	CLOCK_DIVIDER		: integer := 50;
	BAUDRATE_RX : integer := 115200;
	BAUDRATE_TX : integer := 115200;
	TAM_DATA	: integer := 8; 	-- Numero de bits do caractere enviado para o LCD
	NUM_DATA	: integer := 32; 	-- Numero de characteres que serão escritos
	DIV_NUM		: integer := 500;	-- 50Mhz/500 = 100KHz = 10us
	BOOT_TIME	: integer := 2000;  -- 2000/100KHz = 20ms
   REFRESH     : integer := 10000000; -- taxa de atualizaçao do LCD, 10000000*20ns = 0,2s => é atualizado a cada 0,2s
	WR_TIME		: integer := 5;	-- 5*10us = 50us
	CLR_TIME   	: integer := 200;	-- 2ms
	DEBOUNCE    : integer := 5000000   -- filtro ruido de trepidaçao, 5000000*20ns = 0,1s
);
port(
	CLOCK_50MHz		: in std_logic;
	KEY				: in std_logic_vector (11 downto 0);
	SW					: in std_logic_vector (3 downto 0);
	
	--LCD
	LCD_D		   	: inout	std_logic_vector(7  downto 0); 	-- LCD data is a bidirectional bus...
	LCD_RS 			: out   std_logic;                		-- LCD register select
	LCD_RW  			: out   std_logic;                		-- LCD Read / nWrite
	LCD_EN  			: out   std_logic;                		-- LCD Enable
	LCD_BACKLIGHT	: out   std_logic;
	
	-- UART
	UART_RXD			: in std_logic;
	UART_TXD			: out std_logic
	);
end Labx10;

architecture behavior of Labx10 is

signal caractere 		: STD_LOGIC_VECTOR(7 downto 0);
signal preescaler		: integer range 0 to DEBOUNCE;
signal count 			: integer range 1 to NUM_DATA := 1;
signal w_reset_50mhz				: std_logic;
signal dado_rd 		: std_logic_vector(7 downto 0);
signal rd_busy 		: std_logic;
signal wr_busy			: std_logic; 
signal valid_rx		: std_logic;
signal flag_rd 		: std_logic := '0';
signal wr_enable		: std_logic := '0';

--sianis LCD
signal start_lcd	: std_logic;
signal data_dec 	: std_logic_vector(TAM_DATA downto 1);
signal idx 			: integer range 1 to NUM_DATA;

-- Sinal Teclado
signal key_data: std_logic_vector(3 downto 0);
signal ready_key: std_logic;

-- Declaraçao do teclado
component teclado_base is
generic(
	DEBOUNCE : integer
);
port(
		clk_i				:	in std_logic;
		push_button_i	:	in std_logic_vector (11 downto 0);
		key_o				: 	out std_logic_vector (3 downto 0);
		ready_o			:	out std_logic
	);
end component;

-- Declaraçao Componente UART
COMPONENT uart
	GENERIC (   CLOCK_FREQUENCY : INTEGER;
               BAUDRATE_RX     : INTEGER;
               BAUDRATE_TX     : INTEGER;
               CLOCK_DIVIDER   : INTEGER);
	PORT
	(
		CLK_UART_i		:	 IN STD_LOGIC;
		serial_rx_i		:	 IN STD_LOGIC;
		start_tx_i		:	 IN STD_LOGIC;
		serial_write_i	:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		busy_rx_o		:	 OUT STD_LOGIC;
		busy_tx_o		:	 OUT STD_LOGIC;
		valid_rx_o		:	 OUT STD_LOGIC;
		serial_tx_o		:	 OUT STD_LOGIC;
		serial_read_o	:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

-- Declaraçao do LCD
COMPONENT lcd_top
	GENERIC ( TAM_DATA : INTEGER; NUM_DATA : INTEGER; DIV_NUM : INTEGER; BOOT_TIME : INTEGER;
		 WR_TIME : INTEGER; CLR_TIME : INTEGER );
	PORT
	(
		CLK_50MHz_i	:	 IN STD_LOGIC;
		rst_i		   :	 IN STD_LOGIC;
		start_i		:	 IN STD_LOGIC;
		data_i		:	 IN STD_LOGIC_VECTOR(tam_data DOWNTO 1);
		idx_o		   :	 OUT INTEGER range 1 to NUM_DATA;
		ready_o		:	 OUT STD_LOGIC;
		LCD_DATA		:	 INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		LCD_RS		:	 OUT STD_LOGIC;
		LCD_RW		:	 OUT STD_LOGIC;
		LCD_EN		:	 OUT STD_LOGIC;
		LCD_BLON		:	 OUT STD_LOGIC
	);
END COMPONENT;

-- declaraçao da memoria que armazenara os caracteres a serem escritos no LCD
	type MEM is array (1 to NUM_DATA) of std_logic_vector(TAM_DATA downto 1);
	signal word: MEM := MEM'(
      x"20", -- Nulo
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20",
      x"20"
	);

-- Declaração sincronizador de reset
COMPONENT reset_sync
   PORT
	(
		i_clk	               :	 IN STD_LOGIC;
		i_external_reset_n	:	 IN STD_LOGIC;
		o_reset_n      		:	 OUT STD_LOGIC;
		o_reset		         :	 OUT STD_LOGIC
   );
END COMPONENT;   
   
begin

-- rst <= KEY(11);

   --reset <= KEY(11);
	reset_synch_50mhz_inst : reset_sync
	PORT MAP (
		i_clk                => CLOCK_50MHz,
		i_external_reset_n   => KEY(11),
		o_reset		         => open,
		o_reset_n            => w_reset_50mhz
	);

-- Processo para a recepçao dos dados
process(CLOCK_50MHz, w_reset_50mhz)
begin

if w_reset_50mhz = '1' then
	count <= 1;
	flag_rd <= '0';
elsif rising_edge(CLOCK_50MHz) then
	if rd_busy = '0' and valid_rx = '1' and flag_rd = '1' then
		flag_rd <= '0';	-- evita que o mesmo dado seja lido mais de uma vez
		word(count) <= dado_rd;
		count <= count + 2;
		if count >= NUM_DATA -1 then
			count <= 1;
		end if;
	elsif rd_busy = '1' then
		flag_rd <= '1';
	end if;
end if;
end process;

teclado:
	teclado_base 
	generic map
	(
	DEBOUNCE => DEBOUNCE
	)
	port map
	(
		clk_i				=> CLOCK_50MHz,
		push_button_i 	=> '0'& KEY(10 downto 0),
		key_o				=> key_data,
		ready_o			=> ready_key
	);

-- Processo para o envio de dados
	Data_send:
	process (CLOCK_50MHz, w_reset_50mhz)
	variable count : integer range 0 to CLOCK_FREQUENCY - 1:= 0;
	begin
		if w_reset_50mhz = '1' then
			wr_enable <= '0';
		elsif rising_edge(CLOCK_50MHz) then
			wr_enable <= '0';
			if  key_data /= "1111" and ready_key = '1' then
				if wr_busy = '0' then
					caractere <= key_data + x"30";
					wr_enable <= '1';
				end if;
			end if;
		end if;
	end process;

-- Instanciaçao da UART

	uart_inst: uart
	GENERIC MAP (  CLOCK_FREQUENCY   => CLOCK_FREQUENCY,
                  BAUDRATE_RX       => BAUDRATE_RX,
                  BAUDRATE_TX       => BAUDRATE_TX,
                  CLOCK_DIVIDER     => CLOCK_DIVIDER)
	PORT MAP
	(
		CLK_UART_i		=> CLOCK_50MHz,
		serial_rx_i		=> UART_RXD,
		start_tx_i		=> wr_enable,
		serial_write_i	=> CARACTERE,
		busy_rx_o		=> rd_busy,
		busy_tx_o		=> wr_busy,
		valid_rx_o		=> valid_rx,
		serial_tx_o		=> UART_TXD,
		serial_read_o	=> dado_rd
	);



		-- Instanciação e configuraçao do LCD
   
   inst_lcd_top : lcd_top
   generic map(
		TAM_DATA 	=> TAM_DATA,
		NUM_DATA	=> NUM_DATA,
		--LCD
		DIV_NUM		=> DIV_NUM,
		BOOT_TIME	=> BOOT_TIME,
		WR_TIME		=> WR_TIME,
		CLR_TIME	=> CLR_TIME
      )
	port map (
		CLK_50MHz_i=> CLOCK_50Mhz,
		rst_i		=> w_reset_50mhz,
		start_i	=> start_lcd,
		data_i	=> data_dec,
		idx_o		=> idx,
		ready_o	=> open,
		-- LCD
		LCD_DATA	=> LCD_D,
		LCD_RS 	=> LCD_RS,
		LCD_RW  	=> LCD_RW,
		LCD_EN  	=> LCD_EN,
		LCD_BLON => open
	);
   
   LCD_BACKLIGHT <= SW(3);
	
   data_dec <= word(idx);
   
	-- Processo para a atualizaçao dos dados escritos no LCD
   process (CLOCK_50MHz, w_reset_50mhz)
   variable count_2: integer range 1 to REFRESH := 1;
   
   begin
   if (rising_edge(CLOCK_50MHz) and w_reset_50mhz /= '1') then
      start_lcd <= '0';
      count_2 := count_2 + 1;
      if count_2 = (REFRESH - 4) then -- -4, tempo para o sinal ser interpretado sem problemas
         start_lcd <= '1';
      elsif count_2 = (REFRESH) then 
         count_2 := 1;
      end if;
   end if;
   end process;
   
end behavior;