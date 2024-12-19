library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;


entity adc_transfer is
    port (
        clk_50MHz      : in  std_logic;
        D0             : in  std_logic;
        D1             : in  std_logic;
        D2             : in  std_logic;
        D3             : in  std_logic;
        D4             : in  std_logic;
        D5             : in  std_logic;
        D6             : in  std_logic;
        D7             : in  std_logic;
--        o_data         : out std_logic_vector(7 downto 0);
        Sclk           : out std_logic;
		  TxD 			  : out std_logic
    );
end adc_transfer;

architecture rtl of adc_transfer is
    component UART_TX is
        generic (
            CLKS_PER_BIT : integer := 217
        );
        port (
            i_Rst_L     : in  std_logic;
            i_Clock     : in  std_logic;
            i_TX_DV     : in  std_logic;
            i_TX_Byte   : in  std_logic_vector(7 downto 0);
            o_TX_Active : out std_logic;
            o_TX_Serial : out std_logic;
            o_TX_Done   : out std_logic
        );
    end component UART_TX;
	 
	 constant c_CLK_PERIOD : time := 40 ns;
	 signal r_TX_DV     : std_logic                    := '0';
	 signal r_Clock     : std_logic                    := '0';
    signal i_data        : std_logic_vector(7 downto 0);
    signal CLK_25MHz    : std_logic := '0';
    type adc_values_array is array (0 to 99) of std_logic_vector(7 downto 0);
    signal adc_values   : adc_values_array;
    signal adc_index    : integer range 0 to 99 := 0;
    signal transmit_index : integer range 0 to 99 := 0;
    signal reading_done : std_logic := '0';
    signal uart_tx_active : std_logic;
    signal uart_tx_byte : std_logic_vector(7 downto 0);
    signal uart_tx_done : std_logic:='1';
--    signal counter      : integer range 0 to 499999 := 0; -- Counter to divide clock frequency

begin
    i_data <= D7 & D6 & D5 & D4 & D3 & D2 & D1 & D0;
    Sclk <= CLK_25MHz;

    Sclock: process(clk_50MHz)
    begin
        if rising_edge(clk_50MHz) then
--            counter <= counter + 1;
--            if counter = 499999 then
--                counter <= 0;
                CLK_25MHz <= not CLK_25MHz;
--            end if;
        end if;
    end process Sclock;

    p_output : process(CLK_25MHz)
    begin
        if rising_edge(CLK_25MHz) then
--            o_data <= conv_std_logic_vector(adc_index,8);
            if adc_index = 99 then
                reading_done <= '1';
            else
                adc_values(adc_index) <= i_data;
                adc_index <= adc_index + 1;
            end if;
        end if;
    end process p_output;
	 
UART1: UART_TX 
    port map (
        i_Rst_L     => '0', -- Assuming no reset provided, set to low
        i_Clock     => CLK_25MHz, 
        i_TX_DV     => r_TX_DV,
        i_TX_Byte   => uart_tx_byte,
        o_TX_Active => uart_tx_active,
        o_TX_Serial => TxD, -- You need to connect this signal to an output pin if you want to observe it
        o_TX_Done   => uart_tx_done -- You can utilize this signal for flow control if needed
    );
	 
    r_Clock <= not r_Clock after c_CLK_PERIOD/2;
	 
	 data_valid : process(CLK_25MHz)
	 begin
	     if CLK_25MHz='1' then
		    r_TX_DV <= not r_TX_DV;
			 end if;
	 end process data_valid;
	 
    p_transmit_uart : process(CLK_25MHz)
    begin
        if rising_edge(CLK_25MHz) then
            if reading_done = '1' then
                if uart_tx_done = '1' then
                    if transmit_index < 100 then
                        uart_tx_byte <= adc_values((transmit_index));
                        uart_tx_active <= '1';
                        transmit_index <= transmit_index + 1;
                    end if;
                end if;
            end if;
        end if;
    end process p_transmit_uart;

end rtl;
