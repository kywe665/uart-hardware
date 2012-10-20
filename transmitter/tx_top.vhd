----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:34:49 10/18/2012 
-- Design Name: 
-- Module Name:    tx_top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tx_top is
    Port ( clk : in  STD_LOGIC;
           btn : in  STD_LOGIC_VECTOR (1 downto 0);
           sw : in  STD_LOGIC_VECTOR (7 downto 0);
           tx_busy : out  STD_LOGIC;
           tx_out : out  STD_LOGIC;
           dp : out  STD_LOGIC;
           an : out  STD_LOGIC_VECTOR (3 downto 0);
           seg : out  STD_LOGIC_VECTOR (6 downto 0));
end tx_top;

architecture Behavioral of tx_top is
	signal reset_btn, send_btn: std_logic;
	signal sample_count: unsigned(15 downto 0);
	signal data: std_logic_vector(15 downto 0);
begin

	U1: entity work.seven_segment_display
		port map
		(
			clk => clk,
			data_in => data,
			dp_in => "0000",
			blank =>"1100",
			dp => dp,
			an=> an,
			seg=> seg
		);
	data <= "00000000"&sw;
		
	U2: entity work.tx
		port map (
			clk => clk,
			rst => reset_btn,
			data_in => sw,
			send_character => send_btn,
			tx_out => tx_out,
			tx_busy => tx_busy
		);
		
	--DEBOUNCER
	process(clk, btn)
	begin
		if(clk'event and clk = '1') then
			reset_btn <= '0';
			send_btn <= '0';
			if(sample_count = 10000) then
				sample_count <= (others=>'0');
				reset_btn <= btn(1);
				send_btn <= btn(0);
			else
				sample_count <= sample_count + 1;
			end if;
		end if;
	end process;

end Behavioral;

